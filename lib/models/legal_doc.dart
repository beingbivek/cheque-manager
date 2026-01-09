import 'package:cloud_firestore/cloud_firestore.dart';

class LegalDoc {
  final String id;
  final String docType;
  final String title;
  final String content;
  final DateTime? updatedAt;

  LegalDoc({
    required this.id,
    required this.docType,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  static DateTime? _toDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  factory LegalDoc.fromMap(String id, Map<String, dynamic> data) {
    return LegalDoc(
      id: id,
      docType: data['type'] ?? 'document',
      title: data['title'] ?? 'Untitled',
      content: data['content'] ?? '',
      updatedAt: _toDate(data['updatedAt']),
    );
  }
}
