import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cheque.dart';
import '../routes/app_routes.dart';
import 'navigation_service.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'cheque_reminders';
  static const String _channelName = 'Cheque Reminders';
  static const String _channelDescription =
      'Notifications for cheques that are due soon.';
  static const String _pendingPayloadKey = 'pending_notification_payload';

  String? _pendingChequeId;

  String? consumePendingChequeId() {
    final pending = _pendingChequeId;
    _pendingChequeId = null;
    return pending;
  }

  Future<void> init() async {
    // Android init
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // (You can add iOS/web here later if needed)
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) async {
        final payload = response.payload;
        if (payload == null) return;

        final parts = Uri.splitQueryString(payload);
        final route = parts['route'];
        final id = parts['id'];

        if (route == AppRoutes.chequeDetails && id != null) {
          _handleNotificationTap(id);
        }
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) {
        final parts = Uri.splitQueryString(payload);
        final route = parts['route'];
        final id = parts['id'];
        if (route == AppRoutes.chequeDetails && id != null) {
          _pendingChequeId = id;
        }
      }
    }

    // Android channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    final androidImpl =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(channel);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) {
        await _persistPayload(payload);
      }
    }
  }

  Future<void> _handleNotificationTap(String chequeId) async {
    final navState = NavigationService.navigatorKey.currentState;
    if (navState == null) {
      _pendingChequeId = chequeId;
      return;
    }

    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      navState.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      return;
    }

    // Ensure we're on user dashboard, then push cheque detail
    navState.pushNamedAndRemoveUntil(
      AppRoutes.userDashboard,
      (route) => route.isFirst,
    );

    navState.pushNamed(
      AppRoutes.chequeDetails,
      arguments: chequeId,
    );

    await clearPendingPayload();
  }

  Future<String?> peekPendingChequeId() async {
    final payload = await _loadPayload();
    return _payloadToChequeId(payload);
  }

  Future<String?> consumePendingChequeId() async {
    final payload = await _loadPayload();
    if (payload == null) return null;
    await clearPendingPayload();
    return _payloadToChequeId(payload);
  }

  Future<void> clearPendingPayload() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingPayloadKey);
  }

  String? _payloadToChequeId(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final query = payload.replaceFirst('route=', 'route=/');
    final parts = Uri.splitQueryString(query);
    final route = parts['route'];
    final id = parts['id'];

    if (route == AppRoutes.chequeDetails && id != null && id.isNotEmpty) {
      return id;
    }
    return null;
  }

  Future<void> _persistPayload(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPayloadKey, payload);
  }

  Future<String?> _loadPayload() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingPayloadKey);
  }

  Future<void> showChequeReminder({
    required Cheque cheque,
    required String partyName,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      priority: Priority.high,
      importance: Importance.high,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _plugin.show(
      cheque.hashCode, // id (any int)
      'Cheque due soon: $partyName',
      'Cheque of Rs ${cheque.amount.toStringAsFixed(2)} is near ${cheque.date.toLocal().toString().split(' ').first}.',
      details,
      payload: 'route=${AppRoutes.chequeDetails}&id=${cheque.id}',
    );
  }
}
