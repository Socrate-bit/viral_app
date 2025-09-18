import 'package:flutter_bloc/flutter_bloc.dart';
import 'gallery_state.dart';

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit() : super(GalleryInitial());

  /// Load user images from storage
  Future<void> loadUserImages() async {
    emit(GalleryLoading());
    
    try {
      // TODO: Implement loading user images from Firebase/storage
      
      // For now, emit empty state
      emit(GalleryEmpty());
    } catch (e) {
      emit(GalleryError(message: e.toString()));
    }
  }

  /// Delete an image by ID and filename
  Future<void> deleteImage(String id, String fileName) async {
    try {
      // TODO: Implement image deletion from Firebase/storage
      
      // Reload images after deletion
      await loadUserImages();
    } catch (e) {
      emit(GalleryError(message: e.toString()));
    }
  }
}
