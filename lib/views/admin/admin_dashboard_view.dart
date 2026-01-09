import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/admin_notification.dart';
import '../../models/legal_doc.dart';
import 'create_notification_dialog.dart';
import 'edit_legal_doc_dialog.dart';

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
            const _PlaceholderTab(message: 'User management coming soon.'),
            const _PlaceholderTab(message: 'Payments & reports coming soon.'),
            const _NotificationsTab(),
            const _LegalDocsTab(),
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

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  Future<void> _showCreateDialog(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateNotificationDialog(),
    );

    if (!context.mounted || created != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification created successfully.')),
    );
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) return 'Unknown';
    return value.toLocal().toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Notification'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AdminNotification>>(
            stream: controller.streamNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load notifications.'));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('No notifications yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final notification = items[index];
                  return ListTile(
                    title: Text(notification.title),
                    subtitle: Text(notification.message),
                    trailing: Text(
                      _formatTimestamp(notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LegalDocsTab extends StatelessWidget {
  const _LegalDocsTab();

  Future<void> _showEditDialog(BuildContext context, LegalDoc doc) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => EditLegalDocDialog(doc: doc),
    );

    if (!context.mounted || updated != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Legal document updated successfully.')),
    );
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) return 'Not updated';
    return value.toLocal().toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Terms & Privacy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<LegalDoc>>(
            stream: controller.streamLegalDocs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load legal docs.'));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('No legal documents yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final doc = items[index];
                  return ListTile(
                    title: Text(doc.title),
                    subtitle: Text(
                      '${doc.docType} · Updated ${_formatTimestamp(doc.updatedAt)}',
                    ),
                    trailing: TextButton(
                      onPressed: () => _showEditDialog(context, doc),
                      child: const Text('Edit'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
