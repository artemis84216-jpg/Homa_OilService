import 'package:flutter/material.dart';
import 'app_utils.dart';

class EmployeeDashboard extends StatelessWidget {
  final Map<String, dynamic> employeeData;
  const EmployeeDashboard({super.key, required this.employeeData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: Text('پنل کارمند: ${employeeData['name'] ?? ""}'), centerTitle: true),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.engineering, size: 80, color: AppTheme.gold),
          const SizedBox(height: 16),
          const Text('پنل کارمند در فاز بعدی تکمیل می‌شود', style: TextStyle(color: AppTheme.textWhite, fontSize: 18)),
        ]),
      ),
    );
  }
}