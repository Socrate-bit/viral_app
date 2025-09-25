"""Prompt templates for AI image generation and suggestions."""
from typing import Dict, List


class ImagePrompts:
    """Prompts for image generation tasks."""
    
    @staticmethod
    def get_image_generation_prompt(user_prompt: str) -> str:
        """Get the system prompt for image generation."""
        return f"Based on this image, create a new version: {user_prompt}. Answer me by a picture, don't ask detail."


class SuggestionPrompts:
    """Prompts for generating aesthetic suggestions."""
    
    @staticmethod
    def get_suggestions_prompt() -> str:
        """Get the system prompt for generating aesthetic suggestions."""
        return """
Analyze this image and generate exactly 20 aesthetic transformation suggestions based on popular visual aesthetics. Transform the image while preserving the subject's face and key features.

For each aesthetic, provide:
- A short catchy title (3-6 words) for display on chips (example: "📚 Dark Academia", "🤖 Cyberpunk Aesthetic")
- A detailed prompt that transforms the image into that aesthetic while keeping the subject's face recognizable

Generate exactly 20 unique aesthetic transformations based on what you observe in the image.
"""

    @staticmethod
    def get_response_schema() -> Dict:
        """Get the JSON schema for suggestions response."""
        return {
            'type': 'array',
            'items': {
                'type': 'object',
                'properties': {
                    'title': {
                        'type': 'string',
                        'description': 'A short catchy title (3-6 words) for display on chips'
                    },
                    'prompt': {
                        'type': 'string',
                        'description': 'A detailed prompt for image generation (can be longer and more descriptive)'
                    }
                },
                'required': ['title', 'prompt']
            }
        }


class FallbackSuggestions:
    """Fallback suggestions when AI generation fails."""
    
    @staticmethod
    def get_fallback_suggestions() -> List[Dict[str, str]]:
        """Get fallback suggestions if Gemini Vision API fails."""
        return [
            {
                "title": "📚 Dark Academia",
                "prompt": "Transform into Dark Academia aesthetic with vintage clothing, moody library background, and intellectual atmosphere while preserving face details"
            },
            {
                "title": "🤖 Cyberpunk Aesthetic",
                "prompt": "Transform into cyberpunk aesthetic with neon lights, futuristic clothing, and dystopian tech-noir background while keeping face recognizable"
            },
            {
                "title": "✨ Y2K Retro",
                "prompt": "Transform into Y2K aesthetic with early 2000s metallic clothing, futuristic-retro accessories, and glossy finish while preserving facial features"
            },
            {
                "title": "🌸 Soft Girl Aesthetic",
                "prompt": "Transform into Soft Girl aesthetic with pastel colors, kawaii elements, gentle feminine styling while maintaining face details"
            },
            {
                "title": "🖤 Gothic Style",
                "prompt": "Transform into Gothic aesthetic with dramatic dark makeup, mysterious clothing, and moody atmosphere while keeping face recognizable"
            },
            {
                "title": "💜 80s Synthwave",
                "prompt": "Transform into 80s aesthetic with neon synthwave colors, retro-futuristic styling, and vibrant background while preserving face"
            },
            {
                "title": "🌻 Cottagecore Vibes",
                "prompt": "Transform into Cottagecore aesthetic with countryside setting, floral elements, and rustic charm while maintaining facial features"
            },
            {
                "title": "🎵 K-Pop Style",
                "prompt": "Transform into K-Pop aesthetic with street luxury fashion, bold trendy styling, and modern urban background while keeping face details"
            },
            {
                "title": "🧚 Fairycore Magic",
                "prompt": "Transform into Fairycore aesthetic with ethereal styling, magical flowers, sparkles, and dreamy atmosphere while preserving face"
            },
            {
                "title": "🎸 Grunge Alternative",
                "prompt": "Transform into Grunge aesthetic with distressed clothing, alternative styling, and edgy urban background while maintaining face"
            },
            {
                "title": "💎 Vaporwave Dream",
                "prompt": "Transform into Vaporwave aesthetic with pastel pink and blue colors, retro computer graphics, and nostalgic atmosphere while keeping face recognizable"
            },
            {
                "title": "☀️ Clean Girl Look",
                "prompt": "Transform into Clean Girl aesthetic with minimal natural makeup, effortless styling, and bright natural lighting while preserving facial features"
            },
            {
                "title": "💗 Barbiecore Pink",
                "prompt": "Transform into Barbiecore aesthetic with hot pink styling, glamorous doll-like perfection, and luxurious background while maintaining face details"
            },
            {
                "title": "📼 90s Nostalgia",
                "prompt": "Transform into 90s aesthetic with grunge casual clothing, alternative rock styling, and vintage filter while keeping face recognizable"
            },
            {
                "title": "🎌 Animecore Style",
                "prompt": "Transform into Animecore aesthetic with manga-inspired styling, vibrant colors, and stylized anime elements while preserving face"
            },
            {
                "title": "⚙️ Steampunk Victorian",
                "prompt": "Transform into Steampunk aesthetic with Victorian-industrial styling, brass gears, vintage tech elements while maintaining facial features"
            },
            {
                "title": "🌅 VSCO Golden Hour",
                "prompt": "Transform into VSCO Girl aesthetic with casual eco-friendly styling, golden hour lighting, and natural background while keeping face details"
            },
            {
                "title": "👑 Royalcore Elegance",
                "prompt": "Transform into Royalcore aesthetic with regal clothing, luxurious palace-like background, and elegant styling while preserving face"
            },
            {
                "title": "🧜 Mermaidcore Ocean",
                "prompt": "Transform into Mermaidcore aesthetic with aquatic elements, shells, oceanic mystique, and underwater vibes while maintaining face"
            },
            {
                "title": "🎨 Art Academia",
                "prompt": "Transform into Art Academia aesthetic with artistic bohemian styling, museum gallery background, and creative atmosphere while keeping face recognizable"
            }
        ]
