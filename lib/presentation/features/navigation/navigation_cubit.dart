import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit to manage navigation state across the app
class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0); // Start with Packs tab (index 0)

  /// Navigate to specific tab
  void navigateToTab(int index) {
    if (index >= 0 && index <= 2) {
      emit(index);
    }
  }

  /// Navigate to Packs tab
  void navigateToPacks() => navigateToTab(0);

  /// Navigate to Editor tab
  void navigateToEditor() => navigateToTab(1);

  /// Navigate to Gallery tab
  void navigateToGallery() => navigateToTab(2);
}
