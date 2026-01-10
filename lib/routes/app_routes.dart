// lib/routes/app_routes.dart
import 'package:flutter/material.dart';

import '../views/auth/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/user/user_dashboard_view.dart';
import '../views/admin/admin_dashboard_view.dart';
import '../views/common/error_404_view.dart';
import '../views/user/cheque_detail_view.dart';
import '../views/user/user_settings_view.dart';
import '../views/user/terms_privacy_view.dart';
import '../views/user/user_tickets_view.dart';
import '../views/user/user_notifications_view.dart';


class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const userDashboard = '/user-dashboard';
  static const adminDashboard = '/admin-dashboard';
  static const chequeDetails = '/cheque-details';
  static const settings = '/settings';
  static const termsPrivacy = '/terms-privacy';
  static const userTickets = '/tickets';
  static const userNotifications = '/notifications';


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
      case chequeDetails:
        final chequeId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ChequeDetailView(chequeId: chequeId),
        );
      case settings:
        return MaterialPageRoute(builder: (_) => const UserSettingsView());
      case termsPrivacy:
        return MaterialPageRoute(builder: (_) => const TermsPrivacyView());
      case userTickets:
        return MaterialPageRoute(builder: (_) => const UserTicketsView());
      case userNotifications:
        return MaterialPageRoute(builder: (_) => const UserNotificationsView());
      default:
        return MaterialPageRoute(builder: (_) => const Error404View());
    }
  }
}
