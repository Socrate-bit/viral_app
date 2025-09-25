import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'editing_state.dart';
import '../../../data/repositories/cloud_ai_service.dart';
import '../../../data/repositories/firebase_service.dart';
import '../authentication/auth_service.dart';
import '../image_gallery/gallery_cubit.dart';
import '../usage/token_cubit.dart';
import '../../../core/utils/logger.dart';

class EditingCubit extends Cubit<EditingState> {
  EditingCubit({GalleryCubit? galleryCubit, TokenCubit? tokenCubit})
    : _galleryCubit = galleryCubit,
      _tokenCubit = tokenCubit,
      super(EditingInitial());

  final ImagePicker _imagePicker = ImagePicker();
  final CloudAIService _aiService = CloudAIService();
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  final GalleryCubit? _galleryCubit;
  final TokenCubit? _tokenCubit;

  // Directory for storing temporary image versions
  late final Directory _tempVersionsDir;
  bool _isInitialized = false;

  /// Initialize the editing cubit (call on app authentication)
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _initializeTempDirectory();
      _isInitialized = true;
    }
  }

  /// Pick image from gallery
  Future<void> loadImageFromGallery() async {
    try {
      final imageFile = await _getImageFromGallery();
      if (imageFile != null) {
        await _setImageAndGenerateSuggestions(imageFile);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to pick image from gallery', error: e, stackTrace: stackTrace);
      emit(
        EditingError(
          message: 'Failed to pick image from gallery: ${e.toString()}',
        ),
      );
    }
  }

  /// Load an image from URL for editing
  Future<void> loadImageFromUrl(String imageUrl) async {
    try {
      File imageFile;
      if (imageUrl.startsWith('file://')) {
        // Local file path
        imageFile = File(imageUrl.replaceFirst('file://', ''));
      } else {
        // Remote URL - download it
        imageFile = await _firebaseService.downloadImageToFile(imageUrl);
      }
      await _setImageAndGenerateSuggestions(imageFile);
    } catch (e, stackTrace) {
      logger.e('Failed to load image from URL: $imageUrl', error: e, stackTrace: stackTrace);
      emit(
        EditingError(message: 'Failed to load image from URL: ${e.toString()}'),
      );
    }
  }

  /// Load image from File for editing  
  Future<void> loadImageFromFile(File imageFile) async {
    try {
      await _setImageAndGenerateSuggestions(imageFile);
    } catch (e, stackTrace) {
      logger.e('Failed to load image from file', error: e, stackTrace: stackTrace);
      emit(
        EditingError(message: 'Failed to load image: ${e.toString()}'),
      );
    }
  }

  /// Get image file from gallery
  Future<File?> _getImageFromGallery() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    return pickedFile != null ? File(pickedFile.path) : null;
  }

  /// Set image in state and generate suggestions (common logic)
  Future<void> _setImageAndGenerateSuggestions(File imageFile) async {
    final currentState = state;
    if (currentState is EditingLoaded) {
      // Clear previous versions when setting new image
      await _clearImageVersions(currentState.imageVersionFiles);
    }

    // Initialize temp directory if needed
    if (!_isInitialized) {
      await _initializeTempDirectory();
      _isInitialized = true;
    } else {
      try {
        if (!await _tempVersionsDir.exists()) {
          await _initializeTempDirectory();
        }
      } catch (e) {
        logger.w('Temp directory does not exist, reinitializing', error: e);
        await _initializeTempDirectory();
      }
    }

    // Emit completely new state with the image
    emit(
      EditingLoaded(
        initialImage: imageFile,
        suggestionsStatus: SuggestionsStatus.loading,
      ),
    );

    // Generate suggestions after setting image
    await _generateSuggestions();
  }

  /// Generate AI-powered suggestions based on the current image
  Future<void> _generateSuggestions() async {
    try {
      final currentState = state;
      if (currentState is EditingLoaded) {
        // Set loading state
        emit(
          currentState.copyWith(suggestionsStatus: SuggestionsStatus.loading),
        );

        // Get suggestions from Google Gemini Vision AI service by analyzing the current image
        final suggestions = await _aiService.getSuggestions(
          hasImage: true,
          imageFile: currentState.currentImageFile,
        );

        emit(
          currentState.copyWith(
            suggestedPrompts: suggestions,
            suggestionsStatus: SuggestionsStatus.success,
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.e('Failed to generate AI suggestions', error: e, stackTrace: stackTrace);
      final currentState = state;
      if (currentState is EditingLoaded) {
        emit(
          currentState.copyWith(suggestionsStatus: SuggestionsStatus.failure),
        );
      }
    }
  }

  /// Initialize temp directory for image versions
  Future<void> _initializeTempDirectory() async {
    final tempDir = await getTemporaryDirectory();

    // Clean up old version directories from previous sessions
    await cleanupOrphanedVersionDirectories();

    // Create new temp directory for this session
    _tempVersionsDir = Directory(
      '${tempDir.path}/image_versions_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!await _tempVersionsDir.exists()) {
      await _tempVersionsDir.create(recursive: true);
    }
  }

  /// Static method to clean up all orphaned version directories on app startup
  static Future<void> cleanupOrphanedVersionDirectories() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final entities = await tempDir.list().toList();

      for (final entity in entities) {
        if (entity is Directory && entity.path.contains('image_versions_')) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            logger.w('Failed to delete orphaned directory: ${entity.path}', error: e);
          }
        }
      }
    } catch (e) {
      logger.w('Failed to cleanup orphaned version directories', error: e);
    }
  }

  /// Create a new version file from image bytes
  Future<File> _createVersionFile(Uint8List imageBytes) async {
    final fileName = 'version_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final versionFile = File('${_tempVersionsDir.path}/$fileName');
    await versionFile.writeAsBytes(imageBytes);
    return versionFile;
  }

  /// Clear image version files from disk and state
  Future<void> _clearImageVersions(List<File> versionFiles) async {
    for (final file in versionFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        logger.d('Failed to delete version file: ${file.path}', error: e);
      }
    }
  }

  /// Navigate to a specific version (helper method)
  void _navigateToVersion(int newVersion, EditingLoaded currentState) {
    emit(
      currentState.copyWith(
        currentVersion: newVersion,
        exportStatus: ExportStatus.idle,
      ),
    );
  }

  /// Go to previous version of the image
  void goToPreviousVersion() {
    final currentState = state;
    if (currentState is EditingLoaded &&
        currentState.totalVersions > 1 &&
        currentState.displayedVersion > 0) {
      _navigateToVersion(currentState.displayedVersion - 1, currentState);
    }
    // Silently ignore invalid calls - this is expected UI behavior
  }

  /// Go to next version of the image
  void goToNextVersion() {
    final currentState = state;
    if (currentState is EditingLoaded &&
        currentState.totalVersions > 1 &&
        currentState.displayedVersion < currentState.totalVersions - 1) {
      _navigateToVersion(currentState.displayedVersion + 1, currentState);
    }
    // Silently ignore invalid calls - this is expected UI behavior
  }

  /// Pick additional image for AI generation
  Future<void> pickAdditionalImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final currentState = state;
        if (currentState is EditingLoaded) {
          emit(
            currentState.copyWith(
              additionalImage: imageFile,
              exportStatus: ExportStatus.idle,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to pick additional image', error: e, stackTrace: stackTrace);
      emit(
        EditingError(
          message: 'Failed to pick additional image: ${e.toString()}',
        ),
      );
    }
  }

  /// Remove additional image
  void removeAdditionalImage() {
    final currentState = state;
    if (currentState is EditingLoaded) {
      emit(currentState.copyWith(clearAdditionalImage: true));
    }
  }

  /// Generate image with AI using prompt
  Future<void> generateImage(String prompt) async {
    try {
      // Check if user has enough tokens before making the request
      if (_tokenCubit != null && !_tokenCubit.hasEnoughTokens(requiredTokens: 1)) {
        // Show conditional paywall if insufficient tokens
        await _tokenCubit.showConditionalPaywall();
        return; // Exit early without making the request
      }

      final currentState = state;
      if (currentState is EditingLoaded) {
        emit(currentState.copyWith(generationStatus: GenerationStatus.loading));

        // Get the base image for AI generation (use currently displayed image)
        final baseImage = currentState.currentImageFile;

        // Generate new image using AI service
        final Uint8List? generatedImageBytes = await _aiService
            .generateImageFromTextAndImage(
              originalImage: baseImage,
              prompt: prompt,
              referenceImage: currentState.additionalImage,
            );

        if (generatedImageBytes != null) {
          // If generating from a version that's not the latest, delete all versions after current
          List<File> updatedVersionFiles = List<File>.from(currentState.imageVersionFiles);
          List<String> updatedVersionPrompts = List<String>.from(currentState.promptsHistory);
          
          if (currentState.displayedVersion < currentState.totalVersions - 1) {
            // We're not at the latest version, so remove all versions after current
            final versionsToDelete = updatedVersionFiles.sublist(currentState.displayedVersion);
            await _clearImageVersions(versionsToDelete);
            
            // Keep only versions up to current displayed version
            updatedVersionFiles = updatedVersionFiles.sublist(0, currentState.displayedVersion);
            updatedVersionPrompts = updatedVersionPrompts.sublist(0, currentState.displayedVersion);
          }

          // Create new version file and add to versions list
          final newVersionFile = await _createVersionFile(generatedImageBytes);
          updatedVersionFiles.add(newVersionFile);
          updatedVersionPrompts.add(prompt);

          final newCurrentVersion = updatedVersionFiles.length; // Point to the new latest version

          emit(
            currentState.copyWith(
              generationStatus: GenerationStatus.success,
              currentVersion: newCurrentVersion,
              imageVersionFiles: updatedVersionFiles,
              versionPrompts: updatedVersionPrompts,
              exportStatus: ExportStatus.idle,
            ),
          );
        } else {
          emit(
            currentState.copyWith(generationStatus: GenerationStatus.failure),
          );
          emit(
            EditingError(
              message: 'Failed to generate image. Please try again.',
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to generate image with prompt: $prompt', error: e, stackTrace: stackTrace);
      final currentState = state;
      if (currentState is EditingLoaded) {
        emit(currentState.copyWith(generationStatus: GenerationStatus.failure));
      }
      
      // Check if this is a token-related error
      if (e.toString().contains('Insufficient tokens')) {
        logger.w('Insufficient tokens for image generation');
        _tokenCubit?.showConditionalPaywall();
        emit(EditingError(message: 'Insufficient tokens. Please purchase more tokens to continue.'));
      } else {
        emit(EditingError(message: 'Failed to generate image: ${e.toString()}'));
      }
    }
  }

  /// Crop the current image
  Future<void> cropImage() async {
    try {
      final currentState = state;
      if (currentState is EditingLoaded) {
        // Get the currently displayed image file
        final imageToEdit = currentState.currentImageFile;

        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: imageToEdit.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: const Color(0xFF000000),
              toolbarWidgetColor: const Color(0xFFFFFFFF),
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              backgroundColor: const Color(0xFF000000),
            ),
            IOSUiSettings(title: 'Crop Image', minimumAspectRatio: 0.1),
          ],
        );

        if (croppedFile != null) {
          final File croppedImageFile = File(croppedFile.path);

          if (currentState.displayedVersion == 0) {
            // Update the original initial image
            emit(
              currentState.copyWith(
                initialImage: croppedImageFile,
                exportStatus: ExportStatus.idle,
              ),
            );
          } else {
            // Create a new version for the cropped image
            final croppedBytes = await croppedImageFile.readAsBytes();

            // Create new version file and add to versions list
            final newVersionFile = await _createVersionFile(croppedBytes);
            final updatedVersionFiles = List<File>.from(
              currentState.imageVersionFiles,
            )..add(newVersionFile);

            // Add empty prompt for cropped version (since it wasn't generated with AI)
            final updatedVersionPrompts = List<String>.from(
              currentState.promptsHistory,
            )..add('');

            final newCurrentVersion =
                currentState.totalVersions; // Point to the new latest version

            emit(
              currentState.copyWith(
                currentVersion: newCurrentVersion,
                imageVersionFiles: updatedVersionFiles,
                versionPrompts: updatedVersionPrompts,
                exportStatus: ExportStatus.idle,
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to crop image', error: e, stackTrace: stackTrace);
      emit(EditingError(message: 'Failed to crop image: ${e.toString()}'));
    }
  }

  /// Export current image to gallery and firebase (optimistic update)
  Future<void> exportCurrentImage(String prompt) async {
    final currentState = state;
    if (currentState is! EditingLoaded) return;

    // Store previous state for potential rollback
    final previousExportStatus = currentState.exportStatus;

    // Optimistic update - immediately show success
    emit(currentState.copyWith(exportStatus: ExportStatus.success));

    try {
      // Get the currently displayed image file
      final imageFile = currentState.currentImageFile;

      // Save to gallery using gal package (use file directly)
      await Gal.putImage(imageFile.path);

      // Also upload to Firebase for cloud storage
      try {
        final user = _authService.currentUser;
        if (user != null) {
          // Get all prompts from version history
          final allPrompts = _getAllPrompts(currentState, prompt);

          // Read bytes only for Firebase upload
          final imageToExport = await imageFile.readAsBytes();
          await _firebaseService.uploadImage(
            imageBytes: imageToExport,
            prompts: allPrompts,
            userId: user.uid,
          );
        }

        // Reload gallery to show the newly saved image
        _galleryCubit?.loadUserImages();
      } catch (uploadError) {
        logger.e('Cloud upload failed during image export', error: uploadError);
      }

      // Export completed successfully - success state already set optimistically
    } catch (e, stackTrace) {
      logger.e('Failed to export current image', error: e, stackTrace: stackTrace);
      // Rollback optimistic update and show error
      final rollbackState = state;
      if (rollbackState is EditingLoaded) {
        emit(rollbackState.copyWith(exportStatus: previousExportStatus));
      }
      emit(EditingError(message: 'Failed to export image: ${e.toString()}'));
    }
  }

  /// Get prompts from version history up to the displayed version
  List<String> _getAllPrompts(EditingLoaded state, String currentPrompt) {
    final List<String> allPrompts = [];

    // Only include prompts up to the displayed version
    // If displayedVersion is 0 (initial image), include no version prompts
    // If displayedVersion is 1, include prompts[0] only
    // If displayedVersion is 2, include prompts[0] and prompts[1], etc.
    final int maxPromptIndex = state.displayedVersion;

    for (
      int i = 0;
      i < maxPromptIndex && i < state.promptsHistory.length;
      i++
    ) {
      final versionPrompt = state.promptsHistory[i].trim();
      if (versionPrompt.isNotEmpty) {
        allPrompts.add(versionPrompt);
      }
    }

    return allPrompts;
  }

  /// Reset to initial state
  Future<void> resetToInitial() async {
    final currentState = state;

    // Clean up any temporary files if in loaded state
    if (currentState is EditingLoaded) {
      await _clearImageVersions(currentState.imageVersionFiles);
    }

    // Reset to initial state
    emit(EditingInitial());
  }

  @override
  Future<void> close() async {
    // Clean up all orphaned version directories when cubit is disposed
    await cleanupOrphanedVersionDirectories();

    return super.close();
  }
}
