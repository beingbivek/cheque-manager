import 'package:flutter/material.dart';

import '../../models/app_error.dart';
import 'app_error_banner.dart';

class ErrorScreenView extends StatelessWidget {
  final String title;
  final String message;
  final AppError? error;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorScreenView({
    super.key,
    required this.title,
    required this.message,
    this.error,
    this.actionLabel,
    this.onAction,
  });

  void _handleFallback(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final fallbackLabel = canPop ? 'Go Back' : 'Go Home';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                AppErrorBanner(error: error!),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (actionLabel != null && onAction != null)
                    ElevatedButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  TextButton(
                    onPressed: () => _handleFallback(context),
                    child: Text(fallbackLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
