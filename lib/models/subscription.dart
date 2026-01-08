import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionStatus { active, canceled, expired }

enum SubscriptionTier { free, pro }

class Subscription {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    this.updatedAt,
  });

  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Subscription.fromMap(String id, Map<String, dynamic> data) {
    return Subscription(
      id: id,
      userId: data['userId'] as String,
      tier: _tierFromString(data['tier'] as String? ?? 'free'),
      status: _statusFromString(data['status'] as String? ?? 'active'),
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tier': tier.name,
      'status': status.name,
      'startAt': startAt,
      'endAt': endAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static SubscriptionTier _tierFromString(String value) {
    switch (value) {
      case 'pro':
        return SubscriptionTier.pro;
      default:
        return SubscriptionTier.free;
    }
  }

  static SubscriptionStatus _statusFromString(String value) {
    switch (value) {
      case 'canceled':
        return SubscriptionStatus.canceled;
      case 'expired':
        return SubscriptionStatus.expired;
      default:
        return SubscriptionStatus.active;
    }
  }
}
