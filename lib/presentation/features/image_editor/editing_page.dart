import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:viral_app/data/models/prompt_suggestion.dart';
import 'dart:io';

import 'editing_cubit.dart';
import 'editing_state.dart';
import '../../core/theme/colors.dart';

// Wrapper for editing page as a full screen page
class EditingPageScaffold extends StatelessWidget {
  const EditingPageScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the cubit when entering the editing page

    return Scaffold(
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
    );
  }
}

class EditingPage extends StatelessWidget {
  const EditingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditingCubit, EditingState>(
      listenWhen: (previous, current) {
        // Listen only for error states
        return current is EditingError;
      },
      listener: (context, state) {
        if (state is EditingError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Container(
          color: AppColors.backgroundColor,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
            child: switch (state) {
              EditingInitial() => const EditingInitialWidget(),
              EditingLoaded() => EditingLoadedWidget(state: state),
              EditingError() => EditingErrorWidget(state: state),
            },
          ),
        );
      },
    );
  }
}

class EditingInitialWidget extends StatefulWidget {
  const EditingInitialWidget({super.key});

  @override
  State<EditingInitialWidget> createState() => _EditingInitialWidgetState();
}

class _EditingInitialWidgetState extends State<EditingInitialWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the breathing animation
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(flex: 6, child: _buildImagePlaceholder(context)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () => context.read<EditingCubit>().loadImageFromGallery(),
          child: Transform.scale(
            scale: _isPressed ? 0.95 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              child: DottedBorder(
                options: RectDottedBorderOptions(
                  color: AppColors.gradientOrange.withOpacity(
                    _fadeAnimation.value * 0.95,
                  ),
                  strokeWidth: 3.5,
                  dashPattern: const [16, 8],
                ),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.gradientOrange.withOpacity(
                                  0.4 * _fadeAnimation.value,
                                ),
                                AppColors.gradientRed.withOpacity(
                                  0.3 * _fadeAnimation.value,
                                ),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gradientOrange.withOpacity(
                                  0.4 * _fadeAnimation.value,
                                ),
                                blurRadius: 25,
                                spreadRadius: 4,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: AppColors.gradientRed.withOpacity(
                                  0.2 * _fadeAnimation.value,
                                ),
                                blurRadius: 40,
                                spreadRadius: 1,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 72,
                            color: AppColors.gradientOrange.withOpacity(
                              _fadeAnimation.value,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Tap to select a picture',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: AppColors.gradientOrange.withOpacity(
                                0.3 * _fadeAnimation.value,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.mediumGrey.withOpacity(0.6),
                              AppColors.darkGrey.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.gradientOrange.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Choose an image to get started with AI magic ✨',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryText.withOpacity(
                              _fadeAnimation.value * 0.9,
                            ),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class EditingErrorWidget extends StatelessWidget {
  final EditingError state;

  const EditingErrorWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildErrorContent(),
              const SizedBox(height: 32),
              _buildRetryButton(context),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 24),
        const Text(
          'Oops! Something went wrong',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          state.message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.read<EditingCubit>().loadImageFromGallery(),
      icon: const Icon(Icons.refresh, color: AppColors.primaryText),
      label: const Text(
        'Try Again',
        style: TextStyle(
          color: AppColors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mediumGrey,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: const BorderSide(color: AppColors.lightGrey),
        ),
      ),
    );
  }
}

class EditingLoadedWidget extends StatefulWidget {
  final EditingLoaded state;

  const EditingLoadedWidget({super.key, required this.state});

  @override
  State<EditingLoadedWidget> createState() => _EditingLoadedWidgetState();
}

class _EditingLoadedWidgetState extends State<EditingLoadedWidget> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _promptController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
    // Set initial prompt based on current version
    _promptController.text = widget.state.currentVersionPrompt;
  }

  @override
  void didUpdateWidget(EditingLoadedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update prompt when version changes
    if (oldWidget.state.displayedVersion != widget.state.displayedVersion) {
      _promptController.text = widget.state.currentVersionPrompt;
    }
    // Clear prompt when a new version is successfully generated
    if (oldWidget.state.generationStatus.isLoading &&
        widget.state.generationStatus.isSuccess &&
        oldWidget.state.totalVersions < widget.state.totalVersions) {
      _promptController.clear();
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        // Action buttons row with navigation arrows
        _buildActionButtons(widget.state),

        // Image upload area
        Expanded(flex: 4, child: _buildImageArea(widget.state)),

        // Suggestions section
        _buildSuggestionsSection(widget.state),

        // Additional image section
        if (widget.state.additionalImage != null)
          _buildAdditionalImageSection(widget.state),

        // Prompt input area with send button
        _buildPromptInputArea(widget.state),
      ],
    );
  }

  Widget _buildActionButtons(EditingLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildBackArrow(state),
          _buildNewButton(state),
          _buildVersionIndicator(state),
          _buildExportButton(state),
          _buildForwardArrow(state),
        ],
      ),
    );
  }

  Widget _buildBackArrow(EditingLoaded state) {
    final canGoBack = state.totalVersions > 1 && state.displayedVersion > 0;

    return GestureDetector(
      onTap: () => context.read<EditingCubit>().goToPreviousVersion(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: canGoBack
              ? AppColors.lightGrey.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.arrow_back_ios,
          size: 20,
          color: canGoBack ? AppColors.primaryText : AppColors.inactiveIcon,
        ),
      ),
    );
  }

  Widget _buildNewButton(EditingLoaded state) {
    return Expanded(
      child: Center(
        child: TextButton(
          onPressed: () => context.read<EditingCubit>().resetToInitial(),
          child: const Text(
            'New',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 22,
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
                  fontSize: 20,
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
          onPressed: state.exportStatus.isSuccess
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
                state.exportStatus.isSuccess ? 'Saved' : 'Save',
                style: TextStyle(
                  color: state.exportStatus.isSuccess
                      ? AppColors.inactiveIcon
                      : AppColors.primaryText,
                  fontSize: 20,
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
    final canGoForward =
        state.totalVersions > 1 &&
        state.displayedVersion < state.totalVersions - 1;

    return GestureDetector(
      onTap: () => context.read<EditingCubit>().goToNextVersion(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: canGoForward
              ? AppColors.lightGrey.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.arrow_forward_ios,
          size: 20,
          color: canGoForward ? AppColors.primaryText : AppColors.inactiveIcon,
        ),
      ),
    );
  }

  Widget _buildImageArea(EditingLoaded state) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightGrey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Main image display with zoom functionality
            _buildCurrentImage(state.currentImageFile),

            // Loading overlay when generating
            if (state.generationStatus.isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentImage(File imageFile) {
    return GestureDetector(
      onLongPress: () => context.read<EditingCubit>().cropImage(),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(child: Image.file(imageFile, fit: BoxFit.contain)),
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
    return Container(
      height: 48,
      child: state.suggestionsStatus.isLoading
          ? _buildSuggestionsLoading()
          : state.suggestedPrompts.isNotEmpty
          ? ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: state.suggestedPrompts
                  .map((prompt) => _buildSuggestionChip(prompt))
                  .toList(),
            )
          : _buildSuggestionsPlaceholder(),
    );
  }

  Widget _buildSuggestionsLoading() {
    return const Center(
      child: Text(
        'Suggestions loading...',
        style: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSuggestionsPlaceholder() {
    return const Center(
      child: Text(
        'AI suggestions will appear here',
        style: TextStyle(color: AppColors.inactiveIcon, fontSize: 14),
      ),
    );
  }

  Widget _buildSuggestionChip(PromptSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _promptController.text = suggestion.prompt,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkGrey, AppColors.darkGrey.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gradientOrange.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                suggestion.title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
      ],
    );
  }

  Widget _buildPromptInputArea(EditingLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: state.generationStatus.isLoading
              ? [AppColors.darkGrey, AppColors.darkGrey.withOpacity(0.8)]
              : [AppColors.mediumGrey, AppColors.mediumGrey.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.gradientOrange.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              enabled: !state.generationStatus.isLoading,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: state.generationStatus.isLoading
                    ? 'Generating image...'
                    : 'Describe your edit...',
                hintStyle: TextStyle(
                  color: state.generationStatus.isLoading
                      ? AppColors.inactiveIcon
                      : AppColors.veryLightGrey,
                  fontSize: 16,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: state.generationStatus.isLoading
                    ? AppColors.inactiveIcon
                    : AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Additional image button
          GestureDetector(
            onTap: state.generationStatus.isLoading
                ? null
                : () => context.read<EditingCubit>().pickAdditionalImage(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: state.additionalImage != null
                    ? LinearGradient(
                        colors: [
                          AppColors.gradientOrange.withOpacity(0.3),
                          AppColors.gradientRed.withOpacity(0.2),
                        ],
                      )
                    : null,
                color: state.additionalImage == null
                    ? AppColors.mediumGrey
                    : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.additionalImage != null
                      ? AppColors.gradientOrange.withOpacity(0.5)
                      : AppColors.lightGrey,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.image_outlined,
                color: state.additionalImage != null
                    ? AppColors.gradientOrange
                    : AppColors.activeIcon,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: state.generationStatus.isLoading
                ? null
                : () {
                    if (_promptController.text.trim().isNotEmpty) {
                      context.read<EditingCubit>().generateImage(
                        _promptController.text.trim(),
                      );
                    }
                  },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: state.generationStatus.isLoading
                    ? null
                    : _promptController.text.trim().isNotEmpty
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gradientOrange,
                          AppColors.gradientRed,
                        ],
                      )
                    : null,
                color: state.generationStatus.isLoading
                    ? AppColors.inactiveIcon
                    : _promptController.text.trim().isEmpty
                    ? AppColors.lightGrey
                    : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow:
                    _promptController.text.trim().isNotEmpty &&
                        !state.generationStatus.isLoading
                    ? [
                        BoxShadow(
                          color: AppColors.gradientOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                state.generationStatus.isLoading
                    ? Icons.hourglass_empty
                    : Icons.arrow_upward_rounded,
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
