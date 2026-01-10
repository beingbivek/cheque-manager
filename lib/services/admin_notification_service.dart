import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_notification.dart';
import '../models/app_error.dart';
import 'firestore_repository.dart';

class AdminNotificationService {
  AdminNotificationService({FirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();

  final FirestoreRepository _repository;

  Stream<List<AdminNotification>> streamNotifications() {
    return _repository.adminNotifications
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminNotification.fromMap(doc.id, doc.data()))
            .toList())
        .handleError((error, stackTrace) {
          throw _wrapError(error);
        });
  }

  AppError _wrapError(Object error) {
    if (error is AppError) return error;
    if (error is FirebaseException) {
      return AppError(
        code: 'FIRESTORE_${error.code.toUpperCase()}',
        message: 'Failed to load notifications.',
        original: error,
      );
    }
    return AppError(
      code: 'NOTIFICATIONS_UNKNOWN',
      message: 'Unknown error while loading notifications.',
      original: error,
    );
  }
}
