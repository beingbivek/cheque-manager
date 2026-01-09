import 'package:flutter/foundation.dart';

import '../models/admin_notification.dart';
import '../models/legal_doc.dart';
import '../models/payment_record.dart';
import '../models/user.dart';
import '../services/admin_service.dart';

class AdminController extends ChangeNotifier {
  AdminController({AdminService? service}) : _service = service ?? AdminService();

  final AdminService _service;

  Stream<List<User>> streamUsers() => _service.streamUsers();

  Stream<List<PaymentRecord>> streamPayments() => _service.streamPayments();

  Stream<List<AdminNotification>> streamNotifications() =>
      _service.streamNotifications();

  Stream<List<LegalDoc>> streamLegalDocs() => _service.streamLegalDocs();

  Future<void> createNotification({
    required String title,
    required String message,
  }) =>
      _service.createNotification(title: title, message: message);

  Future<void> updateLegalDoc({
    required String docId,
    required String title,
    required String content,
  }) =>
      _service.updateLegalDoc(
        docId: docId,
        title: title,
        content: content,
      );
}
