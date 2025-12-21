import 'package:cheque_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 👇 Initialize local notifications
  await NotificationService.instance.init();

  runApp(
    KhaltiScope(
      publicKey: AppConstants.khaltiPublicKey,
      builder: (context, navKey) {
        return const ChequeApp();
      },
    ),
  );
}
