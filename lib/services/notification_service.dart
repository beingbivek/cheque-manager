import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
    tz.initializeTimeZones();
    final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

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
        if (payload == null) return;

        Map<String, dynamic> data = {};
        try {
          data = jsonDecode(payload) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Failed to parse notification payload: $e');
        }
        final route = data['route'] as String?;
        final chequeId = data['chequeId'] as String?;

        debugPrint('Notification tapped payload=$payload');

        if (route == AppRoutes.chequeDetails && chequeId != null) {
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

    debugPrint('Routing to cheque details for $chequeId');

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
      payload: jsonEncode(
        {
          'route': AppRoutes.chequeDetails,
          'chequeId': cheque.id,
        },
      ),
    );
  }

  Future<void> scheduleChequeReminders({
    required Cheque cheque,
    required String partyName,
    required List<int> reminderDays,
  }) async {
    await cancelChequeReminders(chequeId: cheque.id, reminderDays: reminderDays);

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

    for (final days in reminderDays) {
      final scheduledDate = cheque.dueDate.subtract(Duration(days: days));
      if (scheduledDate.isBefore(DateTime.now())) {
        debugPrint(
          'Skipping reminder for cheque ${cheque.id} ($days days): $scheduledDate is in the past.',
        );
        continue;
      }

      final notificationId = _notificationIdFor(cheque.id, days);
      debugPrint(
        'Scheduling cheque ${cheque.id} reminder for $days days at $scheduledDate.',
      );

      await _plugin.zonedSchedule(
        notificationId,
        'Cheque due soon: $partyName',
        'Cheque ${cheque.chequeNumber} of Rs ${cheque.amount.toStringAsFixed(2)} is due in $days day(s).',
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        payload: jsonEncode(
          {
            'route': AppRoutes.chequeDetails,
            'chequeId': cheque.id,
          },
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelChequeReminders({
    required String chequeId,
    required List<int> reminderDays,
  }) async {
    for (final days in reminderDays) {
      final notificationId = _notificationIdFor(chequeId, days);
      await _plugin.cancel(notificationId);
    }
  }

  int _notificationIdFor(String chequeId, int dayOffset) {
    final base = chequeId.hashCode & 0x7fffffff;
    return base + dayOffset;
  }
}
