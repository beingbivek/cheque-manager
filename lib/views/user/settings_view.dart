import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  static const List<int> _availableDays = [1, 3, 7];
  final Set<int> _selectedDays = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthController>().currentUser;
    if (_selectedDays.isEmpty && user != null) {
      _selectedDays
          .addAll(user.reminderDays.isEmpty ? _availableDays : user.reminderDays);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final isLoading = controller.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Reminder schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how many days before the due date you want reminders.',
          ),
          const SizedBox(height: 16),
          ..._availableDays.map(
            (day) => CheckboxListTile(
              title: Text('$day day${day == 1 ? '' : 's'} before'),
              value: _selectedDays.contains(day),
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    final sortedDays = _selectedDays.toList()..sort();
                    await controller.updateReminderDays(sortedDays);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reminder settings saved.')),
                    );
                  },
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save settings'),
          ),
        ],
      ),
    );
  }
}
