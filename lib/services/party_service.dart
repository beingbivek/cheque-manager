import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/party.dart';
import '../models/app_error.dart';
import 'firestore_repository.dart';

class PartyService {
  PartyService({FirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();

  final FirestoreRepository _repository;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _repository.parties;

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

  Future<Party?> findByName({
    required String userId,
    required String name,
  }) async {
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final d = snapshot.docs.first;
      return Party.fromMap(d.id, d.data());
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to load party.',
        original: e,
      );
    }
  }

  Future<Party> createParty({
    required String userId,
    required String name,
  }) async {
    try {
      final doc = _collection.doc();
      final now = DateTime.now();
      final party = Party(
        id: doc.id,
        userId: userId,
        name: name,
        phone: null,
        notes: null,
        status: PartyStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _collection.firestore.batch();
      batch.set(doc, party.toMap());
      batch.update(_repository.users.doc(userId), {
        'partyCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

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
