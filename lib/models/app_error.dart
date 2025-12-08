// lib/models/app_error.dart
class AppError implements Exception {
  final String code;    // e.g. AUTH_001
  final String message; // user-friendly
  final dynamic original;

  AppError({
    required this.code,
    required this.message,
    this.original,
  });

  @override
  String toString() => '$code: $message';
}
