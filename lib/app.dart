import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/admin_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cheque_controller.dart';
import 'routes/app_routes.dart';
import 'views/auth/splash_view.dart';
import 'views/common/error_404_view.dart';
import 'services/navigation_service.dart';
import 'controllers/subscription_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:khalti_flutter/khalti_flutter.dart';


class ChequeApp extends StatelessWidget {
  const ChequeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
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
        title: 'Cheque Manager',
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService
            .navigatorKey, // 👈 IMPORTANT for navigation from notifications
        localizationsDelegates: const [
          KhaltiLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ne'), // optional (Nepali)
        ],
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
        onUnknownRoute: (_) =>
            MaterialPageRoute(builder: (_) => const Error404View()),
      ),
    );
  }
}
