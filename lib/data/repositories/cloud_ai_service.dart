import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/prompt_suggestion.dart';
import '../../presentation/features/usage/token_cubit.dart';
import '../../core/utils/logger.dart';

class CloudAIService {
  static final CloudAIService _instance = CloudAIService._internal();
  factory CloudAIService() => _instance;
  CloudAIService._internal();

  // Get Firebase Functions instance
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Generate new image based on original image and text prompt using Firebase function
  Future<Uint8List?> generateImageFromTextAndImage({
    required File originalImage,
    required String prompt,
    File? referenceImage,
  }) async {
    try {
      // Read and encode the original image file to base64
      final imageBytes = await originalImage.readAsBytes();
      final base64Image = base64.encode(imageBytes);
      
      // Prepare request data
      final requestData = {
        'originalImage': base64Image,
        'prompt': prompt,
      };

      // Add reference image if provided
      if (referenceImage != null) {
        final referenceBytes = await referenceImage.readAsBytes();
        final base64Reference = base64.encode(referenceBytes);
        requestData['referenceImage'] = base64Reference;
      }

      // Call the Firebase function
      final callable = _functions.httpsCallable('generate_image');
      final result = await callable.call(requestData);
      final responseData = Map<String, dynamic>.from(result.data as Map);
      
      if (responseData['imageData'] != null) {
        // Decode the base64 image data
        final imageData = responseData['imageData'] as String;
        
        return base64.decode(imageData);
      } else if (responseData['error'] != null) {
        throw Exception('Cloud AI Error: ${responseData['error']}');
      }
      
      return null;
      
    } on FirebaseFunctionsException catch (e, stackTrace) {
      logger.e('📡 [CloudAI] Firebase Functions Exception during image generation', error: e, stackTrace: stackTrace);
      // Handle token-specific errors
      if (e.code == 'failed-precondition' && e.details?['needsTokens'] == true) {
        throw InsufficientTokensException(
          'Insufficient tokens to generate image', 
          currentBalance: e.details?['balance'] ?? 0,
        );
      } else {
        throw Exception('Failed to generate image: ${e.message}');
      }
    } catch (e, stackTrace) {
      logger.e('📡 [CloudAI] Unexpected error during image generation', error: e, stackTrace: stackTrace);
      throw Exception('Failed to generate image: $e');
    }
  }

  /// Analyze image and generate 20 stylish prompt suggestions using Firebase function
  Future<List<PromptSuggestion>> generatePromptSuggestions({
    required File imageFile,
  }) async {
    // Read and encode the image file to base64
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64.encode(imageBytes);
    
    // Prepare request data
    final requestData = {
      'imageData': base64Image,
    };

    // Call the Firebase function
    final callable = _functions.httpsCallable('generate_prompt_suggestions');
    final result = await callable.call(requestData);
    final responseData = Map<String, dynamic>.from(result.data as Map);
    
    if (responseData['suggestions'] != null) {
      final List<dynamic> suggestionsJson = responseData['suggestions'];
      final List<PromptSuggestion> suggestions = suggestionsJson
          .map((item) => PromptSuggestion.fromJson(item as Map<String, dynamic>))
          .take(20)
          .toList();
      
      // If we got fewer than 20, pad with fallback suggestions
      while (suggestions.length < 20) {
        final fallback = _getFallbackSuggestions();
        suggestions.addAll(fallback.take(20 - suggestions.length));
      }
      
      return suggestions.take(20).toList();
    } else if (responseData['error'] != null) {
      throw Exception('Cloud AI Error: ${responseData['error']}');
    }
    
    // If we reach here, throw exception to be handled by getSuggestions
    throw Exception('No suggestions data received from Firebase function');
  }

  /// Get suggested prompts for image editing (now powered by Firebase function)
  Future<List<PromptSuggestion>> getSuggestions({
    bool hasImage = false,
    required File imageFile,
  }) async {
    try {
      return _getFallbackSuggestions();
    } catch (e) {
      // Fall back to default suggestions if Firebase function fails
      return _getFallbackSuggestions();
    }
  }

