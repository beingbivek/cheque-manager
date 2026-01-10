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

  Future<List<PaymentRecord>> fetchFilteredPayments({
    DateTime? startDate,
    DateTime? endDate,
    String? provider,
    String? plan,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _repository.payments;

      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }
      final providerFilter = provider?.trim() ?? '';
      if (providerFilter.isNotEmpty) {
        query = query.where('provider', isEqualTo: providerFilter);
      }
      final planFilter = plan?.trim() ?? '';
      if (planFilter.isNotEmpty) {
        query = query.where('planGranted', isEqualTo: planFilter);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to fetch filtered payments.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'ADMIN_FILTERED_PAYMENTS',
        message: 'Unknown error while fetching filtered payments.',
        original: e,
      );
    }
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
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to create notification.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'ADMIN_NOTIFICATION_CREATE',
        message: 'Unknown error while creating notification.',
        original: e,
      );
    }
  }

  Future<void> updateLegalDoc({
    required String docId,
    required String title,
    required String content,
  }) async {
    try {
      await _repository.legalDocs.doc(docId).set(
        {
          'title': title,
          'content': content,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update legal document.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'ADMIN_LEGAL_DOC_UPDATE',
        message: 'Unknown error while updating legal document.',
        original: e,
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
