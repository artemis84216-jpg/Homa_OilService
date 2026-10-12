import 'package:flutter/material.dart';
import 'app_utils.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('پنل مشتری'), centerTitle: true),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.person, size: 80, color: AppTheme.gold),
          const SizedBox(height: 16),
          const Text('پنل مشتری در فاز بعدی تکمیل می‌شود', style: TextStyle(color: AppTheme.textWhite, fontSize: 18)),
        ]),
      ),
    );
  }
}