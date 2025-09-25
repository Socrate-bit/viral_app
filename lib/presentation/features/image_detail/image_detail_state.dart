import 'package:equatable/equatable.dart';

enum SaveStatus { idle, saving, saved, error }
enum CopyStatus { idle, copying, copied, error }

extension SaveStatusX on SaveStatus {
  bool get isSaving => this == SaveStatus.saving;
  bool get isSaved => this == SaveStatus.saved;
  bool get isIdle => this == SaveStatus.idle;
}

extension CopyStatusX on CopyStatus {
  bool get isCopying => this == CopyStatus.copying;
  bool get isCopied => this == CopyStatus.copied;
  bool get isIdle => this == CopyStatus.idle;
}

sealed class ImageDetailState extends Equatable {
  const ImageDetailState();

  @override
  List<Object?> get props => [];
}

final class ImageDetailInitial extends ImageDetailState {}

final class ImageDetailLoaded extends ImageDetailState {
  const ImageDetailLoaded({
    this.saveStatus = SaveStatus.idle,
    this.copyStatus = CopyStatus.idle,
    this.errorMessage,
  });

  final SaveStatus saveStatus;
  final CopyStatus copyStatus;
  final String? errorMessage;

  ImageDetailLoaded copyWith({
    SaveStatus? saveStatus,
    CopyStatus? copyStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ImageDetailLoaded(
      saveStatus: saveStatus ?? this.saveStatus,
      copyStatus: copyStatus ?? this.copyStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [saveStatus, copyStatus, errorMessage];
}
