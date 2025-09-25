import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../data/repositories/firebase_service.dart';
import '../../../data/models/pack.dart';
import '../../../core/logger.dart';

part 'packs_state.dart';

class PacksCubit extends Cubit<PacksState> {
  PacksCubit(this._firebaseService) : super(const PacksState());

  final FirebaseService _firebaseService;

  /// Load all available photo packs from Firestore.
  Future<void> loadPacks() async {
    if (state.status == PacksStatus.loading) return;
    
    emit(state.copyWith(status: PacksStatus.loading));
    try {
      final packs = await _firebaseService.getPacks();
      
      // Convert all pack cover URLs to download URLs
      final packsWithDownloadUrls = <Pack>[];
      for (final pack in packs) {
        try {
          final downloadUrl = await getDownloadUrl(pack.cover);
          final updatedPack = pack.copyWith(cover: downloadUrl);
          packsWithDownloadUrls.add(updatedPack);
        } catch (e, stackTrace) {
          logger.e('Failed to get download URL for pack ${pack.name}, excluding from list', error: e, stackTrace: stackTrace);
          // Skip this pack if URL conversion fails
        }
      }
      
      emit(state.copyWith(
        status: PacksStatus.success,
        packs: packsWithDownloadUrls,
      ));
    } catch (e, stackTrace) {
      logger.e('Failed to load packs from Firestore', error: e, stackTrace: stackTrace);
      emit(state.copyWith(status: PacksStatus.failure));
    }
  }

  /// Factory method to get download URL from Firebase Storage.
  static Future<String> getDownloadUrl(String gsUrl) async {
    try {
      final storage = FirebaseStorage.instance;
      final pathRef = storage.refFromURL(gsUrl);
      return await pathRef.getDownloadURL();
    } catch (e, stackTrace) {
      logger.e('Failed to get download URL for: $gsUrl', error: e, stackTrace: stackTrace);
      throw Exception('Failed to get download URL: $e');
    }
  }
}
