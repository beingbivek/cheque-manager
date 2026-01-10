import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/admin_notification.dart';
import '../../models/legal_doc.dart';
import '../../models/payment_record.dart';
import '../../models/user.dart';
import 'admin_legal_doc_dialog.dart';
import 'admin_notification_dialog.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            user?.email == null
                ? 'Admin Dashboard'
                : 'Admin Dashboard · ${user!.email}',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users', icon: Icon(Icons.people_outline)),
              Tab(text: 'Payments/Reports', icon: Icon(Icons.receipt_long)),
              Tab(text: 'Notifications', icon: Icon(Icons.notifications_none)),
              Tab(text: 'Terms & Privacy', icon: Icon(Icons.description_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PlaceholderTab(message: 'User management coming soon.'),
            PaymentsTab(),
            _NotificationsTab(),
            _LegalDocsTab(),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab({required this.controller});

  String _formatTimestamp(DateTime? value) {
    if (value == null) return 'Unknown';
    return value.toLocal().toString().split('.').first;
  }

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _providerFilter = 'All';
  String _planFilter = 'All';

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted || picked == null) return;
    setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted || picked == null) return;
    setState(() => _endDate = picked);
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _providerFilter = 'All';
      _planFilter = 'All';
    });
  }

  void _exportCsv(List<PaymentRecord> payments) {
    final buffer = StringBuffer()
      ..writeln('userId,amount,provider,planGranted,createdAt');
    for (final payment in payments) {
      final createdAt = payment.createdAt == null
          ? ''
          : _formatDate(payment.createdAt!);
      buffer.writeln(
        '${payment.userId},${payment.amountValue.toStringAsFixed(2)},'
        '${payment.provider},${payment.planGranted},$createdAt',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied as CSV.')),
    );
  }

  List<PaymentRecord> _applyFilters(
    List<PaymentRecord> payments, {
    required String providerFilter,
    required String planFilter,
  }) {
    return payments.where((payment) {
      if (providerFilter != 'All' && payment.provider != providerFilter) {
        return false;
      }
      if (planFilter != 'All' && payment.planGranted != planFilter) {
        return false;
      }
      if (_startDate != null || _endDate != null) {
        if (payment.createdAt == null) return false;
        final created = payment.createdAt!;
        if (_startDate != null && created.isBefore(_startDate!)) return false;
        if (_endDate != null) {
          final endOfDay = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            23,
            59,
            59,
          );
          if (created.isAfter(endOfDay)) return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentRecord>>(
      stream: widget.controller.streamPayments(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminErrorState(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final payments = snapshot.data!;
        if (payments.isEmpty) {
          return const _EmptyState(message: 'No payments recorded yet.');
        }

        final providers = {
          'All',
          ...payments.map((payment) => payment.provider).where((p) => p.isNotEmpty),
        }.toList();
        final plans = {
          'All',
          ...payments.map((payment) => payment.planGranted).where((p) => p.isNotEmpty),
        }.toList();

        final providerValue =
            providers.contains(_providerFilter) ? _providerFilter : 'All';
        final planValue = plans.contains(_planFilter) ? _planFilter : 'All';
        if (providerValue != _providerFilter) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _providerFilter = providerValue);
          });
        }
        if (planValue != _planFilter) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _planFilter = planValue);
          });
        }

        final filtered = _applyFilters(
          payments,
          providerFilter: providerValue,
          planFilter: planValue,
        );
        final totalAmount = filtered.fold<double>(
          0,
          (sum, payment) => sum + payment.amountValue,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickStartDate,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _startDate == null
                              ? 'Start date'
                              : _formatDate(_startDate!),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickEndDate,
                        icon: const Icon(Icons.event),
                        label: Text(
                          _endDate == null ? 'End date' : _formatDate(_endDate!),
                        ),
                      ),
                      DropdownButton<String>(
                        value: providerValue,
                        items: providers
                            .map((provider) => DropdownMenuItem(
                                  value: provider,
                                  child: Text('Provider: $provider'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _providerFilter = value);
                        },
                      ),
                      DropdownButton<String>(
                        value: planValue,
                        items: plans
                            .map((plan) => DropdownMenuItem(
                                  value: plan,
                                  child: Text('Plan: $plan'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _planFilter = value);
                        },
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total payments: ${filtered.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            'Total Rs ${totalAmount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: filtered.isEmpty
                                ? null
                                : () => _exportCsv(filtered),
                            icon: const Icon(Icons.download),
                            label: const Text('Export CSV'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyState(message: 'No payments match filters.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final payment = filtered[index];
                        return ListTile(
                          title: Text(
                            'Rs ${payment.amountValue.toStringAsFixed(2)} · ${payment.provider}',
                          ),
                          subtitle: Text(
                            'User: ${payment.userId}\nPlan: ${payment.planGranted}',
                          ),
                          trailing: Text(
                            payment.createdAt == null
                                ? 'Unknown'
                                : _formatDate(payment.createdAt!),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LegalDocsTab extends StatelessWidget {
  const _LegalDocsTab();

  Future<void> _showEditDialog(BuildContext context, LegalDoc doc) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => AdminLegalDocDialog(doc: doc),
    );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminNotification>>(
      stream: controller.streamNotifications(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminErrorState(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog<bool>(
                      context: context,
                      builder: (_) => const AdminNotificationDialog(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Notification'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: notifications.isEmpty
                  ? const _EmptyState(message: 'No admin notifications yet.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return ListTile(
                          title: Text(notification.title),
                          subtitle: Text(notification.message),
                          trailing: Text(
                            notification.createdAt == null
                                ? 'Unknown'
                                : _formatDate(notification.createdAt!),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) return 'Not updated';
    return value.toLocal().toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LegalDoc>>(
      stream: controller.streamLegalDocs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminErrorState(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!;
        if (docs.isEmpty) {
          return const _EmptyState(message: 'No legal documents found.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final doc = docs[index];
            return ListTile(
              title: Text('${doc.docType.toUpperCase()} · ${doc.title}'),
              subtitle: Text(
                doc.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    doc.updatedAt == null ? 'Unknown' : _formatDate(doc.updatedAt!),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      await showDialog<bool>(
                        context: context,
                        builder: (_) => AdminLegalDocDialog(doc: doc),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        error == null ? 'Something went wrong.' : 'Error: $error',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
