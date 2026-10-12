import 'package:flutter/material.dart';
import 'app_utils.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homa_OilService',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkGoldTheme,
      home: const SplashScreen(),
    );
  }
}