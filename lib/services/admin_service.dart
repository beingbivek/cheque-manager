import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_notification.dart';
import '../models/app_error.dart';
import '../models/legal_doc.dart';
import '../models/payment_record.dart';
import '../models/ticket.dart';
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

  Stream<List<Ticket>> streamTickets() {
    return _repository.tickets
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Ticket.fromMap(doc.id, doc.data())).toList())
        .handleError((error, stackTrace) {
          throw _wrapError(
            error,
            code: 'ADMIN_TICKETS_STREAM',
            message: 'Failed to stream tickets.',
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
    required int version,
    required DateTime? publishedAt,
  }) async {
    try {
      await _repository.legalDocs.doc(docId).set(
        {
          'title': title,
          'content': content,
          'version': version,
          'publishedAt': publishedAt,
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

  Future<void> updateUserStatus({
    required String userId,
    required UserStatus status,
  }) async {
    try {
      await _repository.users.doc(userId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update user status.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'ADMIN_USER_STATUS_UPDATE',
        message: 'Unknown error while updating user status.',
        original: e,
      );
    }
  }

  Future<void> updateUserTier({
    required String userId,
    required UserTier tier,
  }) async {
    try {
      await _repository.users.doc(userId).update({
        'tier': tier.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update user tier.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'ADMIN_USER_TIER_UPDATE',
        message: 'Unknown error while updating user tier.',
        original: e,
      );
    }
  }

  Future<void> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
  }) async {
    try {
      await _repository.tickets.doc(ticketId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update ticket status.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'ADMIN_TICKET_UPDATE',
        message: 'Unknown error while updating ticket.',
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