  /// Get fallback suggestions if Firebase function fails
  List<PromptSuggestion> _getFallbackSuggestions() {
    return [
      const PromptSuggestion(
        title: '📚 Dark Academia',
        prompt: 'Transform into Dark Academia aesthetic with vintage clothing, moody library background, and intellectual atmosphere while preserving face details',
      ),
      const PromptSuggestion(
        title: '🤖 Cyberpunk Aesthetic',
        prompt: 'Transform into cyberpunk aesthetic with neon lights, futuristic clothing, and dystopian tech-noir background while keeping face recognizable',
      ),
      const PromptSuggestion(
        title: '✨ Y2K Retro',
        prompt: 'Transform into Y2K aesthetic with early 2000s metallic clothing, futuristic-retro accessories, and glossy finish while preserving facial features',
      ),
      const PromptSuggestion(
        title: '🌸 Soft Girl Aesthetic',
        prompt: 'Transform into Soft Girl aesthetic with pastel colors, kawaii elements, gentle feminine styling while maintaining face details',
      ),
      const PromptSuggestion(
        title: '🖤 Gothic Style',
        prompt: 'Transform into Gothic aesthetic with dramatic dark makeup, mysterious clothing, and moody atmosphere while keeping face recognizable',
      ),
      const PromptSuggestion(
        title: '💜 80s Synthwave',
        prompt: 'Transform into 80s aesthetic with neon synthwave colors, retro-futuristic styling, and vibrant background while preserving face',
      ),
      const PromptSuggestion(
        title: '🌻 Cottagecore Vibes',
        prompt: 'Transform into Cottagecore aesthetic with countryside setting, floral elements, and rustic charm while maintaining facial features',
      ),
      const PromptSuggestion(
        title: '🎵 K-Pop Style',
        prompt: 'Transform into K-Pop aesthetic with street luxury fashion, bold trendy styling, and modern urban background while keeping face details',
      ),
      const PromptSuggestion(
        title: '🧚 Fairycore Magic',
        prompt: 'Transform into Fairycore aesthetic with ethereal styling, magical flowers, sparkles, and dreamy atmosphere while preserving face',
      ),
      const PromptSuggestion(
        title: '🎸 Grunge Alternative',
        prompt: 'Transform into Grunge aesthetic with distressed clothing, alternative styling, and edgy urban background while maintaining face',
      ),
      const PromptSuggestion(
        title: '💎 Vaporwave Dream',
        prompt: 'Transform into Vaporwave aesthetic with pastel pink and blue colors, retro computer graphics, and nostalgic atmosphere while keeping face recognizable',
      ),
      const PromptSuggestion(
        title: '☀️ Clean Girl Look',
        prompt: 'Transform into Clean Girl aesthetic with minimal natural makeup, effortless styling, and bright natural lighting while preserving facial features',
      ),
      const PromptSuggestion(
        title: '💗 Barbiecore Pink',
        prompt: 'Transform into Barbiecore aesthetic with hot pink styling, glamorous doll-like perfection, and luxurious background while maintaining face details',
      ),
      const PromptSuggestion(
        title: '📼 90s Nostalgia',
        prompt: 'Transform into 90s aesthetic with grunge casual clothing, alternative rock styling, and vintage filter while keeping face recognizable',
      ),
      const PromptSuggestion(
        title: '🎌 Animecore Style',
        prompt: 'Transform into Animecore aesthetic with manga-inspired styling, vibrant colors, and stylized anime elements while preserving face',
      ),
      const PromptSuggestion(
        title: '⚙️ Steampunk Victorian',
        prompt: 'Transform into Steampunk aesthetic with Victorian-industrial styling, brass gears, vintage tech elements while maintaining facial features',
      ),
      const PromptSuggestion(
        title: '🌅 VSCO Golden Hour',
        prompt: 'Transform into VSCO Girl aesthetic with casual eco-friendly styling, golden hour lighting, and natural background while keeping face details',
      ),
      const PromptSuggestion(
        title: '👑 Royalcore Elegance',
        prompt: 'Transform into Royalcore aesthetic with regal clothing, luxurious palace-like background, and elegant styling while preserving face',
      ),
      const PromptSuggestion(
        title: '🧜 Mermaidcore Ocean',
        prompt: 'Transform into Mermaidcore aesthetic with aquatic elements, shells, oceanic mystique, and underwater vibes while maintaining face',
      ),
      const PromptSuggestion(
        title: '🎨 Art Academia',
        prompt: 'Transform into Art Academia aesthetic with artistic bohemian styling, museum gallery background, and creative atmosphere while keeping face recognizable',
      ),
    ];
  }

