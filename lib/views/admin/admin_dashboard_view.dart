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
    final admin = context.watch<AdminController>();
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
              Tab(text: 'Tickets', icon: Icon(Icons.support_agent)),
            ],
          ),
        ),
        body: TabBarView(
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

class _UsersTab extends StatefulWidget {
  const _UsersTab({required this.controller});

  final AdminController controller;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _searchQuery = '';
  UserTier? _tierFilter;
  UserStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<User>>(
      stream: widget.controller.streamUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminErrorState(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!;
        final filtered = users.where((user) {
          if (_tierFilter != null && user.tier != _tierFilter) return false;
          if (_statusFilter != null && user.status != _statusFilter) return false;
          if (_searchQuery.isEmpty) return true;
          final haystack = [
            user.displayName ?? '',
            user.email,
            user.role,
          ].join(' ').toLowerCase();
          return haystack.contains(_searchQuery);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search users',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim().toLowerCase());
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<UserTier?>(
                          value: _tierFilter,
                          decoration: const InputDecoration(
                            labelText: 'Tier',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All tiers')),
                            DropdownMenuItem(
                              value: UserTier.free,
                              child: Text('Free'),
                            ),
                            DropdownMenuItem(
                              value: UserTier.pro,
                              child: Text('Pro'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _tierFilter = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<UserStatus?>(
                          value: _statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All statuses')),
                            DropdownMenuItem(
                              value: UserStatus.active,
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: UserStatus.suspended,
                              child: Text('Suspended'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _statusFilter = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Count: ${filtered.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyState(message: 'No users found.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        return ListTile(
                          title: Text(user.displayName?.trim().isNotEmpty == true
                              ? user.displayName!
                              : user.email),
                          subtitle: Text(
                            'Tier: ${user.tier.name} · Status: ${user.status.name}\n'
                            'Parties: ${user.partyCount} · Cheques: ${user.chequeCount}',
                          ),
                          trailing: _UserActions(
                            controller: widget.controller,
                            user: user,
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

        return _TicketsBody(
          controller: controller,
          tickets: tickets,
        );
      },
    );
  }
}

class _TicketsBody extends StatefulWidget {
  const _TicketsBody({
    required this.controller,
    required this.tickets,
  });

  final AdminController controller;
  final List<Ticket> tickets;

  @override
  State<_TicketsBody> createState() => _TicketsBodyState();
}

class _TicketsBodyState extends State<_TicketsBody> {
  TicketStatus? _statusFilter;

  void _exportCsv(List<Ticket> tickets) {
    final buffer = StringBuffer()
      ..writeln('ticketId,userId,title,status,createdAt');
    for (final ticket in tickets) {
      final createdAt = ticket.createdAt == null
          ? ''
          : _formatDate(ticket.createdAt!);
      buffer.writeln(
        '${ticket.id},${ticket.userId},${ticket.title},'
        '${ticket.status.name},$createdAt',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tickets copied as CSV.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = widget.tickets
        .where((ticket) => _statusFilter == null || ticket.status == _statusFilter)
        .toList();

    final openCount =
        widget.tickets.where((t) => t.status == TicketStatus.open).length;
    final progressCount =
        widget.tickets.where((t) => t.status == TicketStatus.inProgress).length;
    final resolvedCount =
        widget.tickets.where((t) => t.status == TicketStatus.resolved).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TicketStatus?>(
                      value: _statusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Status filter',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All statuses')),
                        DropdownMenuItem(
                          value: TicketStatus.open,
                          child: Text('Open'),
                        ),
                        DropdownMenuItem(
                          value: TicketStatus.inProgress,
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: TicketStatus.resolved,
                          child: Text('Resolved'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _statusFilter = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: tickets.isEmpty ? null : () => _exportCsv(tickets),
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(label: 'Open', count: openCount),
                  _SummaryChip(label: 'In Progress', count: progressCount),
                  _SummaryChip(label: 'Resolved', count: resolvedCount),
                  _SummaryChip(label: 'Filtered', count: tickets.length),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: tickets.isEmpty
              ? const _EmptyState(message: 'No tickets match filters.')
              : ListView.separated(
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
                            await widget.controller.updateTicketStatus(
                              ticketId: ticket.id,
                              status: value,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ticket set to ${value.name}.'),
                              ),
                            );
                          } on AppError catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${e.message} (Code: ${e.code})',
                                ),
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
                ),
        ),
      ],
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

        return StreamBuilder<List<User>>(
          stream: widget.controller.streamUsers(),
          builder: (context, usersSnapshot) {
            final users = usersSnapshot.data ?? [];
            final proCount = users.where((u) => u.tier == UserTier.pro).length;
            final freeCount = users.where((u) => u.tier == UserTier.free).length;

            final providers = {
              'All',
              ...payments
                  .map((payment) => payment.provider)
                  .where((p) => p.isNotEmpty),
            }.toList();
            final plans = {
              'All',
              ...payments
                  .map((payment) => payment.planGranted)
                  .where((p) => p.isNotEmpty),
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
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Text(
                                'Payments: ${filtered.length}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Total Rs ${totalAmount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Pro users: $proCount',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Free users: $freeCount',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
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
      },
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({required this.controller});

  final AdminController controller;

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
}

class _LegalDocsTab extends StatelessWidget {
  const _LegalDocsTab({required this.controller});

  final AdminController controller;

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
    final normalized = _normalizeError(error);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ErrorBanner(error: normalized),
          const SizedBox(height: 12),
          const Text('Please try again later.'),
        ],
      ),
    );
  }

  AppError _normalizeError(Object? error) {
    if (error is AppError) return error;
    return AppError(
      code: 'ADMIN_DASHBOARD_ERROR',
      message: 'Unable to load admin data.',
      original: error,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final AppError error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${error.message}\nCode: ${error.code}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
