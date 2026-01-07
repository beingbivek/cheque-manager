import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_error.dart';

class ErrorMapper {
  static AppError toAppError(Object e, {String fallbackCode = 'UNKNOWN'}) {
    if (e is AppError) return e;

    if (e is FirebaseAuthException) {
      return AppError(
        code: 'AUTH_${e.code.toUpperCase()}',
        message: e.message ?? 'Auth error.',
        original: e,
      );
    }

    if (e is FirebaseException) {
      return AppError(
        code: 'FB_${e.code.toUpperCase()}',
        message: e.message ?? 'Firebase error.',
        original: e,
      );
    }

    return AppError(
      code: fallbackCode,
      message: 'Something went wrong.',
      original: e,
    );
  }
}
