// lib/routes/app_routes.dart
import 'package:flutter/material.dart';

import '../views/auth/splash_view.dart';
import '../views/auth/login_view.dart';
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
  static const parties = '/parties';
  static const profile = '/profile';


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
        final args = settings.arguments;
        if (args is! String || args.isEmpty) {
          return MaterialPageRoute(
            builder: (context) => ErrorScreenView(
              title: 'Cheque unavailable',
              message: 'Missing cheque ID. Please try again.',
              actionLabel: 'Go to Dashboard',
              onAction: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil(
                userDashboard,
                (route) => false,
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ChequeDetailView(chequeId: args),
        );
      case settings:
        return MaterialPageRoute(builder: (_) => const UserSettingsView());
      case termsPrivacy:
        return MaterialPageRoute(builder: (_) => const TermsPrivacyView());
      case userTickets:
        return MaterialPageRoute(builder: (_) => const UserTicketsView());
      case userNotifications:
        return MaterialPageRoute(builder: (_) => const UserNotificationsView());
      case parties:
        return MaterialPageRoute(builder: (_) => const PartyListView());
      case profile:
        return MaterialPageRoute(builder: (_) => const UserProfileView());
      default:
        return MaterialPageRoute(builder: (_) => const Error404View());
    }
  }
}
