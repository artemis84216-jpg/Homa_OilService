import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllCustomers();
    setState(() { 
      _customers = data; 
      _filteredCustomers = data;
      _isLoading = false; 
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) { _filteredCustomers = _customers; }
      else { 
        _filteredCustomers = _customers.where((c) => 
          (c['name'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) ||
          (c['phone'] ?? '').toString().contains(query) ||
          (c['national_id'] ?? '').toString().contains(query)
        ).toList(); 
      }
    });
  }

  Future<void> _showCustomerDialog({Map<String, dynamic>? cust}) async {
    final isEdit = cust != null;
    final nameController = TextEditingController(text: cust?['name']?.toString() ?? '');
    final phoneController = TextEditingController(text: cust?['phone']?.toString() ?? '');
    final nationalIdController = TextEditingController(text: cust?['national_id']?.toString() ?? '');
    final addressController = TextEditingController(text: cust?['address']?.toString() ?? '');
    final notesController = TextEditingController(text: cust?['notes']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: Text(isEdit ? 'ویرایش مشتری' : 'افزودن مشتری', style: const TextStyle(color: AppTheme.gold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام و نام خانوادگی *', prefixIcon: Icon(Icons.person, color: AppTheme.gold))),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شماره تماس *', prefixIcon: Icon(Icons.phone, color: AppTheme.gold))),
              const SizedBox(height: 12),
              TextField(controller: nationalIdController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'کد ملی', prefixIcon: Icon(Icons.badge, color: AppTheme.gold))),
              const SizedBox(height: 12),
              TextField(controller: addressController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'آدرس', prefixIcon: Icon(Icons.location_on, color: AppTheme.gold))),
              const SizedBox(height: 12),
              TextField(controller: notesController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'یادداشت', prefixIcon: Icon(Icons.notes, color: AppTheme.gold))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام و شماره تماس الزامی است'), backgroundColor: Colors.red));
                  return;
                }
                final custData = {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'national_id': nationalIdController.text.trim(),
                  'address': addressController.text.trim(),
                  'notes': notesController.text.trim(),
                };
                if (isEdit) {
                  await DatabaseHelper.instance.updateCustomer(cust!['id'], custData);
                } else {
                  await DatabaseHelper.instance.insertCustomer(custData);
                }
                Navigator.pop(ctx);
                _loadCustomers();
              },
              child: Text(isEdit ? 'ذخیره' : 'افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCustomer(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) {
      await DatabaseHelper.instance.deleteCustomer(id);
      _loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت مشتریان'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadCustomers)]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'جستجو در نام، شماره تماس یا کد ملی...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterCustomers(''); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filterCustomers,
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _filteredCustomers.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('مشتری‌ای یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredCustomers.length,
              itemBuilder: (context, index) {
                final c = _filteredCustomers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppTheme.gold.withOpacity(0.2), child: const Icon(Icons.person, color: AppTheme.gold)),
                    title: Text(c['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                    subtitle: Text('${c['phone'] ?? ''} | کد ملی: ${c['national_id'] ?? 'ثبت نشده'}\n${c['address'] ?? ''}', style: const TextStyle(color: AppTheme.textGrey)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showCustomerDialog(cust: c)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCustomer(c['id'])),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showCustomerDialog(), backgroundColor: AppTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن مشتری')),
    );
  }
}