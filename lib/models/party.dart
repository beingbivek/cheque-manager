// lib/models/party.dart
class Party {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? notes;
  final DateTime createdAt;

  Party({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.notes,
    required this.createdAt,
  });

  factory Party.fromMap(String id, Map<String, dynamic> data) {
    return Party(
      id: id,
      userId: data['userId'],
      name: data['name'],
      phone: data['phone'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'notes': notes,
      'createdAt': createdAt,
    };
  }
}
