import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/colors.dart';
import '../../../data/models/pack.dart';
import '../../../core/utils/utils.dart';
import '../pack_generation/pack_generation_cubit.dart';
import '../pack_generation/pack_preview_modal.dart';
import 'packs_cubit.dart';
import 'dart:io';
import '../../../core/logger.dart';

class PacksPage extends StatelessWidget {
  const PacksPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Load packs on first access
    context.read<PacksCubit>().loadPacks();
    return const PacksWidget();
  }
}

class PacksWidget extends StatefulWidget {
  const PacksWidget({super.key});

  @override
  State<PacksWidget> createState() => _PacksWidgetState();
}

class _PacksWidgetState extends State<PacksWidget> {
  bool _isModalShown = false;

  /// Generate pack - pick image and generate all prompts
  void _generatePack(BuildContext context, Pack pack) async {
    try {
      // Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Generate pack images
        await context.read<PackGenerationCubit>().generatePack(
          originalImage: imageFile,
          pack: pack,
        );
      }
    } catch (e, stackTrace) {
      logger.e(
        '📦 [Packs] Failed to generate pack',
        error: e,
        stackTrace: stackTrace,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PackGenerationCubit, PackGenerationState>(
      listener: (context, state) {
        // Show modal immediately when loading starts (if we have pack info)
        if (state.status == PackGenerationStatus.loading &&
            state.pack != null &&
            !_isModalShown) {
          _isModalShown = true;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            isDismissible: true,
            enableDrag: true,
            builder: (context) =>
                PackPreviewModal(pack: state.pack!, result: state.result),
          ).whenComplete(() {
            _isModalShown = false;
            // Clear the generation state when modal is closed
            context.read<PackGenerationCubit>().clearGeneration();
          });
        }

        // Handle failures with snackbar only if modal is not shown
        if (state.status == PackGenerationStatus.failure && !_isModalShown) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to generate pack: ${state.errorMessage ?? "Unknown error"}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<PacksCubit, PacksState>(
        builder: (context, state) {
          return switch (state.status) {
            PacksStatus.initial => const Center(
              child: Text('Loading packs...'),
            ),
            PacksStatus.loading => _buildLoading(),
            PacksStatus.success => _buildPacksGrid(state.packs),
            PacksStatus.failure => _buildError(),
          };
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return const Center(
      child: Text(
        'Failed to load packs',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildPacksGrid(List<Pack> packs) {
    if (packs.isEmpty) {
      return const Center(
        child: Text(
          'No packs available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: packs.length,
        itemBuilder: (context, index) {
          return _buildPackCard(context, packs[index]);
        },
      ),
    );
  }

  Widget _buildPackCard(BuildContext context, Pack pack) {
    return GestureDetector(
      onTap: () => _generatePack(context, pack),
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
              // Cover image or placeholder
              _buildPackCover(pack.cover),

              // Overlay content at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pack name
                      Text(
                        StringUtils.toTitleCase(pack.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Prompts count
                      Text(
                        '${pack.prompts.length} images',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackCover(String coverUrl) {
    return CachedNetworkImage(
      imageUrl: coverUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.lightGrey.withOpacity(0.2),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.lightGrey.withOpacity(0.2),
        child: const Icon(
          Icons.palette_rounded,
          size: 48,
          color: AppColors.inactiveIcon,
        ),
      ),
    );
  }
}
