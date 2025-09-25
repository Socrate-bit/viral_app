import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../navigation/home_page.dart';
import '../image_editor/editing_cubit.dart';
import '../image_gallery/gallery_cubit.dart';
import '../../../data/models/gallery_image.dart';
import 'image_detail_cubit.dart';
import 'image_detail_state.dart';

class ImageDetailPage extends StatelessWidget {
  const ImageDetailPage({super.key, required this.image});

  final GalleryImage image;

  static Future<void> show(BuildContext context, GalleryImage image) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BlocProvider(
        create: (context) => ImageDetailCubit(context.read())..initialize(),
        child: ImageDetailPage(image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ImageDetailCubit, ImageDetailState>(
      listener: (context, state) {
        if (state is ImageDetailLoaded) {
          // Handle copy status changes
          if (state.copyStatus == CopyStatus.copied) {
            _showToastMessage(
              context,
              'Prompts copied to clipboard!',
              AppColors.gradientOrange,
            );
          } else if (state.copyStatus == CopyStatus.error &&
              state.errorMessage != null) {
            _showToastMessage(
              context,
              state.errorMessage!,
              AppColors.inactiveIcon,
            );
          }
        }
      },
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 12),
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: const BoxDecoration(color: AppColors.backgroundColor),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              context.read<ImageDetailCubit>().reset();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close, color: AppColors.activeIcon),
          ),
          const Spacer(),
          const Text(
            'Image Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final String timeAgo = _formatTimeAgo(image.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview - takes available space
          if (image.imageUrl.isNotEmpty) ...[
            Expanded(flex: 3, child: _buildImagePreview()),
            const SizedBox(height: 16),
          ],

          Text(
            'Created $timeAgo',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),

          Expanded(flex: 2, child: _buildPromptSection(context)),
          const SizedBox(height: 16),

          _buildActionButtons(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
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
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(child: _buildImageWidget()),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Always use CachedNetworkImage for URLs
    return CachedNetworkImage(
      imageUrl: image.imageUrl,
      fit: BoxFit.contain,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 50),
      placeholder: (context, url) => Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.gradientOrange),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: const Center(
          child: Icon(
            Icons.broken_image,
            size: 60,
            color: AppColors.inactiveIcon,
          ),
        ),
      ),
    );
  }

  Widget _buildPromptSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Prompt used:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () =>
                  context.read<ImageDetailCubit>().copyPromptsFromImage(image),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.mediumGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          flex: 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Text(
                  image.aggregatedPrompts,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.primaryText,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Modify this image button
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.studioButtonGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                _createFromImage(context);
              },
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text(
                'Modify this image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: BlocBuilder<ImageDetailCubit, ImageDetailState>(
                builder: (context, state) {
                  final isSaved =
                      state is ImageDetailLoaded && state.saveStatus.isSaved;
                  return ElevatedButton.icon(
                    onPressed: isSaved
                        ? null
                        : () =>
                              context.read<ImageDetailCubit>().saveImage(image),
                    icon: Icon(
                      isSaved ? Icons.check : Icons.save_alt,
                      size: 18,
                      color: isSaved
                          ? AppColors.gradientOrange
                          : AppColors.primaryText,
                    ),
                    label: Text(
                      isSaved ? 'Saved' : 'Save to Photos',
                      style: TextStyle(
                        color: isSaved
                            ? AppColors.gradientOrange
                            : AppColors.primaryText,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSaved
                          ? AppColors.darkGrey.withOpacity(0.5)
                          : AppColors.darkGrey,
                      foregroundColor: isSaved
                          ? AppColors.gradientOrange
                          : AppColors.primaryText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _confirmDelete(context);
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gradientRed,
                  side: const BorderSide(color: AppColors.gradientRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _createFromImage(BuildContext context) async {
    if (image.imageUrl.isNotEmpty) {
      // Load image from URL using the global editing cubit
      await context.read<EditingCubit>().loadImageFromUrl(image.imageUrl);

      // Navigate back to home page with Editor tab (index 0) selected using fade transition
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          _createFadeRoute(const HomePage(initialTabIndex: 1)),
          (route) => false,
        );
      }
    }
  }

  // Custom fade transition route
  PageRouteBuilder _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade transition with slight scale effect for apparition
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext initialContext) {
    showDialog(
      context: initialContext,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text(
          'Are you sure you want to delete this image? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.read<GalleryCubit>().deleteImage(
                image.id,
                image.fileName,
              );
              Navigator.popUntil(initialContext, (route) => route.isFirst);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showToastMessage(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.1,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove the toast after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
