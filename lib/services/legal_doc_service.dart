import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_error.dart';
import '../models/legal_doc.dart';
import 'firestore_repository.dart';

class LegalDocService {
  LegalDocService({FirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();

  final FirestoreRepository _repository;

  Stream<List<LegalDoc>> streamPublishedDocs() {
    return _repository.legalDocs
        .where('publishedAt', isNull: false)
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LegalDoc.fromMap(doc.id, doc.data())).toList())
        .handleError((error, stackTrace) {
          throw _wrapError(error);
        });
  }

  AppError _wrapError(Object error) {
    if (error is AppError) return error;
    if (error is FirebaseException) {
      return AppError(
        code: 'FIRESTORE_${error.code.toUpperCase()}',
        message: 'Failed to load legal documents.',
        original: error,
      );
    }
    return AppError(
      code: 'LEGAL_DOCS_UNKNOWN',
      message: 'Unknown error while loading legal documents.',
      original: error,
    );
  }
}
