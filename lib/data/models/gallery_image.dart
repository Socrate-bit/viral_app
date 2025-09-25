import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model representing a gallery image.
final class GalleryImage extends Equatable {
  const GalleryImage({
    /// Unique identifier for the image.
    required this.id,
    
    /// URL where the image is stored (Firebase Storage).
    required this.imageUrl,
    
    /// File name of the image in storage.
    required this.fileName,
    
    /// List of prompts used to generate this image.
    required this.prompts,
    
    /// Timestamp when the image was created.
    required this.createdAt,
  });

  final String id;
  final String imageUrl;
  final String fileName;
  final List<String> prompts;
  final DateTime createdAt;

  /// Create a copy with modified fields.
  GalleryImage copyWith({
    String? id,
    String? imageUrl,
    String? fileName,
    List<String>? prompts,
    DateTime? createdAt,
  }) {
    return GalleryImage(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      fileName: fileName ?? this.fileName,
      prompts: prompts ?? this.prompts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Deserialize from Firebase document data.
  factory GalleryImage.fromFirestore(Map<String, dynamic> data, String documentId) {
    return GalleryImage(
      id: documentId,
      imageUrl: data['imageUrl'] as String,
      fileName: data['fileName'] as String,
      prompts: List<String>.from(data['prompts'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Serialize to Firebase document data.
  Map<String, dynamic> toFirestore() => {
        'imageUrl': imageUrl,
        'fileName': fileName,
        'prompts': prompts,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Get aggregated prompts as a single string.
  String get aggregatedPrompts {
    if (prompts.isEmpty) return 'No prompt available';
    
    final cleanPrompts = prompts
        .where((prompt) => prompt.trim().isNotEmpty)
        .map((prompt) => prompt.trim().replaceAll(RegExp(r'\.+$'), ''))
        .toList();
    
    return cleanPrompts.isEmpty 
        ? 'No prompt available' 
        : '${cleanPrompts.join('. ')}.';
  }

  @override
  List<Object?> get props => [id, imageUrl, fileName, prompts, createdAt];
}
