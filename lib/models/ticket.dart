import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus { open, inProgress, resolved }

class Ticket {
  final String id;
  final String userId;
  final String title;
  final String message;
  final TicketStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Ticket({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _toDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  factory Ticket.fromMap(String id, Map<String, dynamic> data) {
    return Ticket(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Untitled',
      message: data['message'] ?? '',
      status: _statusFromString(data['status'] ?? 'open'),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  static TicketStatus _statusFromString(String value) {
    switch (value) {
      case 'inProgress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      default:
        return TicketStatus.open;
    }
  }
}
