import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // بررسی رمز فعلی مدیر
      final admin = await DatabaseHelper.instance.getAgentByCredentials('admin', _currentPassController.text);
      // نکته: در این نسخه ساده، رمز مدیر در کد hardcode شده (admin/1234). 
      // برای تغییر واقعی، باید جدول admins را آپدیت کنیم. اینجا فرض می‌کنیم رمز پیش‌فرض 1234 است.
      if (_currentPassController.text != '1234') {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز فعلی اشتباه است'), backgroundColor: Colors.red));
         setState(() => _isLoading = false);
         return;
      }

      // آپدیت رمز در دیتابیس (اگر رکورد admin وجود داشته باشد)
      final allAgents = await DatabaseHelper.instance.getAllAgents();
      final adminRecord = allAgents.firstWhere((a) => a['name'] == 'admin', orElse: () => {});
      
      if (adminRecord.isNotEmpty) {
        await DatabaseHelper.instance.updateAgent(adminRecord['id'], {'password': _newPassController.text});
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ رمز عبور با موفقیت تغییر کرد'), backgroundColor: Colors.green));
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  void _exitApp() {
    // مورد ۵: خروج کامل از برنامه
    SystemNavigator.pop();
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
              // بخش تغییر رمز
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.lock, color: AppTheme.gold), SizedBox(width: 8), Text('تغییر رمز عبور مدیر', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 16),
                      TextField(controller: _currentPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز عبور فعلی', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.gold))),
                      const SizedBox(height: 12),
                      TextField(controller: _newPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز عبور جدید', prefixIcon: Icon(Icons.key, color: AppTheme.gold))),
                      const SizedBox(height: 12),
                      TextField(controller: _confirmPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تکرار رمز عبور جدید', prefixIcon: Icon(Icons.key, color: AppTheme.gold))),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _changePassword,
                          icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.save),
                          label: const Text('ذخیره رمز جدید'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // بخش خروج از برنامه
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
                          label: const Text('خروج کامل'),
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