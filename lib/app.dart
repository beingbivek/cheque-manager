// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'routes/app_routes.dart';
import 'views/auth/splash_view.dart';
import 'views/common/error_404_view.dart';
import 'views/user/user_dashboard_view.dart';
import 'views/admin/admin_dashboard_view.dart';

class ChequeApp extends StatelessWidget {
  const ChequeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        // Add other controllers later (ChequeController, SubscriptionController, etc.)
      ],
      child: MaterialApp(
        title: 'Cheque Reminder',
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
        onUnknownRoute: (_) =>
            MaterialPageRoute(builder: (_) => const Error404View()),
      ),
    );
  }
}
