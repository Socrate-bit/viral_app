import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/cloud_ai_service.dart';
import '../../../data/models/pack.dart';
import '../../../data/models/gallery_image.dart';
import '../image_detail/image_detail_page.dart';
import 'pack_generation_cubit.dart';
import '../../../core/logger.dart';

class PackPreviewModal extends StatefulWidget {
  final Pack pack;
  final PackGenerationResult? result;

  const PackPreviewModal({
    super.key,
    required this.pack,
    this.result,
  });

  @override
  State<PackPreviewModal> createState() => _PackPreviewModalState();
}

class _PackPreviewModalState extends State<PackPreviewModal> {

  @override
  Widget build(BuildContext context) {
    return BlocListener<PackGenerationCubit, PackGenerationState>(
      listener: (context, state) {
        // Modal will automatically rebuild when state changes
      },
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildContent(),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.pack.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<PackGenerationCubit, PackGenerationState>(
      builder: (context, state) {
        if (state.status == PackGenerationStatus.loading) {
          return _buildLoadingGrid();
        } else if (state.status == PackGenerationStatus.success && state.result != null) {
          return _buildImagesGrid(state.result!);
        } else if (state.status == PackGenerationStatus.failure) {
          return _buildErrorContent(state.errorMessage);
        }
        return _buildLoadingGrid();
      },
    );
  }

  Widget _buildLoadingGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: widget.pack.prompts.length,
          itemBuilder: (context, index) {
            return _buildLoadingCard(widget.pack.prompts[index]);
          },
        ),
      ),
    );
  }

  Widget _buildImagesGrid(PackGenerationResult result) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: result.images.length,
          itemBuilder: (context, index) {
            return _buildImageCard(result.images[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildErrorContent(String? errorMessage) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Generation Failed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Close',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(String prompt) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(GeneratedImage image, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main image container
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[900],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                image.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Overlay gradient for better button visibility
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
                stops: const [0.0, 0.6, 0.8, 1.0],
              ),
            ),
          ),
          
          // Tap gesture for navigation to image detail
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToImageDetail(image),
                borderRadius: BorderRadius.circular(16),
                child: Container(), // Empty container for tap area
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToImageDetail(GeneratedImage image) async {
    try {
      // Create a GalleryImage object from the GeneratedImage using the Firebase URL
      final galleryImage = GalleryImage(
        id: 'pack_image_${image.index}',
        imageUrl: image.imageUrl, // Use Firebase Storage URL
        fileName: image.imageUrl.split('/').last,
        prompts: [image.prompt],
        createdAt: DateTime.now(),
      );
      
      // Navigate to image detail page
      if (mounted) {
        await ImageDetailPage.show(context, galleryImage);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to navigate to image detail', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open image details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }




}