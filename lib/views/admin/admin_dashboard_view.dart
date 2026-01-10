import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/admin_notification.dart';
import '../../models/app_error.dart';
import '../../models/legal_doc.dart';
import '../../models/user.dart';
import 'admin_legal_doc_dialog.dart';
import 'admin_notification_dialog.dart';
import 'payments_tab.dart';
import 'tickets_tab.dart';

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
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersTab(),
            PaymentsTab(),
            TicketsTab(),
            _NotificationsTab(),
            _LegalDocsTab(),
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
                doc.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(doc.updatedAt == null
                      ? 'Unknown'
                      : _formatDate(doc.updatedAt!)),
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
