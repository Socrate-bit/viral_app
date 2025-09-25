import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viral_app/presentation/features/image_gallery/gallery_cubit.dart';
import '../../../data/models/gallery_image.dart';
import 'image_detail_state.dart';
import '../../../core/utils/logger.dart';

class ImageDetailCubit extends Cubit<ImageDetailState> {
  ImageDetailCubit(this._galleryCubit) : super(ImageDetailInitial());

  final GalleryCubit _galleryCubit;

  /// Initialize the cubit
  void initialize() {
    emit(const ImageDetailLoaded());
  }

  /// Save image to local photos with optimistic update
  Future<void> saveImage(GalleryImage image) async {
    final currentState = state;
    if (currentState is! ImageDetailLoaded) return;

    // Optimistic update - immediately mark as saved
    emit(currentState.copyWith(saveStatus: SaveStatus.saved));

    try {
      // Actually save the image using gallery cubit
      _galleryCubit.saveImageLocally(image);
    } catch (e, stackTrace) {
      logger.e('Failed to save image locally from image detail', error: e, stackTrace: stackTrace);
      // If save fails, revert to error state
      emit(currentState.copyWith(
        saveStatus: SaveStatus.error,
        errorMessage: 'Failed to save image: ${e.toString()}',
      ));
    }
  }

  /// Copy prompts from GalleryImage to clipboard
  Future<void> copyPromptsFromImage(GalleryImage image) async {
    final currentState = state;
    if (currentState is! ImageDetailLoaded) return;

    final aggregatedPrompts = image.aggregatedPrompts;
    
    // Don't copy if no prompts available
    if (aggregatedPrompts == 'No prompt available') {
      emit(currentState.copyWith(
        copyStatus: CopyStatus.error,
        errorMessage: 'No prompts to copy',
      ));
      return;
    }

    try {
      emit(currentState.copyWith(copyStatus: CopyStatus.copying));
      
      await Clipboard.setData(ClipboardData(text: aggregatedPrompts));
      
      emit(currentState.copyWith(
        copyStatus: CopyStatus.copied,
        clearError: true,
      ));
    } catch (e, stackTrace) {
      logger.e('Failed to copy prompts to clipboard', error: e, stackTrace: stackTrace);
      emit(currentState.copyWith(
        copyStatus: CopyStatus.error,
        errorMessage: 'Failed to copy prompts: ${e.toString()}',
      ));
    }
  }

  /// Copy prompts to clipboard (legacy method for backward compatibility)
  Future<void> copyPrompts(Map<String, dynamic> image) async {
    final currentState = state;
    if (currentState is! ImageDetailLoaded) return;

    final aggregatedPrompts = getAggregatedPrompts(image);
    
    // Don't copy if no prompts available
    if (aggregatedPrompts == 'No prompt available') {
      emit(currentState.copyWith(
        copyStatus: CopyStatus.error,
        errorMessage: 'No prompts to copy',
      ));
      return;
    }

    try {
      emit(currentState.copyWith(copyStatus: CopyStatus.copying));
      
      await Clipboard.setData(ClipboardData(text: aggregatedPrompts));
      
      emit(currentState.copyWith(
        copyStatus: CopyStatus.copied,
        clearError: true,
      ));
    } catch (e, stackTrace) {
      logger.e('Failed to copy prompts to clipboard', error: e, stackTrace: stackTrace);
      emit(currentState.copyWith(
        copyStatus: CopyStatus.error,
        errorMessage: 'Failed to copy prompts: ${e.toString()}',
      ));
    }
  }

  /// Reset state when modal is closed
  void reset() {
    emit(const ImageDetailLoaded());
  }

  /// Get aggregated prompts from image data
  String getAggregatedPrompts(Map<String, dynamic> image) {
    // Get the prompts list
    final List<dynamic>? promptsList = image['prompts'];
    
    // If no prompts list, check for legacy single prompt
    if (promptsList == null || promptsList.isEmpty) {
      final String? legacyPrompt = image['prompt'];
      if (legacyPrompt != null && legacyPrompt.trim().isNotEmpty) {
        // Remove trailing periods and add one at the end
        final cleanPrompt = legacyPrompt.trim().replaceAll(RegExp(r'\.+$'), '');
        return '$cleanPrompt.';
      }
      return 'No prompt available';
    }
    
    // Aggregate all prompts from the list
    final List<String> validPrompts = [];
    
    for (final prompt in promptsList) {
      if (prompt != null && prompt.toString().trim().isNotEmpty) {
        // Remove trailing periods from individual prompts to avoid double periods
        final cleanPrompt = prompt.toString().trim().replaceAll(RegExp(r'\.+$'), '');
        validPrompts.add(cleanPrompt);
      }
    }
    
    return validPrompts.isEmpty 
        ? 'No prompt available' 
        : '${validPrompts.join('. ')}.';
  }

  /// Clear any error states
  void clearError() {
    final currentState = state;
    if (currentState is ImageDetailLoaded) {
      emit(currentState.copyWith(clearError: true));
    }
  }
}
