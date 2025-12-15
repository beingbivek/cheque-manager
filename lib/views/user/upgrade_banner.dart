import 'package:flutter/material.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../models/app_user.dart';

class UpgradeBanner extends StatelessWidget {
  const UpgradeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final sub = context.watch<SubscriptionController>();
    final AppUser? user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();
    if (user.isPro) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Free Plan Limit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Free users can save up to 5 parties and 5 cheques.'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sub.isLoading
                    ? null
                    : () => _startKhaltiPayment(context, user),
                child: sub.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Upgrade to Pro (Rs 500 / month)'),
              ),
            ),
            if (sub.lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                '${sub.lastError!.message} (Code: ${sub.lastError!.code})',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startKhaltiPayment(BuildContext context, AppUser user) {
    final sub = context.read<SubscriptionController>();

    final config = PaymentConfig(
      amount: 500, // Khalti uses paisa -> Rs 500 = 50000
      productIdentity: 'pro_subscription_${user.uid}',
      productName: 'Cheque Manager Pro (1 Month)',
    );

    KhaltiScope.of(context).pay(
      config: config,
      preferences: const [
        PaymentPreference.khalti,
        PaymentPreference.connectIPS,
        PaymentPreference.eBanking,
        PaymentPreference.mobileBanking,
      ],
      onSuccess: (success) async {
        await sub.upgradeUserToPro(
          userId: user.uid,
          khaltiToken: success.token,
          khaltiAmountPaisa: success.amount,
        );

        // After upgrade success, auth user model may still show free until reloaded.
        // We'll refresh by forcing a sign-in state reload later; for now show snack.
        if (sub.lastError == null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upgraded to Pro successfully!')),
          );
        }

        await context.read<AuthController>().reloadUserFromFirestore();

      },
      onFailure: (fail) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${fail.message}')),
        );
      },
      onCancel: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled')),
        );
      },
    );
  }
}
