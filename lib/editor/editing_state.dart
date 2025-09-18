import 'dart:io';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';

enum ExportStatus { idle, loading, success, failure }

extension ExportStatusX on ExportStatus {
  bool get isLoading => this == ExportStatus.loading;
  bool get isSuccess => this == ExportStatus.success;
  bool get isIdle => this == ExportStatus.idle;
}

enum GenerationStatus { idle, loading, success, failure }

extension GenerationStatusX on GenerationStatus {
  bool get isLoading => this == GenerationStatus.loading;
  bool get isSuccess => this == GenerationStatus.success;
  bool get isIdle => this == GenerationStatus.idle;
}

sealed class EditingState extends Equatable {
  const EditingState();
  
  @override
  List<Object?> get props => [];
}

final class EditingInitial extends EditingState {}

final class EditingLoaded extends EditingState {
  const EditingLoaded({
    // Core Status - fundamental state indicators
    this.generationStatus = GenerationStatus.idle,
    this.exportStatus = ExportStatus.idle,
    // Image Data - actual displayed content
    this.selectedImage,
    this.currentDisplayImage,
    // Versioning - version control system
    this.totalVersions = 1,
    this.displayedVersion = 0,
    // Supporting Features - additional functionality
    this.additionalImage,
    this.suggestedPrompts = const [],
  });


  final GenerationStatus generationStatus;
  final ExportStatus exportStatus;

  final File? selectedImage;
  final Uint8List? currentDisplayImage;

  final int totalVersions;
  final int displayedVersion;

  final File? additionalImage;
  final List<String> suggestedPrompts;

  bool get hasImageContent => selectedImage != null || currentDisplayImage != null;


  EditingLoaded copyWith({
    GenerationStatus? generationStatus,
    ExportStatus? exportStatus,
    File? selectedImage,
    Uint8List? currentDisplayImage,
    int? totalVersions,
    int? currentVersion,
    File? additionalImage,
    List<String>? suggestedPrompts,
    bool clearSelectedImage = false,
    bool clearCurrentDisplayImage = false,
    bool clearAdditionalImage = false,
  }) {
    return EditingLoaded(
      generationStatus: generationStatus ?? this.generationStatus,
      exportStatus: exportStatus ?? this.exportStatus,
      selectedImage: clearSelectedImage ? null : (selectedImage ?? this.selectedImage),
      currentDisplayImage: clearCurrentDisplayImage ? null : (currentDisplayImage ?? this.currentDisplayImage),
      totalVersions: totalVersions ?? this.totalVersions,
      displayedVersion: currentVersion ?? this.displayedVersion,
      additionalImage: clearAdditionalImage ? null : (additionalImage ?? this.additionalImage),
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
    );
  }

  @override
  List<Object?> get props => [
    generationStatus,
    exportStatus,
    selectedImage,
    currentDisplayImage,
    totalVersions,
    displayedVersion,
    additionalImage,
    suggestedPrompts,
  ];
}

final class EditingError extends EditingState {
  const EditingError({
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [message];
}
