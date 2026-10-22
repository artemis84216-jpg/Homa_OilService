import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_info_helper.dart';
import 'license_helper.dart';
import 'license_manager.dart';
import 'license_input_screen.dart';
import 'database_helper.dart';
import 'employees_screen.dart';
import 'customers_screen.dart';
import 'vehicles_screen.dart';
import 'products_screen.dart';
import 'services_screen.dart';
import 'invoices_screen.dart';
import 'service_history_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'app_utils.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _deviceId = 'در حال دریافت...';
  String _shopName = '';
  Map<String, dynamic>? _license;
  String _planName = 'بدون لایسنس';
  Map<String, dynamic>? _usageStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final id = await DeviceInfoHelper.instance.getDeviceId();
    final license = await LicenseHelper.getLicense();
    final usage = await LicenseManager.getUsageStats();
    final prefs = await SharedPreferences.getInstance();
    final shopName = prefs.getString('shop_name') ?? '';
    
    String planName = 'بدون لایسنس';
    if (license != null && license['isActive'] == true) {
      final plans = await DatabaseHelper.instance.getAllPlans();
      final plan = plans.firstWhere((p) => p['id'] == license['planId'], orElse: () => {});
      if (plan.isNotEmpty) planName = plan['name'] ?? 'پلن نامشخص';
    }
    
    setState(() {
      _deviceId = id;
      _shopName = shopName;
      _license = license;
      _planName = planName;
      _usageStats = usage;
      _isLoading = false;
    });
    
    if (license != null && license['isActive'] == true) {
      final daysRemaining = license['daysRemaining'];
      if (daysRemaining <= 2 && daysRemaining >= 0) {
        if (mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ لایسنس شما ${toPersianDigits(daysRemaining.toString())} روز دیگر منقضی می‌شود.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          });
        }
      }
    }
  }

  bool get _isLicenseActive => _license != null && _license!['isActive'] == true;

  Color _getLicenseColor() {
    if (!_isLicenseActive) return Colors.red;
    final days = _license!['daysRemaining'];
    if (days <= 2) return Colors.orange;
    return Colors.green;
  }

  String _getLicenseStatus() {
    if (!_isLicenseActive) return 'غیرفعال';
    final days = _license!['daysRemaining'];
    final expiryJalali = _license!['expiryJalali'];
    return '${toPersianDigits(days.toString())} روز باقی‌مانده | انقضا: ${toPersianDigits(expiryJalali.year.toString())}/${toPersianDigits(expiryJalali.month.toString().padLeft(2, '0'))}/${toPersianDigits(expiryJalali.day.toString().padLeft(2, '0'))}';
  }

  Widget _buildUsageRow(IconData icon, String label, Map<String, dynamic> usage) {
    final current = usage['current'] ?? 0;
    final max = usage['max'] ?? 0;
    final isUnlimited = usage['isUnlimited'] ?? false;
    final currentStr = toPersianDigits(current.toString());
    final maxStr = isUnlimited ? '∞' : toPersianDigits(max.toString());
    Color progressColor = Colors.green;
    if (!isUnlimited && max > 0) {
      final percentage = current / max;
      if (percentage >= 1.0) progressColor = Colors.red;
      else if (percentage >= 0.8) progressColor = Colors.orange;
    }
    return Row(children: [
      Icon(icon, color: AppTheme.textGrey, size: 18),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(color: AppTheme.textGrey)),
      Text('$currentStr از $maxStr', style: TextStyle(color: progressColor, fontWeight: FontWeight.bold)),
      if (!isUnlimited && max > 0) ...[
        const SizedBox(width: 8),
        Expanded(child: LinearProgressIndicator(value: (current / max).clamp(0.0, 1.0), backgroundColor: Colors.grey[800], valueColor: AlwaysStoppedAnimation<Color>(progressColor), minHeight: 4)),
      ],
    ]);
  }

  void _navigateTo(Widget screen, String feature) {
    if (!_isLicenseActive) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا لایسنس را فعال کنید'), backgroundColor: Colors.red));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('پنل مدیریت'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: AppTheme.gold), onPressed: () => _navigateTo(const SettingsScreen(), 'تنظیمات')),
          IconButton(icon: const Icon(Icons.logout, color: AppTheme.gold), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // کارت نام مرکز
                    if (_shopName.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.gold.withOpacity(0.2), AppTheme.gold.withOpacity(0.05)]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.gold, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business, color: AppTheme.gold, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('نام مرکز', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Text(_shopName, style: const TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // کارت وضعیت لایسنس
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getLicenseColor(), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.security, color: _getLicenseColor(), size: 24),
                            const SizedBox(width: 8),
                            Expanded(child: Text('لایسنس: $_planName', style: TextStyle(color: _getLicenseColor(), fontWeight: FontWeight.bold, fontSize: 16))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: _getLicenseColor().withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text(_isLicenseActive ? 'فعال' : 'غیرفعال', style: TextStyle(color: _getLicenseColor(), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(_getLicenseStatus(), style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                          if (!_isLicenseActive) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseInputScreen()));
                                  if (result == true) _loadData();
                                },
                                icon: const Icon(Icons.key, size: 18),
                                label: const Text('فعال‌سازی لایسنس', style: TextStyle(fontSize: 14)),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseInputScreen()));
                                  if (result == true) _loadData();
                                },
                                icon: const Icon(Icons.upgrade, size: 18, color: AppTheme.gold),
                                label: const Text('ارتقا پلن', style: TextStyle(fontSize: 14, color: AppTheme.gold)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // کارت شناسه دستگاه
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gold, width: 1),
                      ),
                      child: Row(children: [
                        const Icon(Icons.fingerprint, color: AppTheme.gold, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('شناسه دستگاه:', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                              Text(_deviceId, style: const TextStyle(color: AppTheme.textYellow, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppTheme.gold, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _deviceId));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ شناسه کپی شد'), backgroundColor: AppTheme.gold));
                          },
                        ),
                      ]),
                    ),

                    // کارت وضعیت مصرف پلن
                    if (_usageStats != null && _usageStats!['hasLicense'] == true)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.gold, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.bar_chart, color: AppTheme.gold, size: 20),
                              SizedBox(width: 8),
                              Text('وضعیت مصرف پلن', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                            ]),
                            const SizedBox(height: 12),
                            _buildUsageRow(Icons.people, 'کارمندان', _usageStats!['employees']),
                            const SizedBox(height: 8),
                            _buildUsageRow(Icons.directions_car, 'خودروها', _usageStats!['vehicles']),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // گرید کارت‌های اصلی
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildCard(context, Icons.people, 'کارمندان', AppTheme.gold, () => _navigateTo(const EmployeesScreen(), 'کارمندان')),
                        _buildCard(context, Icons.person, 'مشتریان', AppTheme.gold, () => _navigateTo(const CustomersScreen(), 'مشتریان')),
                        _buildCard(context, Icons.directions_car, 'خودروها', AppTheme.gold, () => _navigateTo(const VehiclesScreen(), 'خودروها')),
                        _buildCard(context, Icons.inventory_2, 'کالاها', AppTheme.gold, () => _navigateTo(const ProductsScreen(), 'کالاها')),
                        _buildCard(context, Icons.build, 'خدمات', AppTheme.gold, () => _navigateTo(const ServicesScreen(), 'خدمات')),
                        _buildCard(context, Icons.receipt_long, 'فاکتورها', AppTheme.gold, () => _navigateTo(const InvoicesScreen(), 'فاکتورها')),
                        _buildCard(context, Icons.history, 'سوابق سرویس', AppTheme.gold, () => _navigateTo(const ServiceHistoryScreen(), 'سوابق سرویس')),
                        _buildCard(context, Icons.money_off, 'هزینه‌ها', AppTheme.gold, () => _navigateTo(const ExpensesScreen(), 'هزینه‌ها')),
                        _buildCard(context, Icons.bar_chart, 'گزارشات', AppTheme.gold, () => _navigateTo(const ReportsScreen(), 'گزارشات')),
                        _buildCard(context, Icons.info, 'درباره ما', AppTheme.gold, () => _navigateTo(const AboutScreen(), 'درباره ما')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: _isLicenseActive ? onTap : () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا لایسنس را فعال کنید'), backgroundColor: Colors.red));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: _isLicenseActive ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isLicenseActive ? AppTheme.textWhite : Colors.grey)),
            if (!_isLicenseActive) ...[
              const SizedBox(height: 4),
              const Icon(Icons.lock, size: 14, color: Colors.red),
            ],
          ],
        ),
      ),
    );
  }
}