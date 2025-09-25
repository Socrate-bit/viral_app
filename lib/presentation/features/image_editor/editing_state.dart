import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../data/models/prompt_suggestion.dart';

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

enum SuggestionsStatus { idle, loading, success, failure }

extension SuggestionsStatusX on SuggestionsStatus {
  bool get isLoading => this == SuggestionsStatus.loading;
  bool get isSuccess => this == SuggestionsStatus.success;
  bool get isIdle => this == SuggestionsStatus.idle;
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
    this.suggestionsStatus = SuggestionsStatus.idle,
    this.generationStatus = GenerationStatus.idle,
    this.exportStatus = ExportStatus.idle,
    // Image Data - actual displayed content
    required this.initialImage,
    // Versioning - version control system
    this.displayedVersion = 0,
    this.imageVersionFiles = const [],
    this.promptsHistory = const [], // Prompts for generated versions only
    // Supporting Features - additional functionality
    this.additionalImage,
    this.suggestedPrompts = const [],
  });

  final GenerationStatus generationStatus;
  final ExportStatus exportStatus;
  final SuggestionsStatus suggestionsStatus;

  final File initialImage;
  final int displayedVersion;
  final List<File> imageVersionFiles;
  final List<String> promptsHistory; // Prompts used for each generated version

  final File? additionalImage;
  final List<PromptSuggestion> suggestedPrompts;

  // Getters functions
  int get totalVersions => imageVersionFiles.length + 1;

  File get currentImageFile {
    if (displayedVersion == 0) {
      return initialImage;
    } else if (displayedVersion > 0 &&
        imageVersionFiles.length >= displayedVersion) {
      return imageVersionFiles[displayedVersion - 1];
    }
    // Fallback to initial image if version is out of bounds
    return initialImage;
  }

  String get currentVersionPrompt {
    if (promptsHistory.length > displayedVersion && promptsHistory.isNotEmpty) {
      return promptsHistory[displayedVersion];
    }
    // Fallback to empty string if version is out of bounds
    return '';
  }

  EditingLoaded copyWith({
    GenerationStatus? generationStatus,
    ExportStatus? exportStatus,
    SuggestionsStatus? suggestionsStatus,
    File? initialImage,
    int? currentVersion,
    List<File>? imageVersionFiles,
    List<String>? versionPrompts,
    File? additionalImage,
    List<PromptSuggestion>? suggestedPrompts,
    bool clearAdditionalImage = false,
  }) {
    return EditingLoaded(
      generationStatus: generationStatus ?? this.generationStatus,
      exportStatus: exportStatus ?? this.exportStatus,
      suggestionsStatus: suggestionsStatus ?? this.suggestionsStatus,
      initialImage: initialImage ?? this.initialImage,
      displayedVersion: currentVersion ?? displayedVersion,
      imageVersionFiles: imageVersionFiles ?? this.imageVersionFiles,
      promptsHistory: versionPrompts ?? this.promptsHistory,
      additionalImage: clearAdditionalImage
          ? null
          : (additionalImage ?? this.additionalImage),
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
    );
  }

  @override
  List<Object?> get props => [
    generationStatus,
    exportStatus,
    suggestionsStatus,
    initialImage,
    displayedVersion,
    imageVersionFiles,
    promptsHistory,
    additionalImage,
    suggestedPrompts,
  ];
}

final class EditingError extends EditingState {
  const EditingError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
