import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  Future<void> init() async {
    // Android init
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // (You can add iOS/web here later if needed)
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.startsWith('cheque:')) {
          final chequeId = payload.substring('cheque:'.length);
          _handleNotificationTap(chequeId);
        }
      },
    );

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
  }

  void _handleNotificationTap(String chequeId) {
    final navState = NavigationService.navigatorKey.currentState;
    if (navState == null) return;

    // Ensure we're on user dashboard, then push cheque detail
    navState.pushNamedAndRemoveUntil(
      AppRoutes.userDashboard,
          (route) => route.isFirst,
    );

    navState.pushNamed(
      AppRoutes.chequeDetails,
      arguments: chequeId,
    );
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
      'Cheque ${cheque.chequeNumber} of Rs ${cheque.amount.toStringAsFixed(2)} is near due date.',
      details,
      payload: 'cheque:${cheque.id}',
    );
  }
}
