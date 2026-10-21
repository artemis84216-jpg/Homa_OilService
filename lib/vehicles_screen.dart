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
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final vehicles = await DatabaseHelper.instance.getAllVehicles();
    final customers = await DatabaseHelper.instance.getAllCustomers();
    setState(() { _vehicles = vehicles; _filteredVehicles = vehicles; _customers = customers; _isLoading = false; });
  }

  void _filterVehicles(String query) {
    setState(() {
      if (query.isEmpty) { _filteredVehicles = _vehicles; }
      else { _filteredVehicles = _vehicles.where((v) => (v['plate_number'] ?? '').toString().contains(query) || (v['brand'] ?? '').toString().contains(query) || (v['customer_name'] ?? '').toString().contains(query)).toList(); }
    });
  }

  // تابع کمکی برای نمایش لیست کشویی قابل جستجو (حل مورد ۴)
  Future<Map<String, dynamic>?> _showSearchableCustomerList() async {
    String query = '';
    List<Map<String, dynamic>> filtered = List.from(_customers);
    
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppTheme.cardBlack,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  autofocus: true,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    hintText: 'جستجوی نام یا شماره تماس...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                    suffixIcon: IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () {
                      setModalState(() { query = ''; filtered = List.from(_customers); });
                    }),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      query = val;
                      filtered = _customers.where((c) => (c['name'] ?? '').contains(val) || (c['phone'] ?? '').contains(val)).toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: AppTheme.gold, child: Icon(Icons.person, color: Colors.black)),
                      title: Text(c['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite)),
                      subtitle: Text(c['phone'] ?? '', style: const TextStyle(color: AppTheme.textGrey)),
                      onTap: () => Navigator.pop(ctx, c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addQuickCustomer(Function(Map<String, dynamic>) onAdded) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final nationalIdController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('افزودن مشتری جدید', style: TextStyle(color: AppTheme.gold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام و نام خانوادگی *', prefixIcon: Icon(Icons.person, color: AppTheme.gold))),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شماره تماس *', prefixIcon: Icon(Icons.phone, color: AppTheme.gold))),
              const SizedBox(height: 12),
              TextField(controller: nationalIdController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'کد ملی', prefixIcon: Icon(Icons.badge, color: AppTheme.gold))),
              const SizedBox(height: 12),
              TextField(controller: addressController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'آدرس', prefixIcon: Icon(Icons.location_on, color: AppTheme.gold))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام و شماره تماس الزامی است'), backgroundColor: Colors.red));
                  return;
                }
                final customerData = {'name': nameController.text.trim(), 'phone': phoneController.text.trim(), 'national_id': nationalIdController.text.trim(), 'address': addressController.text.trim()};
                final id = await DatabaseHelper.instance.insertCustomer(customerData);
                Navigator.pop(ctx, {'id': id, ...customerData});
              },
              child: const Text('افزودن', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      // حل مورد ۳: آپدیت آنی لیست والد و دیالوگ
      setState(() => _customers.add(result));
      onAdded(result);
    }
  }

  Future<void> _showVehicleDialog({Map<String, dynamic>? veh}) async {
    final isEdit = veh != null;
    if (!isEdit) {
      final check = await LicenseManager.canAddVehicle();
      if (!check['allowed']) {
        if (mounted) showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Row(children: [Icon(Icons.lock, color: Colors.red, size: 28), SizedBox(width: 8), Text('محدودیت پلن', style: TextStyle(color: Colors.red))]), content: Text(check['message'] ?? '', style: const TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متوجه شدم', style: TextStyle(color: AppTheme.gold)))])));
        return;
      }
    }
    
    final plateController = TextEditingController(text: veh?['plate_number']?.toString() ?? '');
    final brandController = TextEditingController(text: veh?['brand']?.toString() ?? '');
    final modelController = TextEditingController(text: veh?['model']?.toString() ?? '');
    final mileageController = TextEditingController(text: (veh?['current_mileage'] ?? 0).toString());
    final notesController = TextEditingController(text: veh?['notes']?.toString() ?? '');
    Map<String, dynamic>? selectedCustomer;
    if (veh?['customer_id'] != null) {
      final match = _customers.where((c) => c['id'] == veh!['customer_id']).toList();
      if (match.isNotEmpty) selectedCustomer = match.first;
    }

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش خودرو' : 'افزودن خودرو', style: const TextStyle(color: AppTheme.gold)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  children: [
                    const Expanded(child: Text('مالک خودرو:', style: TextStyle(color: AppTheme.textGrey, fontSize: 13))),
                    TextButton.icon(
                      onPressed: () async {
                        await _addQuickCustomer((newCustomer) {
                          setStateDialog(() { selectedCustomer = newCustomer; });
                        });
                      },
                      icon: const Icon(Icons.person_add, color: AppTheme.gold, size: 18),
                      label: const Text('مشتری جدید', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // حل مورد ۴: استفاده از لیست قابل جستجو به جای Dropdown معمولی
                InkWell(
                  onTap: () async {
                    final selected = await _showSearchableCustomerList();
                    if (selected != null) {
                      setStateDialog(() => selectedCustomer = selected);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF444444))),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppTheme.gold),
                        const SizedBox(width: 8),
                        Expanded(child: Text(selectedCustomer != null ? '${selectedCustomer!['name']} - ${selectedCustomer!['phone']}' : 'انتخاب مالک (کلیک کنید)', style: TextStyle(color: selectedCustomer != null ? AppTheme.textWhite : AppTheme.textGrey))),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.gold),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: plateController, textCapitalization: TextCapitalization.characters, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'شماره پلاک *', prefixIcon: Icon(Icons.directions_car, color: AppTheme.gold))),
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
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                onPressed: () async {
                  if (plateController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شماره پلاک الزامی است'), backgroundColor: Colors.red)); return; }
                  final vehData = {'plate_number': plateController.text.trim().toUpperCase(), 'brand': brandController.text.trim(), 'model': modelController.text.trim(), 'customer_id': selectedCustomer?['id'], 'current_mileage': int.tryParse(toEnglishDigits(mileageController.text)) ?? 0, 'notes': notesController.text.trim()};
                  if (isEdit) { await DatabaseHelper.instance.updateVehicle(veh!['id'], vehData); } 
                  else { await DatabaseHelper.instance.insertVehicle(vehData); }
                  Navigator.pop(ctx);
                  _loadData();
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteVehicle(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) { await DatabaseHelper.instance.deleteVehicle(id); _loadData(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت خودروها'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadData),
        IconButton(icon: const Icon(Icons.people, color: AppTheme.gold), onPressed: () async { await _addQuickCustomer((_) {}); }, tooltip: 'افزودن مشتری'),
      ]),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _searchController, textCapitalization: TextCapitalization.characters, style: const TextStyle(color: AppTheme.textWhite), decoration: InputDecoration(hintText: 'جستجو بر اساس پلاک، برند یا نام مشتری...', prefixIcon: const Icon(Icons.search, color: AppTheme.gold), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterVehicles(''); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: _filterVehicles)),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _filteredVehicles.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.directions_car, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('خودرویی یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: _filteredVehicles.length,
              itemBuilder: (context, index) {
                final v = _filteredVehicles[index];
                return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
                  leading: CircleAvatar(backgroundColor: AppTheme.oilBlue.withOpacity(0.2), child: const Icon(Icons.directions_car, color: AppTheme.oilBlue)),
                  title: Text(v['plate_number'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 16)),
                  subtitle: Text('${v['brand'] ?? ''} ${v['model'] ?? ''} | ${formatNumber(v['current_mileage'] ?? 0)} کیلومتر\nمالک: ${v['customer_name'] ?? 'ثبت نشده'}', style: const TextStyle(color: AppTheme.textGrey)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showVehicleDialog(veh: v)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteVehicle(v['id'])),
                  ]),
                ));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showVehicleDialog(), backgroundColor: AppTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن خودرو')),
    );
  }
}