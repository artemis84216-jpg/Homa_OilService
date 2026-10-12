import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import 'developer_panel_screen.dart';
import 'app_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _logoTapCount = 0;
  Timer? _tapTimer;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  void _onLogoTap() {
    setState(() => _logoTapCount++);
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 1500), () {
      setState(() => _logoTapCount = 0);
    });
    if (_logoTapCount >= 5) {
      _tapTimer?.cancel();
      _navigationTimer?.cancel();
      setState(() => _logoTapCount = 0);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperPanelScreen()));
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Center(
        child: GestureDetector(
          onTap: _onLogoTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppTheme.cardBlack,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.gold, width: 3),
                  boxShadow: [BoxShadow(color: AppTheme.gold.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
                ),
                child: const Icon(Icons.oil_barrel, size: 100, color: AppTheme.gold),
              ),
              const SizedBox(height: 30),
              const Text('Homa_OilService', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.gold, letterSpacing: 2)),
              const SizedBox(height: 8),
              const Text('همـا تعویض روغنی', style: TextStyle(fontSize: 18, color: AppTheme.textYellow)),
              const SizedBox(height: 60),
              const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 2)),
              const SizedBox(height: 20),
              Text('نسخه ۱.۰.۰', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}