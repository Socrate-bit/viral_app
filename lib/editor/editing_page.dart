import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:io';
import 'dart:typed_data';

import 'editing_cubit.dart';
import 'editing_state.dart';
import '../gallery/gallery_cubit.dart';
import '../core/theme/colors.dart';

// Wrapper for editing page as a full screen page
class EditingPageScaffold extends StatelessWidget {
  const EditingPageScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditingCubit()..initialize(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlack,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.primaryText,
              size: 28,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Edit Image',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const EditingPage(),
      ),
    );
  }
}

class EditingPage extends StatefulWidget {
  const EditingPage({super.key});

  @override
  State<EditingPage> createState() => _EditingPageState();
}

class _EditingPageState extends State<EditingPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _hasTriggeredImagePick = false;

  @override
  void initState() {
    super.initState();
    _promptController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditingCubit, EditingState>(
      listenWhen: (previous, current) {
        // Listen when export status changes to success
        if (previous is EditingLoaded && current is EditingLoaded) {
          return previous.exportStatus != ExportStatus.success && 
                 current.exportStatus == ExportStatus.success;
        }
        return current is EditingError;
      },
      listener: (context, state) {
        if (state is EditingLoaded && state.exportStatus.isSuccess) {
          // Refresh gallery when image is exported
          context.read<GalleryCubit>().loadUserImages();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image saved to gallery'),
              backgroundColor: AppColors.gradientOrange,
            ),
          );
        } else if (state is EditingError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<EditingCubit, EditingState>(
        builder: (context, state) {
          if (state is EditingInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! EditingLoaded) {
            return const Center(child: Text('Something went wrong'));
          }

          // Auto-trigger image picking when page loads with no image and not loading
          if (!_hasTriggeredImagePick && !state.hasImageContent && !state.generationStatus.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _hasTriggeredImagePick = true;
              context.read<EditingCubit>().pickImageFromGallery();
            });
          }

          return Container(
            color: AppColors.backgroundColor,
            child: GestureDetector(
              onTap: () {
                // Unfocus keyboard when tapping outside
                FocusScope.of(context).unfocus();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 32),
                child: Column(
                  children: [
                    // Action buttons row with navigation arrows
                    _buildActionButtons(state),

                    // Image upload area
                    Expanded(flex: 3, child: _buildImageArea(state)),

                    const SizedBox(height: 10),

                    // Suggestions section
                    _buildSuggestionsSection(state),

                    const SizedBox(height: 10),

                    // Additional image section
                    _buildAdditionalImageSection(state),

                    // Prompt input area with send button
                    _buildPromptInputArea(state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(EditingLoaded state) {
    return Row(
      children: [
        _buildBackArrow(state),
        _buildNewButton(state),
        _buildVersionIndicator(state),
        _buildExportButton(state),
        _buildForwardArrow(state),
      ],
    );
  }

  Widget _buildBackArrow(EditingLoaded state) {
    return GestureDetector(
      onTap: (state.totalVersions > 1 && state.displayedVersion > 0)
          ? () => context.read<EditingCubit>().goToPreviousVersion()
          : null,
      child: Icon(
        Icons.arrow_back_ios,
        size: 24,
        color: (state.totalVersions > 1 && state.displayedVersion > 0)
            ? AppColors.primaryText
            : AppColors.inactiveIcon,
      ),
    );
  }

  Widget _buildNewButton(EditingLoaded state) {
    return Expanded(
      child: Center(
        child: TextButton(
          onPressed: () => context.read<EditingCubit>().pickImage(),
          child: Text(
            'New',
            style: TextStyle(
              color: (state.selectedImage != null ||
                      state.currentDisplayImage != null)
                  ? AppColors.primaryText
                  : AppColors.inactiveIcon,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionIndicator(EditingLoaded state) {
    return SizedBox(
      width: 60,
      child: Center(
        child: state.totalVersions > 1
            ? Text(
                '${state.displayedVersion}/${state.totalVersions - 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildExportButton(EditingLoaded state) {
    return Expanded(
      child: Center(
        child: TextButton(
          onPressed: (state.selectedImage == null &&
                      state.currentDisplayImage == null) ||
                  state.exportStatus.isSuccess
              ? null
              : () => context.read<EditingCubit>().exportCurrentImage(
                  _promptController.text.trim(),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.exportStatus.isSuccess) ...[
                const Icon(
                  Icons.check_circle,
                  color: AppColors.inactiveIcon,
                  size: 20,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                state.exportStatus.isSuccess ? 'Exported' : 'Export',
                style: TextStyle(
                  color: (state.selectedImage == null &&
                          state.currentDisplayImage == null)
                      ? AppColors.inactiveIcon
                      : state.exportStatus.isSuccess
                          ? AppColors.inactiveIcon
                          : AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForwardArrow(EditingLoaded state) {
    return GestureDetector(
      onTap: (state.totalVersions > 1 &&
              state.displayedVersion < state.totalVersions - 1)
          ? () => context.read<EditingCubit>().goToNextVersion()
          : null,
      child: Icon(
        Icons.arrow_forward_ios,
        size: 24,
        color: (state.totalVersions > 1 &&
                state.displayedVersion < state.totalVersions - 1)
            ? AppColors.primaryText
            : AppColors.inactiveIcon,
      ),
    );
  }

  Widget _buildImageArea(EditingLoaded state) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            (state.currentDisplayImage != null || state.selectedImage != null)
            ? Colors.transparent
            : AppColors.mediumGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Main image display with zoom functionality
          state.currentDisplayImage != null
              ? _buildDisplayImage(state.currentDisplayImage!)
              : state.selectedImage != null
              ? _buildSelectedImage(state.selectedImage!)
              : _buildImagePlaceholder(),

          // Loading overlay when generating
          if (state.generationStatus.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildDisplayImage(Uint8List imageBytes) {
    return GestureDetector(
      onLongPress: () => context.read<EditingCubit>().cropImage(),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(imageBytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImage(File imageFile) {
    return GestureDetector(
      onLongPress: () => context.read<EditingCubit>().cropImage(),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(imageFile, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return GestureDetector(
      onTap: () => context.read<EditingCubit>().pickImage(),
      child: DottedBorder(
        options: RectDottedBorderOptions(
          color: AppColors.inactiveIcon,
          strokeWidth: 2,
          dashPattern: const [8, 4],
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library,
                size: 64,
                color: AppColors.inactiveIcon,
              ),
              SizedBox(height: 16),
              Text(
                'Tap to select from Photos',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Choose an image to get started',
                style: TextStyle(color: AppColors.inactiveIcon, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.gradientOrange,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Generating image...',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(EditingLoaded state) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: state.suggestedPrompts
            .map((prompt) => _buildSuggestionChip(prompt))
            .toList(),
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _promptController.text = suggestion,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.mediumGrey,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.lightGrey, width: 1),
          ),
          child: Text(
            suggestion,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalImageSection(EditingLoaded state) {
    if (state.additionalImage == null) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.mediumGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: Row(
            children: [
              // Reference image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  state.additionalImage!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Image',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    context.read<EditingCubit>().removeAdditionalImage(),
                icon: const Icon(
                  Icons.close,
                  color: AppColors.primaryText,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPromptInputArea(EditingLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (state.generationStatus.isLoading || !state.hasImageContent)
            ? AppColors.lightGrey
            : AppColors.mediumGrey,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.lightGrey, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              enabled: !state.generationStatus.isLoading && state.hasImageContent,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: state.generationStatus.isLoading
                    ? 'Generating image...'
                    : !state.hasImageContent
                    ? 'Load an image first...'
                    : 'Describe your modification...',
                hintStyle: TextStyle(
                  color: (state.generationStatus.isLoading || !state.hasImageContent)
                      ? AppColors.inactiveIcon
                      : AppColors.secondaryText,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              style: TextStyle(
                fontSize: 16,
                color: (state.generationStatus.isLoading || !state.hasImageContent)
                    ? AppColors.inactiveIcon
                    : AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Additional image button
          GestureDetector(
            onTap: (state.generationStatus.isLoading || !state.hasImageContent)
                ? null
                : () => context.read<EditingCubit>().pickAdditionalImage(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: state.additionalImage != null
                    ? AppColors.gradientOrange.withValues(alpha: 0.2)
                    : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.image,
                color: state.additionalImage != null
                    ? AppColors.gradientOrange
                    : AppColors.secondaryText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: (state.generationStatus.isLoading || !state.hasImageContent)
                ? null
                : () {
                     if (_promptController.text.trim().isNotEmpty) {
                       context.read<EditingCubit>().generateImage(
                         _promptController.text.trim(),
                       );
                     }
                  },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (state.generationStatus.isLoading || !state.hasImageContent)
                    ? AppColors.inactiveIcon
                    : _promptController.text.trim().isNotEmpty
                    ? AppColors.primaryBlack
                    : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: AppColors.pureWhite,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
