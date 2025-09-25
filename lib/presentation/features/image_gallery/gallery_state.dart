part of 'gallery_cubit.dart';

enum LoadingStatus { initial, loading, success, failure }

final class GalleryState extends Equatable {
  const GalleryState({
    this.loadingStatus = LoadingStatus.initial,
    this.images = const [],
    this.loadingErrorMessage,
  });

  final LoadingStatus loadingStatus;
  final List<GalleryImage> images;
  final String? loadingErrorMessage;

  GalleryState copyWith({
    LoadingStatus? loadingStatus,
    List<GalleryImage>? images,
    String? loadingErrorMessage,
  }) {
    return GalleryState(
      loadingStatus: loadingStatus ?? this.loadingStatus,
      images: images ?? this.images,
      loadingErrorMessage: loadingErrorMessage ?? this.loadingErrorMessage,
    );
  }

  @override
  List<Object?> get props => [loadingStatus, images, loadingErrorMessage];
}
