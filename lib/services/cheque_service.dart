import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cheque.dart';
import '../models/app_error.dart';
import 'firestore_repository.dart';

class ChequeService {
  ChequeService({FirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();

  final FirestoreRepository _repository;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _repository.cheques;

  Future<List<Cheque>> getChequesForUser(String userId) async {
    try {
      final snapshot =
          await _collection.where('userId', isEqualTo: userId).get();
      return snapshot.docs
          .map((d) => Cheque.fromMap(d.id, d.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to load cheques.',
        original: e,
      );
    }
  }

  Future<int> countChequesForUser(String userId) async {
    final snapshot =
        await _collection.where('userId', isEqualTo: userId).get();
    return snapshot.size;
  }

  Future<Cheque> addCheque(Cheque cheque) async {
    try {
      final doc = _collection.doc();
      final data = cheque.copyWith(id: doc.id).toMap();

      final batch = _collection.firestore.batch();
      batch.set(doc, data);
      batch.update(_repository.users.doc(cheque.userId), {
        'chequeCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      final snap = await doc.get();
      return Cheque.fromMap(snap.id, snap.data()!);
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to add cheque.',
        original: e,
      );
    }
  }

  Future<void> markNotificationSent(String chequeId) async {
    try {
      await _collection.doc(chequeId).update({'notificationSent': true});
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update notification flag.',
        original: e,
      );
    }
  }

  Future<void> updateChequeStatus({
    required String chequeId,
    required ChequeStatus status,
    required DateTime updatedAt,
  }) async {
    try {
      await _collection.doc(chequeId).update({
        'status': status.name,
        'updatedAt': updatedAt,
      });
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update cheque.',
        original: e,
      );
    }
  }

  Future<void> updateChequeDetails({
    required String chequeId,
    required String partyName,
    required double amount,
    required DateTime date,
    required ChequeStatus status,
    required bool notificationSent,
    required DateTime updatedAt,
  }) async {
    try {
      await _collection.doc(chequeId).update({
        'partyName': partyName,
        'amount': amount,
        'date': date,
        'status': status.name,
        'notificationSent': notificationSent,
        'updatedAt': updatedAt,
      });
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update cheque.',
        original: e,
      );
    }
  }

  Future<void> resetNotificationsForUser(String userId) async {
    try {
      final snapshot =
          await _collection.where('userId', isEqualTo: userId).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _collection.firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'notificationSent': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to reset notification flags.',
        original: e,
      );
    }
  }
}
