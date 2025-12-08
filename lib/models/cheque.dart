// lib/models/cheque.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ChequeStatus { valid, near, expired, cashed }

class Cheque {
  final String id;
  final String userId;
  final String partyId;
  final String chequeNumber;
  final double amount;
  final DateTime issueDate;
  final DateTime dueDate;
  final ChequeStatus status;
  final bool notificationSent;
  final DateTime createdAt;

  Cheque({
    required this.id,
    required this.userId,
    required this.partyId,
    required this.chequeNumber,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    this.notificationSent = false,
    required this.createdAt,
  });

  factory Cheque.fromMap(String id, Map<String, dynamic> data) {
    return Cheque(
      id: id,
      userId: data['userId'],
      partyId: data['partyId'],
      chequeNumber: data['chequeNumber'],
      amount: (data['amount'] as num).toDouble(),
      issueDate: (data['issueDate'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: _statusFromString(data['status'] ?? 'valid'),
      notificationSent: data['notificationSent'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'partyId': partyId,
      'chequeNumber': chequeNumber,
      'amount': amount,
      'issueDate': issueDate,
      'dueDate': dueDate,
      'status': status.name,
      'notificationSent': notificationSent,
      'createdAt': createdAt,
    };
  }

  static ChequeStatus _statusFromString(String value) {
    switch (value) {
      case 'near':
        return ChequeStatus.near;
      case 'expired':
        return ChequeStatus.expired;
      case 'cashed':
        return ChequeStatus.cashed;
      default:
        return ChequeStatus.valid;
    }
  }
}