  /// Generate multiple images from a pack using Firebase function
  Future<PackGenerationResult?> generatePackImages({
    required File originalImage,
    required String packId,
  }) async {
    try {
      // Read and encode the original image file to base64
      final imageBytes = await originalImage.readAsBytes();
      final base64Image = base64.encode(imageBytes);
      
      // Prepare request data
      final requestData = {
        'originalImage': base64Image,
        'packId': packId,
      };

      // Call the Firebase function
      final callable = _functions.httpsCallable('generate_pack_images');
      final result = await callable.call(requestData);
      final responseData = Map<String, dynamic>.from(result.data as Map);
      
      if (responseData['images'] != null) {
        final List<dynamic> imagesData = responseData['images'];
        final List<GeneratedImage> images = imagesData
            .map((item) {
              // Handle different possible types from Firebase
              if (item is Map<String, dynamic>) {
                return GeneratedImage.fromJson(item);
              } else if (item is Map) {
                return GeneratedImage.fromJson(Map<String, dynamic>.from(item));
              } else {
                throw Exception('Unexpected item type in images array: ${item.runtimeType}');
              }
            })
            .toList();
        
        return PackGenerationResult(
          images: images,
          packName: responseData['packName'] as String,
          tokensRemaining: responseData['tokensRemaining'] as int,
          generatedCount: responseData['generatedCount'] as int,
          totalPrompts: responseData['totalPrompts'] as int,
        );
      } else if (responseData['error'] != null) {
        throw Exception('Cloud AI Error: ${responseData['error']}');
      }
      
      return null;
      
    } on FirebaseFunctionsException catch (e, stackTrace) {
      logger.e('📡 [CloudAI] Firebase Functions Exception during pack generation', error: e, stackTrace: stackTrace);
      // Handle token-specific errors
      if (e.code == 'failed-precondition' && e.details?['needsTokens'] == true) {
        throw InsufficientTokensException(
          'Insufficient tokens to generate pack', 
          currentBalance: e.details?['balance'] ?? 0,
          required: e.details?['required'] ?? 1,
        );
      } else {
        throw Exception('Failed to generate pack images: ${e.message}');
      }
    } catch (e, stackTrace) {
      logger.e('📡 [CloudAI] Unexpected error during pack generation', error: e, stackTrace: stackTrace);
      throw Exception('Failed to generate pack images: $e');
    }
  }
}

/// Result of pack generation
class PackGenerationResult {
  final List<GeneratedImage> images;
  final String packName;
  final int tokensRemaining;
  final int generatedCount;
  final int totalPrompts;

  const PackGenerationResult({
    required this.images,
    required this.packName,
    required this.tokensRemaining,
    required this.generatedCount,
    required this.totalPrompts,
  });
}

/// Generated image from pack
class GeneratedImage {
  final String imageUrl;
  final String prompt;
  final int index;

  const GeneratedImage({
    required this.imageUrl,
    required this.prompt,
    required this.index,
  });

  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      imageUrl: json['imageUrl'] as String,
      prompt: json['prompt'] as String,
      index: json['index'] as int,
    );
  }
}
