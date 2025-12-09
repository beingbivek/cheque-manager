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

  Cheque copyWith({
    String? id,
    String? userId,
    String? partyId,
    String? chequeNumber,
    double? amount,
    DateTime? issueDate,
    DateTime? dueDate,
    ChequeStatus? status,
    bool? notificationSent,
    DateTime? createdAt,
  }) {
    return Cheque(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partyId: partyId ?? this.partyId,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      amount: amount ?? this.amount,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notificationSent: notificationSent ?? this.notificationSent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Cheque.fromMap(String id, Map<String, dynamic> data) {
    return Cheque(
      id: id,
      userId: data['userId'] as String,
      partyId: data['partyId'] as String,
      chequeNumber: data['chequeNumber'] as String,
      amount: (data['amount'] as num).toDouble(),
      issueDate: (data['issueDate'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: _statusFromString(data['status'] as String? ?? 'valid'),
      notificationSent: data['notificationSent'] as bool? ?? false,
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
