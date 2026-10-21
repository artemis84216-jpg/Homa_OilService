import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'license_helper.dart';
import 'plans_management_screen.dart';
import 'licenses_history_screen.dart';
import 'app_utils.dart';

class DeveloperPanelScreen extends StatefulWidget {
  const DeveloperPanelScreen({super.key});

  @override
  State<DeveloperPanelScreen> createState() => _DeveloperPanelScreenState();
}

class _DeveloperPanelScreenState extends State<DeveloperPanelScreen> {
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _deviceIdController = TextEditingController();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _selectedPlan;
  Jalali? _expiryDate;
  String? _generatedLicense;
  String _developerPassword = '2026';

  @override
  void initState() {
    super.initState();
    _loadSavedPassword();
  }

  Future<void> _loadSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('developer_password');
    if (saved != null && saved.isNotEmpty) {
      setState(() => _developerPassword = saved);
    }
  }

  Future<void> _loadPlans() async {
    final data = await DatabaseHelper.instance.getAllPlans();
    setState(() => _plans = data);
  }

  void _checkPassword() {
    if (_passwordController.text.trim() == _developerPassword) {
      setState(() => _isAuthenticated = true);
      _loadPlans();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز عبور اشتباه است'), backgroundColor: Colors.red));
    }
  }

  String _formatJalali(Jalali? date) {
    if (date == null) return 'انتخاب تاریخ انقضا';
    return '${toPersianDigits(date.year.toString())}/${toPersianDigits(date.month.toString().padLeft(2, '0'))}/${toPersianDigits(date.day.toString().padLeft(2, '0'))}';
  }

  void _calculateExpiryDate() {
    if (_selectedPlan == null) {
      setState(() => _expiryDate = null);
      return;
    }
    final durationValue = _selectedPlan!['duration_value'] ?? 0;
    final durationType = _selectedPlan!['duration_type'] ?? 'months';
    Jalali expiry = durationType == 'days' ? Jalali.now().addDays(durationValue) : Jalali.now().addMonths(durationValue);
    setState(() => _expiryDate = expiry);
  }

  Future<void> _generateLicense() async {
    if (_shopNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام مرکز تعویض روغنی را وارد کنید'), backgroundColor: Colors.red));
      return;
    }
    if (_deviceIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شناسه دستگاه را وارد کنید'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedPlan == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پلن و تاریخ انقضا را انتخاب کنید'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    final license = LicenseHelper.generateLicense(deviceId: _deviceIdController.text.trim(), expiryDate: _expiryDate!, planId: _selectedPlan!['id']);
    await DatabaseHelper.instance.insertLicense({
      'shop_name': _shopNameController.text.trim(),
      'device_id': _deviceIdController.text.trim(),
      'license_code': license,
      'plan_id': _selectedPlan!['id'],
      'plan_name': _selectedPlan!['name'],
      'expiry_date': _formatJalali(_expiryDate),
    });
    setState(() {
      _generatedLicense = license;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ لایسنس تولید و ذخیره شد'), backgroundColor: AppTheme.gold));
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('⚠️ هشدار جدی', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text('این عمل تمام اطلاعات را پاک می‌کند. آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بله، پاک کن', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.resetDatabase();
      await LicenseHelper.clearLicense();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ دیتابیس پاک شد'), backgroundColor: Colors.green));
    }
  }

  Future<void> _changeDeveloperPassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('تغییر رمز توسعه‌دهنده', style: TextStyle(color: AppTheme.gold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: currentController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز فعلی', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.gold))),
                const SizedBox(height: 12),
                TextField(controller: newController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز جدید', prefixIcon: Icon(Icons.key, color: AppTheme.gold))),
                const SizedBox(height: 12),
                TextField(controller: confirmController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تکرار رمز جدید', prefixIcon: Icon(Icons.key, color: AppTheme.gold))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
              onPressed: () async {
                if (currentController.text != _developerPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز فعلی اشتباه است'), backgroundColor: Colors.red));
                  return;
                }
                if (newController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز جدید و تکرار آن مطابقت ندارند'), backgroundColor: Colors.red));
                  return;
                }
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('developer_password', newController.text);
                setState(() => _developerPassword = newController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ رمز توسعه‌دهنده تغییر کرد'), backgroundColor: Colors.green));
              },
              child: const Text('ذخیره', style: TextStyle(fontWeight: FontWeight.bold)),
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
      appBar: AppBar(title: const Text('پنل توسعه‌دهنده'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.gold.withOpacity(0.3), AppTheme.gold.withOpacity(0.1)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.gold, width: 2)),
                child: const Column(children: [
                  Icon(Icons.developer_mode, color: AppTheme.gold, size: 50),
                  SizedBox(height: 8),
                  Text('پنل توسعه‌دهنده', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                  SizedBox(height: 4),
                  Text('Homa_OilService | نسخه ۱.۰.۰', style: TextStyle(color: AppTheme.textYellow, fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 24),
              if (!_isAuthenticated) ...[
                TextFormField(controller: _passwordController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز عبور توسعه‌دهنده', prefixIcon: Icon(Icons.lock, color: AppTheme.gold))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _checkPassword,
                  icon: const Icon(Icons.login),
                  label: const Text('ورود', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                ),
              ] else ...[
                const Text('۱. تولید کد لایسنس', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 8),
                TextFormField(controller: _shopNameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام مرکز تعویض روغنی', prefixIcon: Icon(Icons.business, color: AppTheme.gold))),
                const SizedBox(height: 16),
                TextFormField(controller: _deviceIdController, style: const TextStyle(color: AppTheme.textWhite, fontFamily: 'monospace'), decoration: const InputDecoration(labelText: 'شناسه دستگاه مدیر', prefixIcon: Icon(Icons.fingerprint, color: AppTheme.gold))),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedPlan,
                  dropdownColor: AppTheme.cardBlack,
                  decoration: const InputDecoration(labelText: 'انتخاب پلن', prefixIcon: Icon(Icons.subscriptions, color: AppTheme.gold)),
                  items: _plans.map((p) => DropdownMenuItem<Map<String, dynamic>>(value: p, child: Text(p['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite)))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedPlan = val);
                    _calculateExpiryDate();
                  },
                ),
                if (_selectedPlan != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.gold, width: 1)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('پلن: ${_selectedPlan!['name']}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('مدت: ${_selectedPlan!['duration_value']} ${_selectedPlan!['duration_type'] == 'days' ? 'روز' : 'ماه'}', style: const TextStyle(color: AppTheme.textWhite)),
                      Text('سقف کارمندان: ${_selectedPlan!['max_employees'] == 0 ? "نامحدود" : _selectedPlan!['max_employees'].toString()}', style: const TextStyle(color: AppTheme.textWhite)),
                      Text('سقف خودرو: ${_selectedPlan!['max_vehicles'] == 0 ? "نامحدود" : _selectedPlan!['max_vehicles'].toString()}', style: const TextStyle(color: AppTheme.textWhite)),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showPersianDatePicker(context: context, initialDate: _expiryDate ?? Jalali.now().addDays(30), firstDate: Jalali.now(), lastDate: Jalali(1450));
                    if (picked != null) setState(() => _expiryDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today, color: AppTheme.gold),
                  label: Text(_formatJalali(_expiryDate), style: const TextStyle(color: AppTheme.textWhite)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gold)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateLicense,
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.key),
                  label: const Text('تولید کد لایسنس', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                ),
                if (_generatedLicense != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('✓ کد لایسنس تولید شد', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SelectableText(_generatedLicense!, style: const TextStyle(color: AppTheme.textWhite, fontSize: 12, fontFamily: 'monospace')),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _generatedLicense!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ کپی شد')));
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('کپی کد', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                      ),
                    ]),
                  ),
                ],
                const Divider(color: AppTheme.gold, height: 40),
                const Text('۲. مدیریت و سوابق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LicensesHistoryScreen())),
                  icon: const Icon(Icons.history),
                  label: const Text('سوابق لایسنس‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansManagementScreen())),
                  icon: const Icon(Icons.settings),
                  label: const Text('مدیریت پلن‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                ),
                const Divider(color: AppTheme.gold, height: 40),
                const Text('۳. ابزارهای توسعه‌دهنده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _changeDeveloperPassword,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('تغییر رمز توسعه‌دهنده', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _resetDatabase,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('پاک کردن دیتابیس', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}