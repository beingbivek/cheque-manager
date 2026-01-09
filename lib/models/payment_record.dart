import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRecord {
  final String id;
  final String userId;
  final double? amount;
  final int? amountPaisa;
  final String provider;
  final String planGranted;
  final DateTime? createdAt;

  PaymentRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.amountPaisa,
    required this.provider,
    required this.planGranted,
    required this.createdAt,
  });

  static DateTime? _toDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  double get amountValue {
    if (amount != null) return amount!;
    if (amountPaisa != null) return amountPaisa! / 100.0;
    return 0;
  }

  factory PaymentRecord.fromMap(String id, Map<String, dynamic> data) {
    final rawAmount = data['amount'];
    return PaymentRecord(
      id: id,
      userId: data['userId'] ?? '',
      amount: rawAmount is num ? rawAmount.toDouble() : null,
      amountPaisa: data['amountPaisa'] is int ? data['amountPaisa'] as int : null,
      provider: data['provider'] ?? 'unknown',
      planGranted: data['planGranted'] ?? 'unknown',
      createdAt: _toDate(data['createdAt']),
    );
  }
}
