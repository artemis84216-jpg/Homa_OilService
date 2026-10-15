import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'license_manager.dart';
import 'app_utils.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _filteredVehicles = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllVehicles();
    setState(() { _vehicles = data; _filteredVehicles = data; _isLoading = false; });
  }

  void _filterVehicles(String query) {
    setState(() {
      if (query.isEmpty) { _filteredVehicles = _vehicles; }
      else { _filteredVehicles = _vehicles.where((v) => (v['plate_number'] ?? '').toString().contains(query) || (v['brand'] ?? '').toString().contains(query) || (v['customer_name'] ?? '').toString().contains(query)).toList(); }
    });
  }

  Future<void> _showVehicleDialog({Map<String, dynamic>? veh}) async {
    final isEdit = veh != null;
    
    // چک محدودیت فقط هنگام افزودن
    if (!isEdit) {
      final check = await LicenseManager.canAddVehicle();
      if (!check['allowed']) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: AppTheme.cardBlack,
                title: const Row(children: [Icon(Icons.lock, color: Colors.red, size: 28), SizedBox(width: 8), Text('محدودیت پلن', style: TextStyle(color: Colors.red))]),
                content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(check['message'] ?? 'امکان ثبت خودرو جدید وجود ندارد', style: const TextStyle(color: AppTheme.textWhite)),
                  const SizedBox(height: 12),
                  const Text('برای افزایش سقف خودروها، پلن خود را ارتقا دهید.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                ]),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متوجه شدم', style: TextStyle(color: AppTheme.gold)))],
              ),
            ),
          );
        }
        return;
      }
    }
    
    final plateController = TextEditingController(text: veh?['plate_number']?.toString() ?? '');
    final brandController = TextEditingController(text: veh?['brand']?.toString() ?? '');
    final modelController = TextEditingController(text: veh?['model']?.toString() ?? '');
    final mileageController = TextEditingController(text: veh?['current_mileage']?.toString() ?? '0');
    final notesController = TextEditingController(text: veh?['notes']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: Text(isEdit ? 'ویرایش خودرو' : 'افزودن خودرو', style: const TextStyle(color: AppTheme.gold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: plateController, textCapitalization: TextCapitalization.characters, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'شماره پلاک', prefixIcon: Icon(Icons.directions_car, color: AppTheme.gold))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: brandController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'برند', prefixIcon: Icon(Icons.category, color: AppTheme.gold)))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: modelController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'مدل', prefixIcon: Icon(Icons.model_training, color: AppTheme.gold)))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: mileageController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'کیلومتر فعلی', prefixIcon: Icon(Icons.speed, color: AppTheme.gold))),
              const SizedBox(height: 12),
              TextField(controller: notesController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'یادداشت', prefixIcon: Icon(Icons.notes, color: AppTheme.gold))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
            ElevatedButton(
              onPressed: () async {
                if (plateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شماره پلاک الزامی است')));
                  return;
                }
                final vehData = {'plate_number': plateController.text.trim().toUpperCase(), 'brand': brandController.text.trim(), 'model': modelController.text.trim(), 'current_mileage': int.tryParse(mileageController.text) ?? 0, 'notes': notesController.text.trim()};
                if (isEdit) {
                  await DatabaseHelper.instance.updateVehicle(veh!['id'], vehData);
                } else {
                  await DatabaseHelper.instance.insertVehicle(vehData);
                }
                Navigator.pop(ctx);
                _loadVehicles();
              },
              child: Text(isEdit ? 'ذخیره' : 'افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteVehicle(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) {
      await DatabaseHelper.instance.deleteVehicle(id);
      _loadVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت خودروها'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(hintText: 'جستجو بر اساس پلاک، برند یا نام مشتری...', prefixIcon: const Icon(Icons.search, color: AppTheme.gold), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterVehicles(''); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onChanged: _filterVehicles,
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _filteredVehicles.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.directions_car, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('خودرویی یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredVehicles.length,
              itemBuilder: (context, index) {
                final v = _filteredVehicles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppTheme.oilBlue.withOpacity(0.2), child: const Icon(Icons.directions_car, color: AppTheme.oilBlue)),
                    title: Text(v['plate_number'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 16)),
                    subtitle: Text('${v['brand'] ?? ''} ${v['model'] ?? ''} | ${formatNumber(v['current_mileage'] ?? 0)} کیلومتر\nمالک: ${v['customer_name'] ?? 'ثبت نشده'}', style: const TextStyle(color: AppTheme.textGrey)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showVehicleDialog(veh: v)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteVehicle(v['id'])),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showVehicleDialog(), backgroundColor: AppTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن خودرو')),
    );
  }
}