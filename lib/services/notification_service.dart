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

  Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
    final payload = launchDetails?.notificationResponse?.payload;
    if ((launchDetails?.didNotificationLaunchApp ?? false) && payload != null) {
      _pendingChequeId = _payloadToChequeId(payload);
      await _persistPayload(payload);
    }

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
  }

  Future<void> _handleNotificationTap(String chequeId) async {
    final navState = NavigationService.navigatorKey.currentState;
    if (navState == null) {
      _pendingChequeId = chequeId;
      return;
    }

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
    if (_pendingChequeId != null) return _pendingChequeId;
    final payload = await _loadPayload();
    return _payloadToChequeId(payload);
  }

  Future<String?> consumePendingChequeId() async {
    if (_pendingChequeId != null) {
      final pending = _pendingChequeId;
      _pendingChequeId = null;
      return pending;
    }
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
      cheque.hashCode,
      'Cheque due soon: $partyName',
      'Cheque of Rs ${cheque.amount.toStringAsFixed(2)} is near ${cheque.date.toLocal().toString().split(' ').first}.',
      details,
      payload: 'route=${AppRoutes.chequeDetails}&id=${cheque.id}',
    );
  }

  Future<int?> scheduleChequeReminder({
    required Cheque cheque,
    required String partyName,
    required int leadDays,
    int? notificationId,
  }) async {
    final scheduledDate = DateTime(
      cheque.date.year,
      cheque.date.month,
      cheque.date.day,
    ).subtract(Duration(days: leadDays));

    if (!scheduledDate.isAfter(DateTime.now())) {
      return null;
    }

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

    final id = notificationId ?? _generateNotificationId(cheque.id);

    await _plugin.schedule(
      id,
      'Cheque due soon: $partyName',
      'Cheque of Rs ${cheque.amount.toStringAsFixed(2)} is due on ${cheque.date.toLocal().toString().split(' ').first}.',
      scheduledDate,
      details,
      androidAllowWhileIdle: true,
      payload: 'route=${AppRoutes.chequeDetails}&id=${cheque.id}',
    );

    return id;
  }

  Future<void> cancelScheduledNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  int _generateNotificationId(String chequeId) {
    return chequeId.hashCode & 0x7fffffff;
  }
}
