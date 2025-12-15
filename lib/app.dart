import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/cheque_controller.dart';
import 'routes/app_routes.dart';
import 'views/auth/splash_view.dart';
import 'views/common/error_404_view.dart';
import 'services/navigation_service.dart';
import 'controllers/subscription_controller.dart';

class ChequeApp extends StatelessWidget {
  const ChequeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => SubscriptionController()),
        ChangeNotifierProxyProvider<AuthController, ChequeController>(
          create: (_) => ChequeController(),
          update: (_, auth, chequeController) {
            chequeController ??= ChequeController();
            chequeController.setUser(auth.currentUser);
            return chequeController;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Cheque Reminder',
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService
            .navigatorKey, // 👈 IMPORTANT for navigation from notifications
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
        onUnknownRoute: (_) =>
            MaterialPageRoute(builder: (_) => const Error404View()),
      ),
    );
  }
}
