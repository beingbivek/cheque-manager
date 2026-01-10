import 'package:cloud_firestore/cloud_firestore.dart';

enum PartyStatus { active, archived }

class Party {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? notes;
  final PartyStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Party({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.notes,
    this.status = PartyStatus.active,
    required this.createdAt,
    this.updatedAt,
  });

  Party copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? notes,
    PartyStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Party(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Party.fromMap(String id, Map<String, dynamic> data) {
    return Party(
      id: id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      phone: data['phone'] as String?,
      notes: data['notes'] as String?,
      status: _statusFromString(data['status'] as String? ?? 'active'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'notes': notes,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static PartyStatus _statusFromString(String value) {
    switch (value) {
      case 'archived':
        return PartyStatus.archived;
      default:
        return PartyStatus.active;
    }
  }
}
