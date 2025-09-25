import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../../data/repositories/cloud_ai_service.dart';
import '../../../data/models/pack.dart';
import '../usage/token_cubit.dart';
import '../image_gallery/gallery_cubit.dart';
import '../../../core/utils/logger.dart';

part 'pack_generation_state.dart';

class PackGenerationCubit extends Cubit<PackGenerationState> {
  PackGenerationCubit(this._aiService, this._tokenCubit, this._galleryCubit)
    : super(const PackGenerationState());

  final CloudAIService _aiService;
  final TokenCubit _tokenCubit;
  final GalleryCubit _galleryCubit;

  /// Generate all images from a pack
  Future<void> generatePack({
    required File originalImage,
    required Pack pack,
  }) async {
    if (state.status == PackGenerationStatus.loading) return;

    // Check if user has enough tokens
    final tokensNeeded = pack.prompts.length;
    if (!_tokenCubit.hasEnoughTokens(requiredTokens: tokensNeeded)) {
      // Show conditional paywall and exit early
      await _tokenCubit.showConditionalPaywall();
      return;
    }

    emit(state.copyWith(status: PackGenerationStatus.loading, pack: pack));

    try {
      final result = await _aiService.generatePackImages(
        originalImage: originalImage,
        packId: pack.id,
      );

      if (result != null) {
        // Images are now automatically saved by the backend
        // Just reload the gallery to show the new images
        await _galleryCubit.loadUserImages();

        emit(
          state.copyWith(
            status: PackGenerationStatus.success,
            result: result,
            pack: pack,
          ),
        );
      } else {
        emit(state.copyWith(status: PackGenerationStatus.failure));
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to generate pack images',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is InsufficientTokensException) {
        logger.w(
          'Insufficient tokens for pack generation: ${e.currentBalance}/${e.required}',
        );
        // Show conditional paywall for token-related errors
        await _tokenCubit.showConditionalPaywall();
        emit(
          state.copyWith(
            status: PackGenerationStatus.failure,
            errorMessage:
                'Insufficient tokens. Please purchase more tokens to continue.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: PackGenerationStatus.failure,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  /// Clear generated images and reset state
  void clearGeneration() {
    emit(const PackGenerationState());
  }
}
