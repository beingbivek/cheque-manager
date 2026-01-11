import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../../services/navigation_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_checkAuth);
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthController>();
    final notificationService = NotificationService.instance;

    // small delay just for visual
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final pendingChequeId = await notificationService.peekPendingChequeId();
    final pendingRoute = await notificationService.peekPendingRoute();

    if (auth.isLoggedIn) {
      final user = auth.currentUser!;
      if (user.role == 'admin') {
        await notificationService.clearPendingPayload();
        await notificationService.clearPendingRoute();
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else {
        if (pendingRoute == AppRoutes.userNotifications) {
          await notificationService.consumePendingRoute();
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.userDashboard,
            (route) => false,
          );
          Navigator.pushNamed(context, AppRoutes.userNotifications);
          return;
        }
        if (pendingChequeId != null) {
          final chequeId = await notificationService.consumePendingChequeId();
          if (chequeId != null) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.userDashboard,
              (route) => false,
            );
            Navigator.pushNamed(
              context,
              AppRoutes.chequeDetails,
              arguments: chequeId,
            );
            return;
          }
        }
        Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
        _openPendingNotificationRoute();
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _openPendingNotificationRoute() {
    Future.delayed(const Duration(milliseconds: 300), () async {
      final notificationService = NotificationService.instance;
      final pendingRoute = await notificationService.consumePendingRoute();
      if (pendingRoute != null) {
        final navState = NavigationService.navigatorKey.currentState;
        navState?.pushNamed(pendingRoute);
        return;
      }
      final chequeId = await notificationService.consumePendingChequeId();
      if (chequeId != null) {
        final navState = NavigationService.navigatorKey.currentState;
        navState?.pushNamed(
          AppRoutes.chequeDetails,
          arguments: chequeId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
