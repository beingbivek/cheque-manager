import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get parties => _db.collection('parties');
  CollectionReference<Map<String, dynamic>> get cheques => _db.collection('cheques');
  CollectionReference<Map<String, dynamic>> get subscriptions => _db.collection('subscriptions');
  CollectionReference<Map<String, dynamic>> get payments => _db.collection('payments');
  CollectionReference<Map<String, dynamic>> get adminNotifications =>
      _db.collection('admin_notifications');
  CollectionReference<Map<String, dynamic>> get legalDocs =>
      _db.collection('legal_docs');
}
