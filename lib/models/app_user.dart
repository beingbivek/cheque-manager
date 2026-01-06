import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String role;
  final String plan; // free/pro
  final DateTime? planExpiry;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    required this.plan,
    required this.planExpiry,
  });

  bool get isPro {
    if (plan != 'pro') return false;
    if (planExpiry == null) return true; // if you allow lifetime pro later
    return planExpiry!.isAfter(DateTime.now());
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    DateTime? expiry;
    final raw = data['planExpiry'];
    if (raw is Timestamp) expiry = raw.toDate();

    return AppUser(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      role: data['role'] ?? 'user',
      plan: data['plan'] ?? 'free',
      planExpiry: expiry,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'plan': plan,
      'planExpiry': planExpiry,
    };
  }
}
