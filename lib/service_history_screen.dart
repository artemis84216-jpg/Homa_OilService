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
  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic>? _selectedVehicle;
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoadingVehicles = true;
  bool _isLoadingHistory = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoadingVehicles = true);
    final data = await DatabaseHelper.instance.getAllVehicles();
    setState(() { _vehicles = data; _isLoadingVehicles = false; });
  }

  Future<void> _loadHistory(int vehicleId) async {
    setState(() => _isLoadingHistory = true);
    final data = await DatabaseHelper.instance.getServiceHistoryByVehicle(vehicleId);
    setState(() { 
      _history = data; 
      _filteredHistory = data;
      _isLoadingHistory = false; 
    });
  }

  void _filterHistory(String query) {
    setState(() {
      if (query.isEmpty) { _filteredHistory = _history; }
      else {
        _filteredHistory = _history.where((h) => 
          (h['service_type'] ?? '').toString().contains(query) ||
          (h['oil_brand'] ?? '').toString().contains(query) ||
          (h['technician_notes'] ?? '').toString().contains(query)
        ).toList();
      }
    });
  }

  // تبدیل تاریخ میلادی به شمسی برای نمایش
  String _formatToJalali(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'نامشخص';
    try {
      // فرمت پایگاه داده: "2024-10-25 14:30:00"
      final cleanDate = dateStr.split(' ')[0];
      final parts = cleanDate.split('-');
      if (parts.length == 3) {
        final miladi = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final jalali = Jalali.fromDateTime(miladi);
        return '${toPersianDigits(jalali.year.toString())}/${toPersianDigits(jalali.month.toString().padLeft(2, '0'))}/${toPersianDigits(jalali.day.toString().padLeft(2, '0'))}';
      }
    } catch (e) {
      // اگر قبلاً شمسی ذخیره شده باشد
      return dateStr;
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('سوابق سرویس خودرو'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _isLoadingVehicles ? const CircularProgressIndicator(color: AppTheme.gold) : Column(
              children: [
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedVehicle,
                  dropdownColor: AppTheme.cardBlack,
                  decoration: const InputDecoration(labelText: 'انتخاب خودرو', prefixIcon: Icon(Icons.directions_car, color: AppTheme.gold)),
                  items: _vehicles.map((v) => DropdownMenuItem<Map<String, dynamic>>(
                    value: v,
                    child: Text('${v['plate_number']} - ${v['brand'] ?? ''} ${v['model'] ?? ''}', style: const TextStyle(color: AppTheme.textWhite)),
                  )).toList(),
                  onChanged: (val) {
                    setState(() => _selectedVehicle = val);
                    if (val != null) {
                      _loadHistory(val['id']);
                      _searchController.clear();
                    }
                  },
                ),
                if (_selectedVehicle != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      hintText: 'جستجو در نوع سرویس، روغن یا یادداشت...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                      suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterHistory(''); }) : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: _filterHistory,
                  ),
                ]
              ],
            ),
          ),
          Expanded(
            child: _selectedVehicle == null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('ابتدا یک خودرو انتخاب کنید', style: TextStyle(fontSize: 16, color: AppTheme.textGrey))]))
                : _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                    : _filteredHistory.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_busy, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('سابقه‌ای برای این خودرو یافت نشد', style: TextStyle(fontSize: 16, color: AppTheme.textGrey))]))
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
                                      const Icon(Icons.build, color: AppTheme.gold),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(h['service_type'] ?? 'سرویس', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16))),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text('${formatNumber(h['mileage'] ?? 0)} کیلومتر', style: const TextStyle(color: AppTheme.gold, fontSize: 12))),
                                    ]),
                                    const SizedBox(height: 12),
                                    if ((h['oil_brand'] ?? '').toString().isNotEmpty && h['oil_brand'] != 'سرویس دوره')
                                      Text('روغن: ${h['oil_brand']} ${h['oil_viscosity'] ?? ''}', style: const TextStyle(color: AppTheme.textWhite)),
                                    if ((h['oil_volume'] ?? 0) > 0)
                                      Text('حجم: ${formatNumber((h['oil_volume'] as num).toDouble())} لیتر', style: const TextStyle(color: AppTheme.textWhite)),
                                    const SizedBox(height: 8),
                                    // حل مورد ۸: نمایش تاریخ به صورت شمسی
                                    Text('تاریخ سرویس: ${_formatToJalali(h['created_at'])}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                                    if ((h['next_service_date'] ?? '').toString().isNotEmpty)
                                      Text('سرویس بعدی: ${_formatToJalali(h['next_service_date'])} (کیلومتر: ${formatNumber(h['next_service_mileage'] ?? 0)})', style: const TextStyle(color: AppTheme.oilBlue, fontSize: 12, fontWeight: FontWeight.bold)),
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