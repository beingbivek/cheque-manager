// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import '../models/app_error.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // lib/services/auth_service.dart
  Future<AppUser> createOrGetUser(User firebaseUser) async {
    try {
      final doc = _db.collection('users').doc(firebaseUser.uid);
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        final newUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          role: 'user',
          plan: 'free',
          createdAt: DateTime.now(),
        );
        await doc.set(newUser.toMap());
        return newUser;
      } else {
        return AppUser.fromMap(snapshot.id, snapshot.data()!);
      }
    } on FirebaseException catch (e) {
      // Firestore-specific error -> wrap in AppError with a clear code
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',  // e.g. FIRESTORE_PERMISSION-DENIED
        message: 'Database error: ${e.message ?? 'Unable to access data.'}',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'FIRESTORE_UNKNOWN',
        message: 'Unknown database error occurred.',
        original: e,
      );
    }
  }


  Future<AppUser> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      return await createOrGetUser(user);
    } on FirebaseAuthException catch (e) {
      throw AppError(
        code: 'AUTH_REG_${e.code.toUpperCase()}',
        message: e.message ?? 'Failed to register.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'AUTH_REG_UNKNOWN',
        message: 'Unknown error while registering.',
        original: e,
      );
    }
  }

  Future<AppUser> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      return await createOrGetUser(user);
    } on FirebaseAuthException catch (e) {
      throw AppError(
        code: 'AUTH_LOGIN_${e.code.toUpperCase()}',
        message: e.message ?? 'Failed to login.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'AUTH_LOGIN_UNKNOWN',
        message: 'Unknown error while logging in.',
        original: e,
      );
    }
  }

  Future<AppUser> signInWithGoogle() async {
    try {
      // Native (Android/iOS) flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw AppError(
          code: 'AUTH_GOOGLE_CANCELLED',
          message: 'Sign-in cancelled.',
        );
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;
      return await createOrGetUser(user);
    } on FirebaseAuthException catch (e) {
      throw AppError(
        code: 'AUTH_GOOGLE_${e.code.toUpperCase()}',
        message: e.message ?? 'Google sign-in failed.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'AUTH_GOOGLE_UNKNOWN',
        message: 'Unknown error during Google sign-in.',
        original: e,
      );
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
