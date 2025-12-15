import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_error.dart';

class SubscriptionService {
  final _db = FirebaseFirestore.instance;

  Future<void> upgradeToPro({
    required String userId,
    required int amount,
    required String khaltiToken,
    required int khaltiAmountPaisa,
  }) async {
    try {
      final now = DateTime.now();
      final expiry = now.add(const Duration(days: 30));

      // 1) Log payment
      await _db.collection('payments').add({
        'userId': userId,
        'amount': amount, // 500
        'amountPaisa': khaltiAmountPaisa,
        'provider': 'khalti',
        'token': khaltiToken,
        'planGranted': 'pro',
        'validUntil': expiry,
        'createdAt': now,
      });

      // 2) Update user plan
      await _db.collection('users').doc(userId).update({
        'plan': 'pro',
        'planExpiry': expiry,
      });
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
