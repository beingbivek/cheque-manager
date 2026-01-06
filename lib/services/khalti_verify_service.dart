import 'package:cloud_functions/cloud_functions.dart';
import '../models/app_error.dart';

class KhaltiVerifyService {
  Future<void> verifyAndUpgrade({
    required String token,
    required int amountPaisa,
  }) async {
    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable('verifyKhaltiAndUpgrade');

      final res = await callable.call({
        'token': token,
        'amount': amountPaisa,
      });

      final data = res.data;
      if (data == null || data['ok'] != true) {
        throw AppError(
          code: 'KHALTI_VERIFY_FAILED',
          message: 'Payment verification failed.',
          original: data,
        );
      }
    } on FirebaseFunctionsException catch (e) {
      throw AppError(
        code: 'FN_${e.code.toUpperCase()}',
        message: e.message ?? 'Server verification failed.',
        original: e,
      );
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        code: 'KHALTI_VERIFY_UNKNOWN',
        message: 'Unknown error during verification.',
        original: e,
      );
    }
  }
}
