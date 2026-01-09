import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_notification.dart';
import '../models/app_error.dart';
import '../models/legal_doc.dart';
import '../models/payment_record.dart';
import '../models/user.dart';
import 'firestore_repository.dart';

class AdminService {
  AdminService({FirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();

  final FirestoreRepository _repository;

  Stream<List<User>> streamUsers() {
    return _repository.users
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromMap(doc.id, doc.data())).toList())
        .handleError((error, stackTrace) {
          throw _wrapError(
            error,
            code: 'ADMIN_USERS_STREAM',
            message: 'Failed to stream users.',
          );
        });
  }

  Stream<List<PaymentRecord>> streamPayments() {
    return _repository.payments
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
            .toList())
        .handleError((error, stackTrace) {
          throw _wrapError(
            error,
            code: 'ADMIN_PAYMENTS_STREAM',
            message: 'Failed to stream payments.',
          );
        });
  }

  Stream<List<AdminNotification>> streamNotifications() {
    return _repository.adminNotifications
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminNotification.fromMap(doc.id, doc.data()))
            .toList())
        .handleError((error, stackTrace) {
          throw _wrapError(
            error,
            code: 'ADMIN_NOTIFICATIONS_STREAM',
            message: 'Failed to stream notifications.',
          );
        });
  }

  Stream<List<LegalDoc>> streamLegalDocs() {
    return _repository.legalDocs
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LegalDoc.fromMap(doc.id, doc.data())).toList())
        .handleError((error, stackTrace) {
          throw _wrapError(
            error,
            code: 'ADMIN_LEGAL_DOCS_STREAM',
            message: 'Failed to stream legal documents.',
          );
        });
  }

  Future<void> createNotification({
    required String title,
    required String message,
  }) async {
    try {
      final doc = _repository.adminNotifications.doc();
      await doc.set({
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw _wrapError(
        error,
        code: 'ADMIN_CREATE_NOTIFICATION',
        message: 'Failed to create notification.',
      );
    }
  }

  Future<void> updateLegalDoc({
    required String docId,
    required String title,
    required String content,
  }) async {
    try {
      await _repository.legalDocs.doc(docId).update({
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw _wrapError(
        error,
        code: 'ADMIN_UPDATE_LEGAL_DOC',
        message: 'Failed to update legal document.',
      );
    }
  }

  AppError _wrapError(
    Object error, {
    required String code,
    required String message,
  }) {
    if (error is AppError) {
      return error;
    }
    if (error is FirebaseException) {
      throw AppError(
        code: 'FIRESTORE_${error.code.toUpperCase()}',
        message: message,
        original: error,
      );
    }
    return AppError(
      code: code,
      message: message,
      original: error,
    );
  }
}
