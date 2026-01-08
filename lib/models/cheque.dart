import 'package:cloud_firestore/cloud_firestore.dart';

enum ChequeStatus { valid, near, expired, cashed }

class Cheque {
  final String id;
  final String userId;
  final String partyId;
  final String partyName;
  final String chequeNumber;
  final double amount;
  final DateTime date;
  final ChequeStatus status;
  final bool notificationSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cheque({
    required this.id,
    required this.userId,
    required this.partyId,
    required this.partyName,
    required this.chequeNumber,
    required this.amount,
    required this.date,
    required this.status,
    this.notificationSent = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Cheque copyWith({
    String? id,
    String? userId,
    String? partyId,
    String? partyName,
    String? chequeNumber,
    double? amount,
    DateTime? date,
    ChequeStatus? status,
    bool? notificationSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cheque(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      notificationSent: notificationSent ?? this.notificationSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Cheque.fromMap(String id, Map<String, dynamic> data) {
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final date = data['date'] as Timestamp? ??
        data['dueDate'] as Timestamp? ??
        data['issueDate'] as Timestamp?;

    return Cheque(
      id: id,
      userId: data['userId'] as String,
      partyId: data['partyId'] as String,
      partyName: data['partyName'] as String? ?? '',
      chequeNumber: data['chequeNumber'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: (date ?? Timestamp.fromDate(createdAt)).toDate(),
      status: _statusFromString(data['status'] as String? ?? 'valid'),
      notificationSent: data['notificationSent'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'partyId': partyId,
      'partyName': partyName,
      'chequeNumber': chequeNumber,
      'amount': amount,
      'date': date,
      'status': status.name,
      'notificationSent': notificationSent,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool isNear({
    required int thresholdDays,
    DateTime? referenceDate,
  }) {
    if (status == ChequeStatus.cashed) return false;
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final chequeDate = DateTime(date.year, date.month, date.day);
    if (chequeDate.isBefore(today)) return false;

    final diff = chequeDate.difference(today).inDays;
    return diff <= thresholdDays;
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
