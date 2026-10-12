import 'package:flutter/material.dart';
import 'package:homa_oil_change/core/app_theme.dart';
// import 'package:homa_oil_change/screens/login_screen.dart'; // بعداً اضافه می‌شود

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _onLogoTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 5) {
        _tapCount = 0;
        _showDevDialog();
      }
    });
  }

  void _showDevDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('پنل توسعه‌دهنده', style: TextStyle(color: AppTheme.gold)),
        content: const TextField(
          decoration: InputDecoration(hintText: 'رمز عبور (پیش‌فرض: 2026)'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              // منطق بررسی رمز و فعال‌سازی Master Mode
              Navigator.of(context).pop();
            },
            child: const Text('تأیید'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: GestureDetector(
        onTap: _onLogoTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.oil_barrel, size: 80, color: AppTheme.gold),
              const SizedBox(height: 16),
												const Text(
												  'Homa_OilService',
												  style: TextStyle(color: AppTheme.gold, fontSize: 28, fontWeight: FontWeight.bold),
												),
												const SizedBox(height: 8),
												const Text(
												  'همـا تعویض روغنی',
												  style: TextStyle(color: AppTheme.textLight, fontSize: 18),
												),
            ],

          ),
        ),
      ),
    );
  }
}