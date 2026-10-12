import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class LicensesHistoryScreen extends StatefulWidget {
  const LicensesHistoryScreen({super.key});

  @override
  State<LicensesHistoryScreen> createState() => _LicensesHistoryScreenState();
}

class _LicensesHistoryScreenState extends State<LicensesHistoryScreen> {
  List<Map<String, dynamic>> _licenses = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses({String? query}) async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> data = query != null && query.isNotEmpty ? await DatabaseHelper.instance.searchLicenses(query) : await DatabaseHelper.instance.getAllLicenses();
    setState(() { _licenses = data; _isLoading = false; });
  }

  String _formatIssuedAt(String? issuedAt) {
    if (issuedAt == null || issuedAt.isEmpty) return 'نامشخص';
    try {
      final parts = issuedAt.split(' ')[0].split('-');
      if (parts.length != 3) return issuedAt;
      final miladi = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final jalali = Jalali.fromDateTime(miladi);
      return '${toPersianDigits(jalali.year.toString())}/${toPersianDigits(jalali.month.toString().padLeft(2, '0'))}/${toPersianDigits(jalali.day.toString().padLeft(2, '0'))}';
    } catch (e) {
      return issuedAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('سوابق لایسنس‌ها'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(hintText: 'جستجو در نام مرکز یا شناسه دستگاه...', prefixIcon: const Icon(Icons.search, color: AppTheme.gold), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _loadLicenses(); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onChanged: (value) => _loadLicenses(query: value),
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _licenses.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('هنوز لایسنسی صادر نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _licenses.length,
              itemBuilder: (context, index) {
                final l = _licenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.business, color: AppTheme.gold, size: 24),
                        const SizedBox(width: 8),
                        Expanded(child: Text(l['shop_name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold))),
                      ]),
                      const SizedBox(height: 12),
                      Text('پلن: ${l['plan_name']}', style: const TextStyle(color: AppTheme.textWhite)),
                      Text('تاریخ شروع: ${_formatIssuedAt(l['issued_at'])}', style: const TextStyle(color: AppTheme.textWhite)),
                      Text('تاریخ انقضا: ${l['expiry_date']}', style: const TextStyle(color: AppTheme.textWhite)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.fingerprint, color: AppTheme.textGrey, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: SelectableText(l['device_id'] ?? '', style: const TextStyle(color: AppTheme.textYellow, fontSize: 11, fontFamily: 'monospace'))),
                        IconButton(icon: const Icon(Icons.copy, color: AppTheme.gold, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: l['device_id'] ?? '')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ شناسه کپی شد'))); }),
                      ]),
                      Row(children: [
                        const Icon(Icons.key, color: AppTheme.textGrey, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: SelectableText(l['license_code'] ?? '', style: const TextStyle(color: AppTheme.textYellow, fontSize: 10, fontFamily: 'monospace'))),
                        IconButton(icon: const Icon(Icons.copy, color: AppTheme.gold, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: l['license_code'] ?? '')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ کد کپی شد'))); }),
                      ]),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}