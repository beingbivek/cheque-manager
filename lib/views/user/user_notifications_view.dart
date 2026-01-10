import 'package:flutter/material.dart';

import '../../models/admin_notification.dart';
import '../../models/app_error.dart';
import '../../services/admin_notification_service.dart';

class UserNotificationsView extends StatelessWidget {
  const UserNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<AdminNotification>>(
        stream: AdminNotificationService().streamNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
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
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeError(error);
    return Center(
      child: Text(
        '${normalized.message}\nCode: ${normalized.code}',
        textAlign: TextAlign.center,
      ),
    );
  }

  AppError _normalizeError(Object? error) {
    if (error is AppError) return error;
    return AppError(
      code: 'NOTIFICATIONS_LOAD_ERROR',
      message: 'Unable to load notifications.',
      original: error,
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
