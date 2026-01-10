import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus { open, pending, resolved, closed }

class Ticket {
  Ticket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.requesterEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final TicketStatus status;
  final String requesterEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
      subject: data['subject'] ?? 'Support ticket',
      description: data['description'] ?? '',
      category: data['category'] ?? 'general',
      priority: data['priority'] ?? 'normal',
      status: _statusFromString(data['status'] ?? 'open'),
      requesterEmail: data['requesterEmail'] ?? '',
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subject': subject,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status.name,
      'requesterEmail': requesterEmail,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static TicketStatus _statusFromString(String value) {
    switch (value) {
      case 'pending':
        return TicketStatus.pending;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      case 'open':
      default:
        return TicketStatus.open;
    }
  }
}
