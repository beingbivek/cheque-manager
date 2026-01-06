import 'package:cheque_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.instance.init();

  runApp(
    KhaltiScope(
      publicKey: AppConstants.khaltiPublicKey,
      builder: (context, navKey) {
        NavigationService.setNavigatorKey(navKey);

        return const ChequeApp();
      },
    ),
  );
}
