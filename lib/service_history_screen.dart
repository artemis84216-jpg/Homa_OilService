import 'package:flutter/material.dart';
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
  bool _isLoadingVehicles = true;
  bool _isLoadingHistory = false;

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
    setState(() { _history = data; _isLoadingHistory = false; });
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
            child: _isLoadingVehicles ? const CircularProgressIndicator(color: AppTheme.gold) : DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedVehicle,
              dropdownColor: AppTheme.cardBlack,
              decoration: const InputDecoration(labelText: 'انتخاب خودرو', prefixIcon: Icon(Icons.directions_car, color: AppTheme.gold)),
              items: _vehicles.map((v) => DropdownMenuItem<Map<String, dynamic>>(
                value: v,
                child: Text('${v['plate_number']} - ${v['brand'] ?? ''} ${v['model'] ?? ''}', style: const TextStyle(color: AppTheme.textWhite)),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedVehicle = val);
                if (val != null) _loadHistory(val['id']);
              },
            ),
          ),
          Expanded(
            child: _selectedVehicle == null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('ابتدا یک خودرو انتخاب کنید', style: TextStyle(fontSize: 16, color: AppTheme.textGrey))]))
                : _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                    : _history.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_busy, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('سابقه‌ای برای این خودرو ثبت نشده', style: TextStyle(fontSize: 16, color: AppTheme.textGrey))]))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final h = _history[index];
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
                                    if ((h['oil_brand'] ?? '').toString().isNotEmpty)
                                      Text('روغن: ${h['oil_brand']} ${h['oil_viscosity'] ?? ''}', style: const TextStyle(color: AppTheme.textWhite)),
                                    if ((h['oil_volume'] ?? 0) > 0)
                                      Text('حجم: ${formatNumber(h['oil_volume'].toDouble())} لیتر', style: const TextStyle(color: AppTheme.textWhite)),
                                    const SizedBox(height: 8),
                                    Text('تاریخ: ${h['created_at']?.toString().split(' ').first ?? ''}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                                    if ((h['technician_notes'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('یادداشت: ${h['technician_notes']}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
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