import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_error.dart';
import '../models/user.dart';
import 'firestore_repository.dart';

class UserService {
  UserService({FirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();

  final FirestoreRepository _repository;

  Future<User> fetchUser(String userId) async {
    try {
      final snapshot = await _repository.users.doc(userId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw AppError(
          code: 'USER_NOT_FOUND',
          message: 'User record not found.',
        );
      }
      return User.fromMap(snapshot.id, snapshot.data()!);
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to load user profile.',
        original: e,
      );
    }
  }

  Future<void> incrementPartyCount(String userId, int delta) async {
    await _updateCounts(userId, partyDelta: delta, chequeDelta: 0);
  }

  Future<void> incrementChequeCount(String userId, int delta) async {
    await _updateCounts(userId, partyDelta: 0, chequeDelta: delta);
  }

  Future<void> _updateCounts(
    String userId, {
    required int partyDelta,
    required int chequeDelta,
  }) async {
    try {
      await _repository.users.doc(userId).update({
        if (partyDelta != 0) 'partyCount': FieldValue.increment(partyDelta),
        if (chequeDelta != 0) 'chequeCount': FieldValue.increment(chequeDelta),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update usage counts.',
        original: e,
      );
    }
  }

  Future<void> updateTier({
    required String userId,
    required String tier,
  }) async {
    try {
      await _repository.users.doc(userId).update({
        'tier': tier,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update user tier.',
        original: e,
      );
    }
  }

  Future<void> updateProfile({
    required String userId,
    required String displayName,
    required String phone,
  }) async {
    try {
      await _repository.users.doc(userId).update({
        'displayName': displayName,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update profile.',
        original: e,
      );
    }
  }

  Future<void> updateNotificationLeadDays({
    required String userId,
    required int leadDays,
  }) async {
    try {
      await _repository.users.doc(userId).update({
        'notificationLeadDays': leadDays,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to update notification settings.',
        original: e,
      );
    }
  }
}
