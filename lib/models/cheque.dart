import 'package:cloud_firestore/cloud_firestore.dart';

enum ChequeStatus { valid, near, expired, cashed }

enum ChequeSettlementStatus { pending, cleared }

class Cheque {
  final String id;
  final String userId;
  final String partyId;
  final String chequeNumber;
  final double amount;
  final DateTime issueDate;
  final DateTime dueDate;
  final ChequeStatus status;
  final ChequeSettlementStatus settlementStatus;
  final bool notificationSent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Cheque({
    required this.id,
    required this.userId,
    required this.partyId,
    required this.chequeNumber,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    this.settlementStatus = ChequeSettlementStatus.pending,
    this.notificationSent = false,
    required this.createdAt,
    this.updatedAt,
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
    ChequeSettlementStatus? settlementStatus,
    bool? notificationSent,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      settlementStatus: settlementStatus ?? this.settlementStatus,
      notificationSent: notificationSent ?? this.notificationSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      settlementStatus:
          _settlementStatusFromString(data['settlementStatus'] as String? ?? 'pending'),
      notificationSent: data['notificationSent'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
      'settlementStatus': settlementStatus.name,
      'notificationSent': notificationSent,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
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

  static ChequeSettlementStatus _settlementStatusFromString(String value) {
    switch (value) {
      case 'cleared':
        return ChequeSettlementStatus.cleared;
      default:
        return ChequeSettlementStatus.pending;
    }
  }
}
