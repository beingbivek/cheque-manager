import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../routes/app_routes.dart';
import 'navigation_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class FcmService {
  FcmService._internal();

  static final FcmService instance = FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> init() async {
    await _requestPermissions();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleMessageTap(initialMessage);
    }

    _messaging.onTokenRefresh.listen((token) async {
      final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await _saveToken(uid, token);
    });
  }

  Future<void> registerTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _saveToken(uid, token);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    await NotificationService.instance.showAdminNotification(
      title: title,
      body: body,
    );
  }

  Future<void> _handleMessageTap(RemoteMessage message) async {
    final route = message.data['route'] ?? AppRoutes.userNotifications;
    await _navigateToRoute(route);
  }

  Future<void> _navigateToRoute(String route) async {
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      await NotificationService.instance.setPendingRoute(route);
      return;
    }

    final navState = NavigationService.navigatorKey.currentState;
    if (navState == null) {
      await NotificationService.instance.setPendingRoute(route);
      return;
    }

    navState.pushNamedAndRemoveUntil(
      AppRoutes.userDashboard,
      (route) => route.isFirst,
    );
    navState.pushNamed(route);
  }

  Future<void> _saveToken(String uid, String token) async {
    final now = FieldValue.serverTimestamp();
    await _db
        .collection('users')
        .doc(uid)
        .collection('tokens')
        .doc(token)
        .set(
      {
        'token': token,
        'platform': _platformLabel(),
        'createdAt': now,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
