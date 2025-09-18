import 'package:equatable/equatable.dart';

sealed class GalleryState extends Equatable {
  const GalleryState();
  
  @override
  List<Object?> get props => [];
}

final class GalleryInitial extends GalleryState {}

final class GalleryLoading extends GalleryState {}

final class GalleryEmpty extends GalleryState {}

final class GalleryLoaded extends GalleryState {
  const GalleryLoaded({
    this.images = const [],
  });

  final List<Map<String, dynamic>> images;

  GalleryLoaded copyWith({
    List<Map<String, dynamic>>? images,
  }) {
    return GalleryLoaded(
      images: images ?? this.images,
    );
  }

  @override
  List<Object?> get props => [images];
}

final class GalleryError extends GalleryState {
  const GalleryError({
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [message];
}
