import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/party.dart';
import '../models/app_error.dart';

class PartyService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('parties');

  Future<List<Party>> getPartiesForUser(String userId) async {
    try {
      final snapshot =
      await _collection.where('userId', isEqualTo: userId).get();
      return snapshot.docs
          .map((d) => Party.fromMap(d.id, d.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to load parties.',
        original: e,
      );
    }
  }

  Future<int> countPartiesForUser(String userId) async {
    final snapshot =
    await _collection.where('userId', isEqualTo: userId).get();
    return snapshot.size;
  }

  Future<Party> createOrGetByName({
    required String userId,
    required String name,
  }) async {
    try {
      // try existing party with same name (case-insensitive-ish)
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final d = snapshot.docs.first;
        return Party.fromMap(d.id, d.data());
      }

      final doc = await _collection.add({
        'userId': userId,
        'name': name,
        'phone': null,
        'notes': null,
        'createdAt': DateTime.now(),
      });

      final newSnapshot = await doc.get();
      return Party.fromMap(newSnapshot.id, newSnapshot.data()!);
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to save party.',
        original: e,
      );
    }
  }
}
