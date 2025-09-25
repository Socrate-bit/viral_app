import 'package:equatable/equatable.dart';

class PromptSuggestion extends Equatable {
  const PromptSuggestion({
    required this.title,
    required this.prompt,
  });

  /// Short title for display on chips (3-8 words)
  final String title;
  
  /// Full detailed prompt for text field
  final String prompt;

  factory PromptSuggestion.fromJson(Map<String, dynamic> json) {
    return PromptSuggestion(
      title: json['title'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'prompt': prompt,
    };
  }

  @override
  List<Object?> get props => [title, prompt];
}
