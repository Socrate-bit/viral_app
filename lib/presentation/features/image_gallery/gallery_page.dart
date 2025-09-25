import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'gallery_cubit.dart';
import '../image_editor/editing_cubit.dart';
import '../image_editor/editing_state.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/widgets.dart';
import '../../../data/models/gallery_image.dart';
import '../image_detail/image_detail_page.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  void initState() {
    super.initState();
    // Load user images when the gallery page is opened
    context.read<GalleryCubit>().loadUserImages();
  }

  void _showPictureDetails(GalleryImage image) {
    ImageDetailPage.show(context, image);
  }


  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to GalleryCubit for gallery-specific events
        BlocListener<GalleryCubit, GalleryState>(
          listener: (context, state) {
            // Show snackbar for loading errors
            if (state.loadingStatus == LoadingStatus.failure &&
                state.loadingErrorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.loadingErrorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        // Listen to EditingCubit for successful exports
        BlocListener<EditingCubit, EditingState>(
          listener: (context, editingState) {
            if (editingState is EditingLoaded &&
                editingState.exportStatus == ExportStatus.success) {
              // Reload gallery when user exports an image from editing page
              context.read<GalleryCubit>().loadUserImages();
            }
          },
        ),
      ],
      child: BlocBuilder<GalleryCubit, GalleryState>(
        builder: (context, state) {
          // Handle loading states
          if (state.loadingStatus == LoadingStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.loadingStatus == LoadingStatus.failure ||
              state.loadingErrorMessage != null) {
            return AppErrorWidget(
              message: state.loadingErrorMessage!,
              onRetry: () => context.read<GalleryCubit>().loadUserImages(),
              retryButtonText: 'Reload Gallery',
              title: 'Failed to load gallery',
            );
          } else if (state.loadingStatus == LoadingStatus.success &&
              state.images.isEmpty) {
            return _buildEmptyState();
          } else if (state.loadingStatus == LoadingStatus.success &&
              state.images.isNotEmpty) {
            return _buildGalleryGrid(state.images);
          }
          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No creations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start editing photos to see them here',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(List<GalleryImage> images) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return _buildGalleryItem(image);
        },
      ),
    );
  }

  Widget _buildGalleryItem(GalleryImage image) {
    return GestureDetector(
      onTap: () => _showPictureDetails(image),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.mediumGrey,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.mediumGrey,
              AppColors.lightGrey.withOpacity(0.3),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Main image
              image.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: image.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 150),
                      fadeOutDuration: const Duration(milliseconds: 50),
            
                      placeholder: (context, url) => Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: AppColors.lightGrey.withOpacity(0.2),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: AppColors.lightGrey.withOpacity(0.2),
                        child: const Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: AppColors.inactiveIcon,
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppColors.lightGrey.withOpacity(0.2),
                      child: const Icon(
                        Icons.image_rounded,
                        size: 48,
                        color: AppColors.inactiveIcon,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
