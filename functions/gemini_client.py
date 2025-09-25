"""Client for interacting with Google Gemini API using the native SDK."""
import json
import base64
import os
from typing import Dict, Any, List, Optional
from firebase_functions import https_fn
import google.generativeai as genai
from google.generativeai.types import HarmCategory, HarmBlockThreshold

from prompts import ImagePrompts, SuggestionPrompts, FallbackSuggestions


class Config:
    """Configuration class for Firebase Functions."""
    
    # Google AI API Configuration  
    GOOGLE_AI_API_KEY = os.environ.get('GOOGLE_AI_API_KEY')
    
    # Gemini Model Names
    GEMINI_IMAGE_MODEL = 'gemini-2.5-flash-image-preview'
    GEMINI_VISION_MODEL = 'gemini-2.5-flash'
    
    # Generation settings
    IMAGE_GENERATION_CONFIG = {
        'temperature': 0.7,
        'top_k': 40,
        'top_p': 0.95,
        'max_output_tokens': 1024
    }
    
    SUGGESTIONS_GENERATION_CONFIG = {
        'temperature': 0.8,
        'top_k': 40,
        'top_p': 0.95,
        'max_output_tokens': 1024,
        'response_mime_type': 'application/json'
    }
    
    @classmethod
    def validate(cls):
        """Validate that all required configuration is present."""
        if not cls.GOOGLE_AI_API_KEY:
            raise ValueError("GOOGLE_AI_API_KEY environment variable is required")


class GeminiClient:
    """Client for making requests to Google Gemini API using the native SDK."""
    
    def __init__(self):
        """Initialize the Gemini client."""
        Config.validate()
        
        # Configure the SDK
        genai.configure(api_key=Config.GOOGLE_AI_API_KEY)
        
        # Initialize models
        self.image_model = genai.GenerativeModel(Config.GEMINI_IMAGE_MODEL)
        self.vision_model = genai.GenerativeModel(Config.GEMINI_VISION_MODEL)
        
        # Safety settings
        self.safety_settings = {
            HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
        }
    
    def _base64_to_image_part(self, base64_data: str, mime_type: str = 'image/jpeg') -> Dict[str, Any]:
        """Convert base64 data to image part for Gemini."""
        return {
            'mime_type': mime_type,
            'data': base64.b64decode(base64_data)
        }
    
    def generate_image(
        self, 
        original_image_base64: str, 
        prompt: str, 
        reference_image_base64: Optional[str] = None
    ) -> str:
        """Generate an image using Gemini."""
        try:
            # Prepare content parts
            content_parts = [
                ImagePrompts.get_image_generation_prompt(prompt),
                self._base64_to_image_part(original_image_base64)
            ]
            
            # Add reference image if provided
            if reference_image_base64:
                content_parts.append(self._base64_to_image_part(reference_image_base64))
            
            # Generate content
            response = self.image_model.generate_content(
                content_parts,
                generation_config=genai.GenerationConfig(**Config.IMAGE_GENERATION_CONFIG),
                safety_settings=self.safety_settings
            )
            
            # Extract image data from response
            if response.candidates and len(response.candidates) > 0:
                candidate = response.candidates[0]
                if candidate.content and candidate.content.parts:
                    for part in candidate.content.parts:
                        if hasattr(part, 'inline_data') and part.inline_data:
                            return base64.b64encode(part.inline_data.data).decode('utf-8')
            
            raise https_fn.HttpsError('internal', 'No image data found in response')
            
        except Exception as e:
            if isinstance(e, https_fn.HttpsError):
                raise
            raise https_fn.HttpsError('internal', f'Failed to generate image: {str(e)}')
    
    def generate_suggestions(self, image_base64: str) -> List[Dict[str, str]]:
        """Generate prompt suggestions using Gemini Vision."""
        try:
            # Prepare content parts
            content_parts = [
                SuggestionPrompts.get_suggestions_prompt(),
                self._base64_to_image_part(image_base64)
            ]
            
            # Configure generation for JSON output
            generation_config = genai.GenerationConfig(
                **Config.SUGGESTIONS_GENERATION_CONFIG,
                response_schema=SuggestionPrompts.get_response_schema()
            )
            
            # Generate content
            response = self.vision_model.generate_content(
                content_parts,
                generation_config=generation_config,
                safety_settings=self.safety_settings
            )
            
            # Extract and parse JSON response
            if response.candidates and len(response.candidates) > 0:
                candidate = response.candidates[0]
                if candidate.content and candidate.content.parts:
                    for part in candidate.content.parts:
                        if hasattr(part, 'text') and part.text:
                            try:
                                suggestions = json.loads(part.text)
                                return suggestions
                            except json.JSONDecodeError:
                                # Continue to fallback
                                pass
            
            # Return fallback suggestions if parsing fails or no valid response
            return FallbackSuggestions.get_fallback_suggestions()
            
        except Exception as e:
            # Return fallback suggestions on any error
            return FallbackSuggestions.get_fallback_suggestions()
