// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import '../models/app_error.dart';
import 'firestore_repository.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirestoreRepository _repository = FirestoreRepository();

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // lib/services/auth_service.dart
  Future<User> createOrGetUser(firebase_auth.User firebaseUser) async {
    try {
      final doc = _repository.users.doc(firebaseUser.uid);
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        final now = DateTime.now();
        final newUser = User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          phone: firebaseUser.phoneNumber,
          role: 'user',
          tier: UserTier.free,
          status: UserStatus.active,
          partyCount: 0,
          chequeCount: 0,
          notificationLeadDays: 3,
          createdAt: now,
          updatedAt: now,
        );
        await doc.set(newUser.toMap());
        return newUser;
      } else {
        return User.fromMap(snapshot.id, snapshot.data()!);
      }
    } on FirebaseException catch (e) {
      // Firestore-specific error -> wrap in AppError with a clear code
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}', // e.g. FIRESTORE_PERMISSION-DENIED
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

  Future<User> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      return await createOrGetUser(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
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

  Future<User> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      return await createOrGetUser(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
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

  Future<User> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = firebase_auth.GoogleAuthProvider();
        final result =
            await firebase_auth.FirebaseAuth.instance.signInWithPopup(provider);
        final user = result.user;
        if (user == null) {
          throw AppError(
            code: 'AUTH_GOOGLE_NO_USER',
            message: 'Google sign-in failed to return a user.',
          );
        }
        return await createOrGetUser(user);
      }

      // Native (Android/iOS) flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw AppError(
          code: 'AUTH_GOOGLE_CANCELLED',
          message: 'Sign-in cancelled.',
        );
      }

      final googleAuth = await googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;
      return await createOrGetUser(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
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
