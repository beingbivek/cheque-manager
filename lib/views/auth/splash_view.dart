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

    // small delay just for visual
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (auth.isLoggedIn) {
      final user = auth.currentUser!;
      if (user.role == 'admin') {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
        _openPendingChequeDetail();
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _openPendingChequeDetail() {
    Future.delayed(const Duration(milliseconds: 300), () {
      final chequeId = NotificationService.instance.consumePendingChequeId();
      if (chequeId == null) return;
      final navState = NavigationService.navigatorKey.currentState;
      navState?.pushNamed(
        AppRoutes.chequeDetails,
        arguments: chequeId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
