import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'employee_dashboard.dart';
import 'customer_dashboard.dart';
import 'database_helper.dart';
import 'qr_scanner_screen.dart';
import 'app_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'admin';
  bool _isLoading = false;

  void _login() async {
    String user = _usernameController.text.trim();
    String pass = _passwordController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام کاربری و رمز عبور را وارد کنید'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    if (_selectedRole == 'admin') {
      if (user == 'admin' && pass == '1234') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام کاربری یا رمز عبور مدیر اشتباه است'), backgroundColor: Colors.red));
      }
    } else if (_selectedRole == 'employee') {
      final emp = await DatabaseHelper.instance.getEmployeeByCredentials(user, pass);
      if (emp != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EmployeeDashboard(employeeData: emp)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کارمند یافت نشد یا غیرفعال است'), backgroundColor: Colors.red));
      }
    } else {
      if (pass == '1234') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerDashboard()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز عبور مشتری اشتباه است (پیش‌فرض: 1234)'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Center(
        child: SingleChildScrollView(
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
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'نام کاربری', prefixIcon: Icon(Icons.person, color: AppTheme.gold)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'رمز عبور', prefixIcon: Icon(Icons.lock, color: AppTheme.gold)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    dropdownColor: AppTheme.cardBlack,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'نقش', prefixIcon: Icon(Icons.badge, color: AppTheme.gold)),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('مدیر')),
                      DropdownMenuItem(value: 'employee', child: Text('کارمند/تکنسین')),
                      DropdownMenuItem(value: 'customer', child: Text('مشتری')),
                    ],
                    onChanged: (v) => setState(() => _selectedRole = v!),
                  ),
                  const SizedBox(height: 24),
                                    SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black), 
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('ورود', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedRole == 'admin' ? 'مدیر: admin / 1234' : (_selectedRole == 'customer' ? 'مشتری: هر نامی / 1234' : 'کارمند: نام ثبت‌شده / رمز تعیین‌شده'),
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.gold),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                    },
                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.gold),
                    label: const Text('اسکن کد دعوت', style: TextStyle(color: AppTheme.gold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.gold),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
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