import 'package:flutter/foundation.dart';
import '../models/app_error.dart';
import '../services/subscription_service.dart';

class SubscriptionController extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();

  bool _isLoading = false;
  AppError? _lastError;

  bool get isLoading => _isLoading;
  AppError? get lastError => _lastError;

  Future<void> upgradeUserToPro({
    required String userId,
    required String khaltiToken,
    required int khaltiAmountPaisa,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Rs 500/month
      await _service.upgradeToPro(
        userId: userId,
        amount: 500,
        khaltiToken: khaltiToken,
        khaltiAmountPaisa: khaltiAmountPaisa,
      );
    } on AppError catch (e) {
      _lastError = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
