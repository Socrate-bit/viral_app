import 'package:equatable/equatable.dart';

/// Photo pack model containing prompts and cover image.
final class Pack extends Equatable {
  const Pack({
    /// Firestore document ID.
    required this.id,
    
    /// Display name of the pack.
    required this.name,
    
    /// Cover image URL for the pack.
    required this.cover,
    
    /// List of AI prompts in this pack (1-5 prompts).
    required this.prompts,
  });

  final String id;
  final String name;
  final String cover;
  final List<String> prompts;

  /// Create a copy with modified fields.
  Pack copyWith({
    String? id,
    String? name,
    String? cover,
    List<String>? prompts,
  }) {
    return Pack(
      id: id ?? this.id,
      name: name ?? this.name,
      cover: cover ?? this.cover,
      prompts: prompts ?? this.prompts,
    );
  }

  /// Deserialize from Firestore document.
  factory Pack.fromJson(String id, Map<String, dynamic> json) {
    return Pack(
      id: id,
      name: json['name'] as String,
      cover: json['cover'] as String,
      prompts: (json['prompt'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Serialize to JSON for Firestore.
  Map<String, dynamic> toJson() => {
        'name': name,
        'cover': cover,
        'prompt': prompts,
      };

  @override
  List<Object?> get props => [id, name, cover, prompts];
}
