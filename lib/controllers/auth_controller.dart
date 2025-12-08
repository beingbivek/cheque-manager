// lib/controllers/auth_controller.dart
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/app_error.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;
  AppError? _lastError;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  AppError? get lastError => _lastError;
  bool get isLoggedIn => _currentUser != null;

  AuthController() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
      } else {
        // Refresh user from Firestore
        _currentUser = await _authService
            .createOrGetUser(firebaseUser); // could expose properly
      }
      notifyListeners();
    });
  }

  Future<void> loginWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      _lastError = null;
      _currentUser = await _authService.loginWithEmail(email, password);
    } on AppError catch (e) {
      _lastError = e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      _lastError = null;
      _currentUser = await _authService.registerWithEmail(email, password);
    } on AppError catch (e) {
      _lastError = e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithGoogle() async {
    _setLoading(true);
    try {
      _lastError = null;
      _currentUser = await _authService.signInWithGoogle();
    } on AppError catch (e) {
      _lastError = e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
