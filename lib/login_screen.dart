import 'package:flutter/material.dart';
import 'app_utils.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBlack,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.gold, width: 2),
                    ),
                    child: const Icon(Icons.oil_barrel, size: 50, color: AppTheme.gold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Homa_OilService', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.gold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  const Text('سیستم مدیریت تعویض روغنی', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                  const SizedBox(height: 32),
                  const Text(
                    'در حال آماده‌سازی صفحات ورود...\n\nدر فازهای بعدی، ورود مدیر، کارمند و مشتری اضافه می‌شود.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textWhite, fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('در فاز بعدی فعال می‌شود'), backgroundColor: AppTheme.gold),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('ورود به عنوان مدیر'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}