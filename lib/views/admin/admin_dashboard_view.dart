import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/admin_notification.dart';
import '../../models/app_error.dart';
import '../../models/legal_doc.dart';
import '../../models/payment_record.dart';
import '../../models/ticket.dart';
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
      length: 5,
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
              Tab(text: 'Tickets', icon: Icon(Icons.support_agent)),
              Tab(text: 'Notifications', icon: Icon(Icons.notifications_none)),
              Tab(text: 'Terms & Privacy', icon: Icon(Icons.description_outlined)),
              Tab(text: 'Tickets', icon: Icon(Icons.support_agent)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersTab(controller: admin),
            _PaymentsTab(controller: admin),
            _NotificationsTab(controller: admin),
            _LegalDocsTab(controller: admin),
            _TicketsTab(controller: admin),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AdminController>();
    return StreamBuilder<List<User>>(
      stream: controller.streamUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminErrorState(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!;
        if (users.isEmpty) {
          return const _EmptyState(message: 'No users found.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!
                  : user.email),
              subtitle: Text(
                'Tier: ${user.tier.name} · Status: ${user.status.name}\n'
                'Parties: ${user.partyCount} · Cheques: ${user.chequeCount}',
              ),
              trailing: _UserActions(
                controller: controller,
                user: user,
              ),
            );
          },
        );
      },
    );
  }
}

class _UserActions extends StatelessWidget {
  const _UserActions({
    required this.controller,
    required this.user,
  });

  final AdminController controller;
  final User user;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_UserAction>(
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _UserAction.toggleStatus,
          child: Text(
            user.status == UserStatus.active ? 'Suspend user' : 'Activate user',
          ),
        ),
        const PopupMenuItem(
          value: _UserAction.setFree,
          child: Text('Set tier: Free'),
        ),
        const PopupMenuItem(
          value: _UserAction.setPro,
          child: Text('Set tier: Pro'),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }

  Future<void> _handleAction(BuildContext context, _UserAction action) async {
    try {
      switch (action) {
        case _UserAction.toggleStatus:
          final newStatus = user.status == UserStatus.active
              ? UserStatus.suspended
              : UserStatus.active;
          await controller.updateUserStatus(
            userId: user.uid,
            status: newStatus,
          );
          _showSuccess(
            context,
            'User status set to ${newStatus.name}.',
          );
          break;
        case _UserAction.setFree:
          await controller.updateUserTier(userId: user.uid, tier: UserTier.free);
          _showSuccess(context, 'User tier set to free.');
          break;
        case _UserAction.setPro:
          await controller.updateUserTier(userId: user.uid, tier: UserTier.pro);
          _showSuccess(context, 'User tier set to pro.');
          break;
      }
    } on AppError catch (e) {
      _showError(context, e);
    }
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${error.message} (Code: ${error.code})')),
    );
  }
}

enum _UserAction { toggleStatus, setFree, setPro }

class _TicketsTab extends StatelessWidget {
  const _TicketsTab({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ticket>>(
      stream: controller.streamTickets(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminErrorState(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final tickets = snapshot.data!;
        if (tickets.isEmpty) {
          return const _EmptyState(message: 'No tickets submitted yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return ListTile(
              title: Text(ticket.title),
              subtitle: Text(
                'User: ${ticket.userId}\n${ticket.message}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: DropdownButton<TicketStatus>(
                value: ticket.status,
                onChanged: (value) async {
                  if (value == null) return;
                  try {
                    await controller.updateTicketStatus(
                      ticketId: ticket.id,
                      status: value,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ticket set to ${value.name}.')),
                    );
                  } on AppError catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('${e.message} (Code: ${e.code})'),
                      ),
                    );
                  }
                },
                items: TicketStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.name),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab({required this.controller});

  final AdminController controller;

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

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({required this.controller});

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AdminController>();
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
}

class _LegalDocsTab extends StatelessWidget {
  const _LegalDocsTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AdminController>();
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
                'Version ${doc.version} · ${doc.publishedAt == null ? 'Draft' : 'Published'}\n'
                '${doc.content}',
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

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
