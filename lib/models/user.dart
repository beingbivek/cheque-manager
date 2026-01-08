import 'package:cloud_firestore/cloud_firestore.dart';

enum UserStatus { active, suspended }

enum UserTier { free, pro }

class User {
  final String uid;
  final String email;
  final String? displayName;
  final String role;
  final UserTier tier;
  final UserStatus status;
  final int partyCount;
  final int chequeCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    required this.tier,
    required this.status,
    required this.partyCount,
    required this.chequeCount,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPro => tier == UserTier.pro;

  static DateTime? _toDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  factory User.fromMap(String id, Map<String, dynamic> data) {
    return User(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      role: data['role'] ?? 'user',
      tier: _tierFromString(data['tier'] ?? 'free'),
      status: _statusFromString(data['status'] ?? 'active'),
      partyCount: (data['partyCount'] ?? 0) as int,
      chequeCount: (data['chequeCount'] ?? 0) as int,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'tier': tier.name,
      'status': status.name,
      'partyCount': partyCount,
      'chequeCount': chequeCount,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static UserTier _tierFromString(String value) {
    switch (value) {
      case 'pro':
        return UserTier.pro;
      default:
        return UserTier.free;
    }
  }

  static UserStatus _statusFromString(String value) {
    switch (value) {
      case 'suspended':
        return UserStatus.suspended;
      default:
        return UserStatus.active;
    }
  }
}
