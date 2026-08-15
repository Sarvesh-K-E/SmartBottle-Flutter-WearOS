import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/wear_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SmartBottleWearApp()));
}

class SmartBottleWearApp extends StatelessWidget {
  const SmartBottleWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Bottle Watch',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const WearHomeScreen(),
    );
  }
}
