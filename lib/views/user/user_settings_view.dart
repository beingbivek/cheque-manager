import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/cheque_controller.dart';

class UserSettingsView extends StatefulWidget {
  const UserSettingsView({super.key});

  @override
  State<UserSettingsView> createState() => _UserSettingsViewState();
}

class _UserSettingsViewState extends State<UserSettingsView> {
  static const int _minDays = 1;
  static const int _maxDays = 30;

  bool _initialized = false;
  int _leadDays = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final controller = context.read<ChequeController>();
    _leadDays = controller.nearThresholdDays;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChequeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how many days in advance you want to be notified.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              '$_leadDays day${_leadDays == 1 ? '' : 's'} before',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Slider(
              min: _minDays.toDouble(),
              max: _maxDays.toDouble(),
              divisions: _maxDays - _minDays,
              label: '$_leadDays',
              value: _leadDays.toDouble().clamp(
                    _minDays.toDouble(),
                    _maxDays.toDouble(),
                  ),
              onChanged: controller.isLoading
                  ? null
                  : (value) => setState(() => _leadDays = value.round()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () async {
                        await controller.updateNotificationLeadDays(_leadDays);
                        if (!context.mounted) return;
                        if (controller.lastError == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification lead time updated.'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(controller.lastError!.message),
                            ),
                          );
                        }
                      },
                child: controller.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
