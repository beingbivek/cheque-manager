import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_error.dart';

class KhaltiVerifyService {
  // ✅ put your Render URL here
  static const String baseUrl = 'https://khaltibackend-ffu2.onrender.com';

  Future<void> verifyAndUpgrade({
    required String token,
    required int amountPaisa,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw AppError(code: 'UNAUTHENTICATED', message: 'Please login first.');
      }

      final idToken = await user.getIdToken(true);

      final res = await http.post(
        Uri.parse('$baseUrl/verify-khalti-and-upgrade'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'token': token, 'amount': amountPaisa}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200 || data['ok'] != true) {
        throw AppError(
          code: (data['code'] ?? 'VERIFY_FAILED').toString(),
          message: (data['message'] ?? 'Verification failed.').toString(),
          original: data,
        );
      }
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        code: 'VERIFY_UNKNOWN',
        message: 'Could not verify payment.',
        original: e,
      );
    }
  }
}
