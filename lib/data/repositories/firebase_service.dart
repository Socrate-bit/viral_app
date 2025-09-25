import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pack.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload image bytes to Firebase Storage
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required List<String> prompts,
    required String userId,
  }) async {
    try {
      // Generate unique filename using userId
      final String fileName = 'user_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
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
        prompts: prompts,
        fileName: fileName,
      );
      
      return documentId;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Save image metadata to Firestore
  Future<String> _saveImageMetadata({
    required String userId,
    required String imageUrl,
    required List<String> prompts,
    required String fileName,
  }) async {
    try {
      // Filter out empty prompts
      final validPrompts = prompts.where((p) => p.trim().isNotEmpty).toList();
      
      // Build document data
      final Map<String, dynamic> documentData = {
        'userId': userId,
        'imageUrl': imageUrl,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Only add prompts field if there are valid prompts
      if (validPrompts.isNotEmpty) {
        documentData['prompts'] = validPrompts;
      }
      
      final DocumentReference docRef = await _firestore.collection('user_images').add(documentData);
      
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

  /// Download image from Firebase Storage URL and save to temporary file
  Future<File> downloadImageToFile(String imageUrl) async {
    try {
      // Use Firebase Storage's built-in download method
      final ref = _storage.refFromURL(imageUrl);
      final data = await ref.getData();
      
      if (data == null) {
        throw Exception('Failed to download image: No data received');
      }
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'downloaded_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(data);
      
      return tempFile;
    } catch (e) {
      throw Exception('Failed to download image: $e');
    }
  }

  /// Stream user's complete token and subscription info
  Stream<Map<String, dynamic>> getUserTokenInfoStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value({
        'balance': 0,
        'subscriptionStatus': 'none',
        'subscriptionProductId': null,
        'lastUpdated': null,
        'role': 'normal',
      });
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return {
          'balance': 0,
          'subscriptionStatus': 'none',
          'subscriptionProductId': null,
          'lastUpdated': null,
          'role': 'normal',
        };
      }
      
      final data = snapshot.data() as Map<String, dynamic>;
      return {
        'balance': data['balance'] ?? 0,
        'subscriptionStatus': data['subscriptionStatus'] ?? 'none',
        'subscriptionProductId': data['subscriptionProductId'],
        'lastUpdated': data['lastUpdated'],
        'role': data['role'] ?? 'normal',
      };
    });
  }

  /// Get all photo packs from Firestore.
  Future<List<Pack>> getPacks() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('packs')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Pack.fromJson(doc.id, data);
      }).toList();
    } catch (e) {
      print('❌ Failed to get packs: $e');
      throw Exception('Failed to get packs: $e');
    }
  }
}

