import 'package:flutter/foundation.dart';
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
  static const String _pendingRouteKey = 'pending_notification_route';

  String? _pendingChequeId;
  String? _pendingRoute;
  bool _webNotificationsSupported = true;

  Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinInit =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
      web: WebInitializationSettings(),
    );

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
        } else if (route == AppRoutes.userNotifications) {
          _handleRouteTap(route);
        }
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    if ((launchDetails?.didNotificationLaunchApp ?? false) && payload != null) {
      final route = _payloadToRoute(payload);
      if (route == AppRoutes.userNotifications) {
        _pendingRoute = route;
        await _persistRoute(route);
      } else {
        _pendingChequeId = _payloadToChequeId(payload);
        await _persistPayload(payload);
      }
    }

    if (kIsWeb) {
      final webImpl =
          _plugin.resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin>();
      if (webImpl == null) {
        _webNotificationsSupported = false;
        debugPrint(
          'Web notifications are not supported. Consider enabling Firebase Messaging for web.',
        );
      } else {
        final granted = await webImpl.requestPermission();
        _webNotificationsSupported = granted ?? false;
      }
      return;
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

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

  Future<void> clearPendingRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRouteKey);
  }

  Future<void> setPendingRoute(String route) async {
    _pendingRoute = route;
    await _persistRoute(route);
  }

  String? _payloadToChequeId(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = Uri.splitQueryString(payload);
    final route = _normalizeRoute(parts['route']);
    final id = parts['id'];

    if (route == AppRoutes.chequeDetails && id != null && id.isNotEmpty) {
      return id;
    }
    return null;
  }

  String? _payloadToRoute(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = Uri.splitQueryString(payload);
    return _normalizeRoute(parts['route']);
  }

  String? _normalizeRoute(String? route) {
    if (route == null || route.isEmpty) return null;
    return route.startsWith('/') ? route : '/$route';
  }

  Future<void> _persistPayload(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPayloadKey, payload);
  }

  Future<void> _persistRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingRouteKey, route);
  }

  Future<String?> _loadPayload() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingPayloadKey);
  }

  Future<String?> _loadRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingRouteKey);
  }

  Future<String?> peekPendingRoute() async {
    if (_pendingRoute != null) return _pendingRoute;
    return _loadRoute();
  }

  Future<String?> consumePendingRoute() async {
    if (_pendingRoute != null) {
      final pending = _pendingRoute;
      _pendingRoute = null;
      await clearPendingRoute();
      return pending;
    }
    final route = await _loadRoute();
    if (route == null) return null;
    await clearPendingRoute();
    return route;
  }

  Future<void> showChequeReminder({
    required Cheque cheque,
    required String partyName,
  }) async {
    if (kIsWeb && !_webNotificationsSupported) {
      return;
    }
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      priority: Priority.high,
      importance: Importance.high,
    );

    const DarwinNotificationDetails darwinDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

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
    if (kIsWeb && !_webNotificationsSupported) {
      return null;
    }
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

    const DarwinNotificationDetails darwinDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

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

  Future<void> showAdminNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb && !_webNotificationsSupported) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      priority: Priority.high,
      importance: Importance.high,
    );

    const DarwinNotificationDetails darwinDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: 'route=${AppRoutes.userNotifications}',
    );
  }

  int _generateNotificationId(String chequeId) {
    return chequeId.hashCode & 0x7fffffff;
  }

  Future<void> _handleRouteTap(String route) async {
    final navState = NavigationService.navigatorKey.currentState;
    if (navState == null) {
      _pendingRoute = route;
      await _persistRoute(route);
      return;
    }

    navState.pushNamedAndRemoveUntil(
      AppRoutes.userDashboard,
      (route) => route.isFirst,
    );

    navState.pushNamed(route);

    await clearPendingRoute();
  }
}
