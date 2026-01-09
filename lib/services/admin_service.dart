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
    try {
      return _repository.users
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => User.fromMap(doc.id, doc.data())).toList(),
          )
          .handleError((error) {
        throw _mapError(
          'ADMIN_USERS_STREAM',
          'Failed to load users.',
          error,
        );
      });
    } catch (error) {
      return Stream.error(
        _mapError('ADMIN_USERS_STREAM', 'Failed to load users.', error),
      );
    }
  }

  Stream<List<PaymentRecord>> streamPayments() {
    try {
      return _repository.payments
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
                .toList(),
          )
          .handleError((error) {
        throw _mapError(
          'ADMIN_PAYMENTS_STREAM',
          'Failed to load payments.',
          error,
        );
      });
    } catch (error) {
      return Stream.error(
        _mapError('ADMIN_PAYMENTS_STREAM', 'Failed to load payments.', error),
      );
    }
  }

  Stream<List<AdminNotification>> streamNotifications() {
    try {
      return _repository.adminNotifications
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AdminNotification.fromMap(doc.id, doc.data()))
                .toList(),
          )
          .handleError((error) {
        throw _mapError(
          'ADMIN_NOTIFICATIONS_STREAM',
          'Failed to load notifications.',
          error,
        );
      });
    } catch (error) {
      return Stream.error(
        _mapError(
          'ADMIN_NOTIFICATIONS_STREAM',
          'Failed to load notifications.',
          error,
        ),
      );
    }
  }

  Stream<List<LegalDoc>> streamLegalDocs() {
    try {
      return _repository.legalDocs
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => LegalDoc.fromMap(doc.id, doc.data()))
                .toList(),
          )
          .handleError((error) {
        throw _mapError(
          'ADMIN_LEGAL_DOCS_STREAM',
          'Failed to load legal documents.',
          error,
        );
      });
    } catch (error) {
      return Stream.error(
        _mapError(
          'ADMIN_LEGAL_DOCS_STREAM',
          'Failed to load legal documents.',
          error,
        ),
      );
    }
  }

  AppError _mapError(String code, String message, Object error) {
    if (error is AppError) return error;
    if (error is FirebaseException) {
      return AppError(
        code: 'FIRESTORE_${error.code.toUpperCase()}',
        message: message,
        original: error,
      );
    }
    return AppError(code: code, message: message, original: error);
  }
}
