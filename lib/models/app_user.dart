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
  final List<int> reminderDays;
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
    required this.reminderDays,
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

  static List<int> _toReminderDays(dynamic raw) {
    if (raw is List) {
      return raw
          .map((value) => int.tryParse(value.toString()))
          .whereType<int>()
          .toList();
    }
    return [1, 3, 7];
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
      reminderDays: _toReminderDays(data['reminderDays']),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? plan,
    DateTime? planExpiry,
    int? partyCount,
    int? chequeCount,
    List<int>? reminderDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      plan: plan ?? this.plan,
      planExpiry: planExpiry ?? this.planExpiry,
      partyCount: partyCount ?? this.partyCount,
      chequeCount: chequeCount ?? this.chequeCount,
      reminderDays: reminderDays ?? this.reminderDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'reminderDays': reminderDays,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }
}
