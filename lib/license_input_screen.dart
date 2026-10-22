import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'device_info_helper.dart';
import 'license_helper.dart';
import 'app_utils.dart';

class LicenseInputScreen extends StatefulWidget {
  const LicenseInputScreen({super.key});

  @override
  State<LicenseInputScreen> createState() => _LicenseInputScreenState();
}

class _LicenseInputScreenState extends State<LicenseInputScreen> {
  final _licenseController = TextEditingController();
  final _shopNameController = TextEditingController();
  bool _isLoading = false;
  String _deviceId = 'در حال دریافت...';
  Map<String, dynamic>? _currentLicense;
  String _currentPlanName = 'بدون لایسنس';
  String _currentShopName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final id = await DeviceInfoHelper.instance.getDeviceId();
    final license = await LicenseHelper.getLicense();
    final prefs = await SharedPreferences.getInstance();
    final savedShopName = prefs.getString('shop_name') ?? '';
    
    String planName = 'بدون لایسنس';
    if (license != null && license['isActive'] == true) {
      final plans = await DatabaseHelper.instance.getAllPlans();
      final plan = plans.firstWhere((p) => p['id'] == license['planId'], orElse: () => {});
      if (plan.isNotEmpty) planName = plan['name'] ?? 'پلن نامشخص';
    }
    setState(() { 
      _deviceId = id; 
      _currentLicense = license; 
      _currentPlanName = planName;
      _currentShopName = savedShopName;
      _shopNameController.text = savedShopName;
    });
  }

  Future<void> _activateLicense() async {
    if (_licenseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد لایسنس را وارد کنید'), backgroundColor: Colors.red));
      return;
    }
    if (_shopNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام مرکز تعویض روغنی را وارد کنید'), backgroundColor: Colors.red));
      return;
    }
    
    setState(() => _isLoading = true);
    final result = LicenseHelper.validateLicense(_licenseController.text.trim(), _deviceId);
    if (result == null || result.containsKey('error')) {
      setState(() => _isLoading = false);
      String errorMsg = 'کد لایسنس نامعتبر است';
      if (result != null) {
        switch (result['error']) {
          case 'device_mismatch': errorMsg = 'این کد برای دستگاه دیگری است'; break;
          case 'invalid_checksum': errorMsg = 'کد دستکاری شده است'; break;
          case 'expired': errorMsg = 'کد منقضی شده است'; break;
          case 'invalid_format': errorMsg = 'فرمت نامعتبر'; break;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
      return;
    }
    final plans = await DatabaseHelper.instance.getAllPlans();
    final plan = plans.firstWhere((p) => p['id'] == result['planId'], orElse: () => {});
    if (plan.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پلن یافت نشد'), backgroundColor: Colors.red));
      return;
    }
    
    int bonusDays = 0;
    if (_currentLicense != null && _currentLicense!['isActive'] == true) {
      bonusDays = _currentLicense!['daysRemaining'] ?? 0;
    }
    Jalali finalExpiry = result['expiryJalali'];
    if (bonusDays > 0) finalExpiry = finalExpiry.addDays(bonusDays);
    await LicenseHelper.saveLicense(_licenseController.text.trim(), result['planId'], finalExpiry);
    
    // ذخیره نام مرکز در SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_name', _shopNameController.text.trim());
    
    setState(() => _isLoading = false);
    final isUpgrade = _currentLicense != null && _currentLicense!['isActive'] == true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isUpgrade ? '✓ پلن ارتقا یافت - ${plan['name']} (+$bonusDays روز)' : '✓ لایسنس فعال شد - ${plan['name']}'),
      backgroundColor: Colors.green, duration: const Duration(seconds: 3),
    ));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveLicense = _currentLicense != null && _currentLicense!['isActive'] == true;
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('فعال‌سازی لایسنس'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: hasActiveLicense ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: hasActiveLicense ? Colors.green : Colors.orange, width: 1)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(hasActiveLicense ? Icons.upgrade : Icons.info, color: hasActiveLicense ? Colors.green : Colors.orange, size: 24), const SizedBox(width: 8), Expanded(child: Text(hasActiveLicense ? 'ارتقا پلن' : 'فعال‌سازی اولیه', style: TextStyle(color: hasActiveLicense ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)))]),
                const SizedBox(height: 8),
                if (hasActiveLicense) ...[
                  Text('پلن فعلی: $_currentPlanName', style: const TextStyle(color: AppTheme.textWhite)),
                  Text('نام مرکز: $_currentShopName', style: const TextStyle(color: AppTheme.textWhite)),
                  Text('روزهای باقی‌مانده: ${toPersianDigits((_currentLicense!['daysRemaining']).toString())}', style: const TextStyle(color: AppTheme.textWhite)),
                ] else
                  const Text('برای استفاده از اپ، کد لایسنس و نام مرکز را وارد کنید.', style: TextStyle(color: Colors.orange, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.gold, width: 1)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('شناسه دستگاه شما:', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                const SizedBox(height: 4),
                SelectableText(_deviceId, style: const TextStyle(color: AppTheme.textYellow, fontSize: 12, fontFamily: 'monospace')),
              ]),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _shopNameController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: const InputDecoration(
                labelText: 'نام مرکز تعویض روغنی',
                hintText: 'مثال: تعویض روغنی هما',
                prefixIcon: Icon(Icons.business, color: AppTheme.gold),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _licenseController, style: const TextStyle(color: AppTheme.textWhite, fontFamily: 'monospace', fontSize: 12), maxLines: 4, decoration: const InputDecoration(labelText: 'کد لایسنس', prefixIcon: Icon(Icons.key, color: AppTheme.gold), alignLabelWithHint: true)),
            const SizedBox(height: 24),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _activateLicense,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.check_circle, size: 24),
                label: Text(_isLoading ? 'در حال بررسی...' : (hasActiveLicense ? 'ارتقا پلن' : 'فعال‌سازی'), style: const TextStyle(fontSize: 18)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}