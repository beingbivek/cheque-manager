// lib/models/app_user.dart
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String role;        // 'admin' or 'user'
  final String plan;        // 'free' or 'pro'
  final DateTime? planExpiry; // null for free or life-time
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    required this.plan,
    this.planExpiry,
    required this.createdAt,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      role: data['role'] ?? 'user',
      plan: data['plan'] ?? 'free',
      planExpiry: data['planExpiry'] != null
          ? (data['planExpiry'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'plan': plan,
      'planExpiry': planExpiry,
      'createdAt': createdAt,
    };
  }

  bool get isPro => plan == 'pro' && (planExpiry == null || planExpiry!.isAfter(DateTime.now()));
}
