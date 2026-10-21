import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'database_helper.dart';
import 'app_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (_currentPassController.text.isEmpty || _newPassController.text.isEmpty || _confirmPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً تمام فیلدها را پر کنید'), backgroundColor: Colors.red));
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز جدید و تکرار آن مطابقت ندارند'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // رمز پیش‌فرض مدیر: 1234
      if (_currentPassController.text != '1234') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز فعلی اشتباه است (پیش‌فرض: 1234)'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
        return;
      }

      // ذخیره رمز جدید در SharedPreferences برای استفاده بعدی
      final prefs = await _getPrefs();
      await prefs.setString('admin_password', _newPassController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ رمز عبور با موفقیت تغییر کرد'), backgroundColor: Colors.green),
      );
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  Future<dynamic> _getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  void _exitApp() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('خروج از برنامه', style: TextStyle(color: AppTheme.gold)),
          content: const Text('آیا مطمئن هستید که می‌خواهید از برنامه خارج شوید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                exit(0); // بستن کامل برنامه
              },
              child: const Text('بله، خارج شو', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('تنظیمات'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.lock, color: AppTheme.gold), SizedBox(width: 8), Text('تغییر رمز عبور مدیر', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 16),
                      TextField(controller: _currentPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز عبور فعلی (پیش‌فرض: 1234)', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.gold))),
                      const SizedBox(height: 12),
                      TextField(controller: _newPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز عبور جدید', prefixIcon: Icon(Icons.key, color: AppTheme.gold))),
                      const SizedBox(height: 12),
                      TextField(controller: _confirmPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تکرار رمز عبور جدید', prefixIcon: Icon(Icons.key, color: AppTheme.gold))),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                          onPressed: _isLoading ? null : _changePassword,
                          icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.save),
                          label: const Text('ذخیره رمز جدید', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.power_settings_new, color: Colors.red), SizedBox(width: 8), Text('خروج از برنامه', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 12),
                      const Text('با کلیک روی دکمه زیر، اپلیکیشن به طور کامل بسته می‌شود.', style: TextStyle(color: AppTheme.textGrey)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: _exitApp,
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('خروج کامل', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}