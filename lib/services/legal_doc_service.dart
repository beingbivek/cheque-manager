import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/legal_doc.dart';
import 'firestore_repository.dart';

class LegalDocService {
  LegalDocService({FirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();

  final FirestoreRepository _repository;

  Stream<LegalDoc?> streamLatestPublishedDoc(String docType) {
    return _repository.legalDocs
        .where('type', isEqualTo: docType)
        .where('publishedAt', isGreaterThan: Timestamp(0, 0))
        .orderBy('publishedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final doc = snapshot.docs.first;
      return LegalDoc.fromMap(doc.id, doc.data());
    });
  }
}
