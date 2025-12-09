// lib/routes/app_routes.dart
import 'package:flutter/material.dart';

import '../views/auth/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/user/user_dashboard_view.dart';
import '../views/admin/admin_dashboard_view.dart';
import '../views/common/error_404_view.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const userDashboard = '/user-dashboard';
  static const adminDashboard = '/admin-dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashView());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginView());
      case userDashboard:
        return MaterialPageRoute(builder: (_) => const UserDashboardView());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardView());
      default:
        return MaterialPageRoute(builder: (_) => const Error404View());
    }
  }
}
