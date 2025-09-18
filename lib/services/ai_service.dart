import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Your Google AI API key
  static const String _apiKey = 'AIzaSyAvNLyXHiDc4KzQ0q7PBwAx2VsrteKAasY';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';

  void initialize() {
    // No initialization needed for direct API calls
  }

  /// Generate new image based on original image and text prompt using direct API call
  Future<Uint8List?> generateImageFromTextAndImage({
    required File originalImage,
    required String prompt,
    File? referenceImage,
  }) async {
    try {
      // Read and encode the original image file to base64
      final imageBytes = await originalImage.readAsBytes();
      final base64Image = base64.encode(imageBytes);
      
      // Prepare parts array starting with text and original image
      List<Map<String, dynamic>> parts = [
        {
          'text':'Based on this image, create a new version: $prompt. Answer me by a picture, don\'t ask detail.',
        },
        {
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Image,
          }
        }
      ];

      // Add reference image if provided
      if (referenceImage != null) {
        final referenceBytes = await referenceImage.readAsBytes();
        final base64Reference = base64.encode(referenceBytes);
        parts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Reference,
          }
        });
      }

      // Prepare the request body
      final requestBody = {
        'contents': [
          {
            'parts': parts
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      // Make the API call
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Accept-Encoding': 'gzip', // Accept gzip compression
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // Debug: Print response info
        print('Response headers: ${response.headers}');
        print('Response body length: ${response.body.length}');
        print('Response bodyBytes length: ${response.bodyBytes.length}');
        print('Content-Type: ${response.headers['content-type']}');
        
        // Always try to parse as JSON first since Gemini API returns JSON
        try {
          final responseData = json.decode(response.body);
          print('Parsed JSON response keys: ${responseData.keys}');
          
          // Check for candidates structure (standard Gemini response)
          if (responseData['candidates'] != null && responseData['candidates'].isNotEmpty) {
            final candidate = responseData['candidates'][0];
            print('Candidate keys: ${candidate.keys}');
            
            if (candidate['content'] != null && candidate['content']['parts'] != null) {
              for (var part in candidate['content']['parts']) {
                print('Part keys: ${part.keys}');
                // Check for inlineData (camelCase, not snake_case)
                if (part['inlineData'] != null && part['inlineData']['data'] != null) {
                  // Decode the base64 image data
                  final imageData = part['inlineData']['data'];
                  print('Found image data, length: ${imageData.length}');
                  return base64.decode(imageData);
                }
              }
            }
          }
          
          // Check for error in response
          if (responseData['error'] != null) {
            throw Exception('API Error: ${responseData['error']}');
          }
          
          // Print full response for debugging
          print('Full response: ${json.encode(responseData)}');
          
        } catch (jsonError) {
          print('JSON parsing failed: $jsonError');
          print('Raw response body: ${response.body}');
          throw Exception('Failed to parse API response: $jsonError');
        }
        
      } else {
        throw Exception('API call failed with status: ${response.statusCode}, body: ${response.body}');
      }
      
      return null;
      
    } catch (e) {
      throw Exception('Failed to generate image: $e');
    }
  }

  /// Get hardcoded suggested prompts for image editing
  List<String> getHardcodedSuggestions({bool hasImage = false}) {
    return [
      'Add me a girlfriend',
      'Give me a classy costume',
      'Transform into a vintage film style',
      'Create a cartoon or anime version',
      'Add a magical fantasy background',
      'Apply cyberpunk atmosphere',
      'Make it look like a professional portrait',
      'Add a beautiful background',
      'Transform into an oil painting style',
    ];
  }
}