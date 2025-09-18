import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload image to Firebase Storage and save metadata to Firestore
  Future<String> uploadImage({
    required File imageFile,
    required String prompt,
    required String userId,
    String? userDisplayName,
  }) async {
    try {
      // Create user folder name (use display name if available, otherwise userId)
      final String userFolder = _sanitizeFolderName(userDisplayName ?? userId);
      
      // Generate unique filename
      final String fileName = 'user_images/$userFolder/originals/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Firebase Storage
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Save metadata to Firestore
      final String documentId = await _saveImageMetadata(
        userId: userId,
        imageUrl: downloadUrl,
        prompt: prompt,
        fileName: fileName,
        userDisplayName: userDisplayName,
      );
      
      return documentId;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload processed image bytes to Firebase Storage
  Future<String> uploadProcessedImage({
    required Uint8List imageBytes,
    required String prompt,
    required String userId,
    String? userDisplayName,
  }) async {
    try {
      // Create user folder name (use display name if available, otherwise userId)
      final String userFolder = _sanitizeFolderName(userDisplayName ?? userId);
      
      // Generate unique filename
      final String fileName = 'user_images/$userFolder/processed/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Firebase Storage
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putData(imageBytes);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Save metadata to Firestore
      final String documentId = await _saveImageMetadata(
        userId: userId,
        imageUrl: downloadUrl,
        prompt: prompt,
        fileName: fileName,
        userDisplayName: userDisplayName,
        isProcessed: true,
      );
      
      return documentId;
    } catch (e) {
      throw Exception('Failed to upload processed image: $e');
    }
  }

  /// Save image metadata to Firestore
  Future<String> _saveImageMetadata({
    required String userId,
    required String imageUrl,
    required String prompt,
    required String fileName,
    String? userDisplayName,
    bool isProcessed = false,
  }) async {
    try {
      final DocumentReference docRef = await _firestore.collection('user_images').add({
        'userId': userId,
        'userDisplayName': userDisplayName,
        'imageUrl': imageUrl,
        'prompt': prompt,
        'fileName': fileName,
        'isProcessed': isProcessed,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save image metadata: $e');
    }
  }

  /// Get user's images from Firestore
  Future<List<Map<String, dynamic>>> getUserImages(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('user_images')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user images: $e');
    }
  }

  /// Delete image from Storage and Firestore
  Future<void> deleteImage(String documentId, String fileName) async {
    try {
      // Delete from Storage
      await _storage.ref().child(fileName).delete();
      
      // Delete from Firestore
      await _firestore.collection('user_images').doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Update image metadata
  Future<void> updateImageMetadata({
    required String documentId,
    Map<String, dynamic>? updates,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        ...?updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('user_images').doc(documentId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update image metadata: $e');
    }
  }

  /// Download image bytes from Firebase Storage
  Future<Uint8List> downloadImageBytes(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      const maxSize = 10 * 1024 * 1024; // 10MB max
      final data = await ref.getData(maxSize);
      if (data == null) {
        throw Exception('Failed to download image: No data received');
      }
      return data;
    } catch (e) {
      throw Exception('Failed to download image: $e');
    }
  }

  /// Sanitize folder name to be Firebase Storage compatible
  String _sanitizeFolderName(String name) {
    // Remove or replace invalid characters for Firebase Storage paths
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special characters except spaces and hyphens
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .toLowerCase()
        .trim();
  }
}

