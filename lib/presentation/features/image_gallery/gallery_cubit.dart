import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../authentication/auth_service.dart';
import '../../../data/repositories/firebase_service.dart';
import '../../../data/models/gallery_image.dart';
import '../../../core/logger.dart';

part 'gallery_state.dart';

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit({
    AuthService? authService,
    FirebaseService? firebaseService,
  })  : _authService = authService ?? AuthService(),
        _firebaseService = firebaseService ?? FirebaseService(),
        super(const GalleryState());

  final AuthService _authService;
  final FirebaseService _firebaseService;

  /// Load user images from storage
  Future<void> loadUserImages() async {
    // Guard against concurrent loading
    if (state.loadingStatus == LoadingStatus.loading) return;
    
    final userId = _authService.getUserId();
    if (userId == null) return;

    emit(state.copyWith(loadingStatus: LoadingStatus.loading));

    try {
      final imagesData = await _firebaseService.getUserImages(userId);
      final images = imagesData.map((data) {
        return GalleryImage.fromFirestore(data, data['id'] as String);
      }).toList();
      emit(state.copyWith(
        loadingStatus: LoadingStatus.success,
        images: images,
      ));
    } catch (e, stackTrace) {
      logger.e('Failed to load user images', error: e, stackTrace: stackTrace);
      emit(state.copyWith(
        loadingStatus: LoadingStatus.failure,
        loadingErrorMessage: e.toString(),
      ));
    }
  }

  /// Delete an image by ID and filename with optimistic update
  Future<void> deleteImage(String id, String fileName) async {
    if (id.isEmpty || fileName.isEmpty) return;

    // Store original images for potential rollback
    final originalImages = List<GalleryImage>.from(state.images);
    
    // Optimistic update - remove image from UI immediately
    final updatedImages = state.images.where((image) => image.id != id).toList();
    emit(state.copyWith(images: updatedImages));

    try {
      await _firebaseService.deleteImage(id, fileName);
      // Image successfully deleted, keep the optimistic update
    } catch (e, stackTrace) {
      logger.e('Failed to delete image', error: e, stackTrace: stackTrace);
      // Rollback on failure - restore the original images
      emit(state.copyWith(
        images: originalImages,
        loadingErrorMessage: 'Failed to delete image: ${e.toString()}',
      ));
      // Reload to ensure consistency
      await loadUserImages();
    }
  }

  /// Save an image locally to the device photo gallery
  /// This method is used by ImageDetailCubit for saving images
  Future<void> saveImageLocally(GalleryImage image) async {

    try {
      // Check if we have permission to access photo library
      if (!await Gal.hasAccess()) {
        // Request permission
        if (!await Gal.requestAccess()) {
          throw Exception('Photo library access is required to save images');
        }
      }

      // Download image from Firebase Storage
      final response = await http.get(Uri.parse(image.imageUrl));
      
      if (response.statusCode == 200) {
        final Uint8List imageBytes = response.bodyBytes;
        
        // Save to device photo gallery
        await Gal.putImageBytes(imageBytes, album: 'Viral App');
      } else {
        throw Exception('Failed to download image (Status: ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to save image locally', error: e, stackTrace: stackTrace);
      String errorMessage = 'Failed to save image';
      if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please allow photo access in Settings.';
        logger.w('Photo library permission denied');
      } else if (e.toString().contains('network') || e.toString().contains('download')) {
        errorMessage = 'Network error. Please check your connection.';
        logger.w('Network error while downloading image for local save');
      } else {
        errorMessage = 'Failed to save image: ${e.toString()}';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Save generated image to gallery and Firebase storage
  Future<void> saveImageToGalleryAndFirebase({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    if (_authService.getUserId() == null) return;

    try {
      // Save to device gallery first
      await Gal.putImageBytes(imageBytes, album: 'Viral App');

      // Upload to Firebase for cloud storage
      try {
        final user = _authService.currentUser;
        if (user != null) {
          await _firebaseService.uploadImage(
            imageBytes: imageBytes,
            prompts: [prompt], // Single prompt for generated image
            userId: user.uid,
          );
        }

        // Reload gallery to show the newly saved image
        await loadUserImages();
      } catch (uploadError) {
        logger.e('Cloud upload failed but image saved locally', error: uploadError);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to save image to gallery and Firebase', error: e, stackTrace: stackTrace);
      throw Exception('Failed to save image: ${e.toString()}');
    }
  }
}
