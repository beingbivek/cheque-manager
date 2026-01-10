import 'package:cloud_firestore/cloud_firestore.dart';

class LegalDoc {
  final String id;
  final String docType;
  final String title;
  final String content;
  final int version;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  LegalDoc({
    required this.id,
    required this.docType,
    required this.title,
    required this.content,
    required this.version,
    required this.publishedAt,
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
      version: (data['version'] ?? 1) as int,
      publishedAt: _toDate(data['publishedAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }
}
