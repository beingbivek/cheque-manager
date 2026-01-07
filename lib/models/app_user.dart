import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String role;
  final String plan; // free/pro
  final DateTime? planExpiry;
  final int partyCount;
  final int chequeCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    required this.plan,
    required this.planExpiry,
    required this.partyCount,
    required this.chequeCount,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPro {
    if (plan != 'pro') return false;
    if (planExpiry == null) return true;
    return planExpiry!.isAfter(DateTime.now());
  }

  static DateTime? _toDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      role: data['role'] ?? 'user',
      plan: data['plan'] ?? 'free',
      planExpiry: _toDate(data['planExpiry']),
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
      'plan': plan,
      'planExpiry': planExpiry == null ? null : Timestamp.fromDate(planExpiry!),
      'partyCount': partyCount,
      'chequeCount': chequeCount,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }
}
