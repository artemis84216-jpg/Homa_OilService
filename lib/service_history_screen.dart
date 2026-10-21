import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    // استفاده از متد جدید برای دریافت اطلاعات کامل
    final data = await DatabaseHelper.instance.getAllServiceHistoryWithDetails();
    setState(() { 
      _history = data; 
      _filteredHistory = data;
      _isLoading = false; 
    });
  }

  void _filterHistory(String query) {
    setState(() {
      if (query.isEmpty) { _filteredHistory = _history; }
      else {
        final q = query.toLowerCase();
        _filteredHistory = _history.where((h) => 
          (h['plate_number'] ?? '').toString().toLowerCase().contains(q) ||
          (h['customer_name'] ?? '').toString().toLowerCase().contains(q) ||
          (h['national_id'] ?? '').toString().toLowerCase().contains(q) ||
          (h['service_type'] ?? '').toString().toLowerCase().contains(q)
        ).toList();
      }
    });
  }

  String _formatToJalali(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'نامشخص';
    try {
      final cleanDate = dateStr.split(' ')[0];
      final parts = cleanDate.split('-');
      if (parts.length == 3) {
        final miladi = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final jalali = Jalali.fromDateTime(miladi);
        return '${toPersianDigits(jalali.year.toString())}/${toPersianDigits(jalali.month.toString().padLeft(2, '0'))}/${toPersianDigits(jalali.day.toString().padLeft(2, '0'))}';
      }
    } catch (e) {
      return dateStr;
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('سوابق سرویس خودرو'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadHistory),
      ]),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'جستجو بر اساس پلاک، نام مالک یا کد ملی...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterHistory(''); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filterHistory,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _filteredHistory.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_busy, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('سابقه‌ای یافت نشد', style: TextStyle(fontSize: 16, color: AppTheme.textGrey))]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          final h = _filteredHistory[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  const Icon(Icons.directions_car, color: AppTheme.oilBlue),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('${h['plate_number'] ?? 'نامشخص'} | ${h['brand'] ?? ''} ${h['model'] ?? ''}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold))),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text('${formatNumber(h['mileage'] ?? 0)} کیلومتر', style: const TextStyle(color: AppTheme.gold, fontSize: 12))),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.person, color: AppTheme.textGrey, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('مالک: ${h['customer_name'] ?? 'نامشخص'} ${h['national_id'] != null ? '(کد ملی: ${h['national_id']})' : ''}', style: const TextStyle(color: AppTheme.textGrey))),
                                ]),
                                const Divider(color: AppTheme.gold, height: 20),
                                Row(children: [
                                  const Icon(Icons.build, color: AppTheme.gold),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(h['service_type'] ?? 'سرویس', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16))),
                                ]),
                                const SizedBox(height: 8),
                                if ((h['oil_brand'] ?? '').toString().isNotEmpty && h['oil_brand'] != 'سرویس دوره')
                                  Text('روغن: ${h['oil_brand']} ${h['oil_viscosity'] ?? ''}', style: const TextStyle(color: AppTheme.textWhite)),
                                if ((h['oil_volume'] ?? 0) > 0)
                                  Text('حجم: ${formatNumber((h['oil_volume'] as num).toDouble())} لیتر', style: const TextStyle(color: AppTheme.textWhite)),
                                const SizedBox(height: 8),
                                Text('تاریخ سرویس: ${_formatToJalali(h['created_at'])}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                                if ((h['technician_notes'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.notes, color: AppTheme.textGrey, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text('یادداشت: ${h['technician_notes']}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13))),
                                      ],
                                    ),
                                  ),
                                ],
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