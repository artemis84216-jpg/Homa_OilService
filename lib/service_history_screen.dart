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
    final data = await DatabaseHelper.instance.getAllServiceHistoryWithDetails();
    setState(() {
      _history = data;
      _filteredHistory = data;
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ سوابق بروزرسانی شد'), backgroundColor: AppTheme.gold),
      );
    }
  }

  void _filterHistory(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredHistory = List.from(_history);
      } else {
        _filteredHistory = _history.where((h) {
          return (h['plate_number'] ?? '').toString().toLowerCase().contains(q) ||
              (h['customer_name'] ?? '').toString().toLowerCase().contains(q) ||
              (h['national_id'] ?? '').toString().toLowerCase().contains(q) ||
              (h['brand'] ?? '').toString().toLowerCase().contains(q) ||
              (h['service_type'] ?? '').toString().toLowerCase().contains(q);
        }).toList();
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
      appBar: AppBar(
        title: const Text('سوابق سرویس خودرو'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadHistory),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'جستجو بر اساس پلاک، نام مالک یا کد ملی...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterHistory(''); })
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: _filterHistory,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                  : _filteredHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 80, color: AppTheme.textGrey),
                              const SizedBox(height: 16),
                              Text('سابقه‌ای یافت نشد', style: TextStyle(fontSize: 16, color: AppTheme.textGrey)),
                              const SizedBox(height: 8),
                              Text('پس از ثبت فاکتور شامل روغن یا فیلتر، سابقه سرویس اینجا ثبت می‌شود', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredHistory.length,
                          itemBuilder: (context, index) {
                            final h = _filteredHistory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_car, color: AppTheme.oilBlue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${h['plate_number'] ?? 'نامشخص'} | ${h['brand'] ?? ''} ${h['model'] ?? ''}',
                                            style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, color: AppTheme.textGrey, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'مالک: ${h['customer_name'] ?? 'نامشخص'} | کد ملی: ${h['national_id'] ?? '-'}',
                                            style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(color: AppTheme.gold, height: 24),
                                    Row(
                                      children: [
                                        const Icon(Icons.build, color: AppTheme.gold),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            h['service_type'] ?? 'سرویس',
                                            style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                          child: Text('${formatNumber((h['mileage'] ?? 0).toInt())} کیلومتر', style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if ((h['oil_brand'] ?? '').toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text('روغن / کالا: ${h['oil_brand']}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 13)),
                                      ),
                                    if ((h['oil_viscosity'] ?? '').toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text('گرانروی: ${h['oil_viscosity']}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 13)),
                                      ),
                                    if ((h['oil_volume'] ?? 0) > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text('حجم: ${formatNumber((h['oil_volume'] as num).toDouble())} لیتر', style: const TextStyle(color: AppTheme.textWhite, fontSize: 13)),
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: AppTheme.textGrey, size: 16),
                                        const SizedBox(width: 6),
                                        Text('تاریخ سرویس: ${_formatToJalali(h['created_at'])}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                                      ],
                                    ),
                                    if ((h['technician_notes'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: AppTheme.backgroundBlack, borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.notes, color: AppTheme.textGrey, size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text('یادداشت: ${h['technician_notes']}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}