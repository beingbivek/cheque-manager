import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_error.dart';
import '../models/subscription.dart';
import 'firestore_repository.dart';

class SubscriptionService {
  SubscriptionService({FirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();

  final FirestoreRepository _repository;

  Future<void> upgradeToPro({
    required String userId,
    required int amount,
    required String khaltiToken,
    required int khaltiAmountPaisa,
  }) async {
    try {
      final now = DateTime.now();
      final expiry = now.add(const Duration(days: 30));

      final subscription = Subscription(
        id: '',
        userId: userId,
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.active,
        startAt: now,
        endAt: expiry,
        createdAt: now,
        updatedAt: now,
      );

      // 1) Log payment
      final paymentDoc = _repository.payments.doc();
      final subscriptionDoc = _repository.subscriptions.doc();
      final userDoc = _repository.users.doc(userId);

      final batch = _repository.users.firestore.batch();
      batch.set(paymentDoc, {
        'userId': userId,
        'amount': amount, // 500
        'amountPaisa': khaltiAmountPaisa,
        'provider': 'khalti',
        'token': khaltiToken,
        'planGranted': 'pro',
        'validUntil': expiry,
        'createdAt': now,
      });
      batch.set(subscriptionDoc, subscription.copyWith(id: subscriptionDoc.id).toMap());
      batch.update(userDoc, {
        'tier': 'pro',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to upgrade plan.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'UPGRADE_UNKNOWN',
        message: 'Unknown error while upgrading.',
        original: e,
      );
    }
  }
}
