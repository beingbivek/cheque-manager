// lib/routes/app_routes.dart
import 'package:flutter/material.dart';

import '../views/auth/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/user/user_dashboard_view.dart';
import '../views/admin/admin_dashboard_view.dart';
import '../views/common/error_404_view.dart';
import '../views/common/error_screen_view.dart';
import '../views/user/cheque_detail_view.dart';
import '../views/user/user_settings_view.dart';
import '../views/user/terms_privacy_view.dart';
import '../views/user/user_tickets_view.dart';
import '../views/user/user_notifications_view.dart';
import '../views/user/party_list_view.dart';
import '../views/user/user_profile_view.dart';
import '../models/app_error.dart';


class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const userDashboard = '/user-dashboard';
  static const adminDashboard = '/admin-dashboard';
  static const chequeDetails = '/cheque-details';
  static const settings = '/settings';
  static const termsPrivacy = '/terms-privacy';
  static const userTickets = '/tickets';
  static const userNotifications = '/notifications';
  static const parties = '/parties';
  static const profile = '/profile';


  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashView());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginView());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterView());
      case AppRoutes.userDashboard:
        return MaterialPageRoute(builder: (_) => const UserDashboardView());
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardView());
      case AppRoutes.chequeDetails:
        final args = settings.arguments;
        if (args is! String || args.isEmpty) {
          final error = AppError(
            code: 'CHEQUE_ID_MISSING',
            message: 'Missing cheque ID.',
          );
          return MaterialPageRoute(
            builder: (context) => ErrorScreenView(
              title: 'Cheque unavailable',
              message: 'Missing cheque ID. Please try again.',
              error: error,
              actionLabel: 'Go to Dashboard',
              onAction: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.userDashboard,
                (route) => false,
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ChequeDetailView(chequeId: args),
        );
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const UserSettingsView());
      case AppRoutes.termsPrivacy:
        return MaterialPageRoute(builder: (_) => const TermsPrivacyView());
      case AppRoutes.userTickets:
        return MaterialPageRoute(builder: (_) => const UserTicketsView());
      case AppRoutes.userNotifications:
        return MaterialPageRoute(builder: (_) => const UserNotificationsView());
      case AppRoutes.parties:
        return MaterialPageRoute(builder: (_) => const PartyListView());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const UserProfileView());
      default:
        return MaterialPageRoute(builder: (_) => const Error404View());
    }
  }
}
