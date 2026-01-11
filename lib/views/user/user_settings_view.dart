import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cheque_controller.dart';
import '../../models/app_error.dart';

class UserSettingsView extends StatefulWidget {
  const UserSettingsView({super.key});

  @override
  State<UserSettingsView> createState() => _UserSettingsViewState();
}

class _UserSettingsViewState extends State<UserSettingsView> {
  AppError? _error;
  bool _saving = false;
  int _leadDays = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthController>().currentUser;
    if (user != null) {
      _leadDays = user.notificationLeadDays;
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<ChequeController>().updateNotificationLeadDays(_leadDays);
      await context.read<AuthController>().reloadUserFromFirestore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved.')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = List.generate(14, (index) => index + 1);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlanSummary(),
            const SizedBox(height: 12),
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_error!.message}\nCode: ${_error!.code}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Text(
              'Cheque notification lead time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _leadDays,
              items: options
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value day${value == 1 ? '' : 's'} before'),
                      ))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _leadDays = value);
                    },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Lead time',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save settings'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/terms-privacy'),
                child: const Text('View Terms & Privacy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) return const SizedBox.shrink();
    final maxParties = user.isPro ? 50 : 5;
    final maxCheques = user.isPro ? 50 : 5;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              'Plan: ${user.isPro ? 'Pro' : 'Free'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Parties: ${user.partyCount}/$maxParties',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Cheques: ${user.chequeCount}/$maxCheques',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
