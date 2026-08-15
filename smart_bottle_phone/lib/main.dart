import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'core/theme.dart';
import 'services/background_tasks.dart';
import 'services/notification_service.dart';
import 'ui/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestAndroidNotificationPermission();
  await Workmanager().initialize(callbackDispatcher);
  runApp(const ProviderScope(child: SmartBottleApp()));
}

class SmartBottleApp extends StatelessWidget {
  const SmartBottleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Bottle',
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
