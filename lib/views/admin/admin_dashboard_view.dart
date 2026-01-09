import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/admin_notification.dart';
import '../../models/app_error.dart';
import '../../models/legal_doc.dart';
import '../../models/payment_record.dart';
import '../../models/user.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final admin = context.watch<AdminController>();
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
        body: TabBarView(
          children: [
            _UsersTab(controller: admin),
            _PaymentsTab(controller: admin),
            _NotificationsTab(controller: admin),
            _LegalDocsTab(controller: admin),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
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
              trailing: Text(user.role),
            );
          },
        );
      },
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentRecord>>(
      stream: controller.streamPayments(),
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
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final payment = payments[index];
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
        if (notifications.isEmpty) {
          return const _EmptyState(message: 'No admin notifications yet.');
        }
        return ListView.separated(
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
                doc.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                doc.updatedAt == null ? 'Unknown' : _formatDate(doc.updatedAt!),
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
