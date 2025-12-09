import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cheque.dart';
import '../models/app_error.dart';

class ChequeService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('cheques');

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
      final doc = await _collection.add(cheque.toMap());
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

  Future<void> updateChequeStatus({
    required String chequeId,
    required ChequeStatus status,
  }) async {
    try {
      await _collection.doc(chequeId).update({'status': status.name});
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update cheque.',
        original: e,
      );
    }
  }
}
