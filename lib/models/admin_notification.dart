import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final DateTime? createdAt;

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  static DateTime? _toDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  factory AdminNotification.fromMap(String id, Map<String, dynamic> data) {
    return AdminNotification(
      id: id,
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      createdAt: _toDate(data['createdAt']),
    );
  }
}
