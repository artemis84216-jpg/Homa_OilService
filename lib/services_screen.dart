import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllServices();
    setState(() { _services = data; _isLoading = false; });
  }

  Future<void> _showServiceDialog({Map<String, dynamic>? srv}) async {
    final isEdit = srv != null;
    final nameController = TextEditingController(text: srv?['name']?.toString() ?? '');
    final priceController = TextEditingController(text: srv?['price']?.toString() ?? '0');
    final descController = TextEditingController(text: srv?['description']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: Text(isEdit ? 'ویرایش خدمت' : 'افزودن خدمت', style: const TextStyle(color: AppTheme.gold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام خدمت (مثال: تعویض روغن موتور)', prefixIcon: Icon(Icons.build, color: AppTheme.gold))),
              const SizedBox(height: 12),
              TextField(controller: priceController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'دستمزد خدمت (تومان)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold))),
              const SizedBox(height: 12),
              TextField(controller: descController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'توضیحات', prefixIcon: Icon(Icons.notes, color: AppTheme.gold))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام خدمت الزامی است')));
                  return;
                }
                final srvData = {'name': nameController.text.trim(), 'price': double.tryParse(priceController.text) ?? 0, 'description': descController.text.trim(), 'is_active': 1};
                if (isEdit) {
                  await DatabaseHelper.instance.updateService(srv!['id'], srvData);
                } else {
                  await DatabaseHelper.instance.insertService(srvData);
                }
                Navigator.pop(ctx);
                _loadServices();
              },
              child: Text(isEdit ? 'ذخیره' : 'افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteService(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) {
      await DatabaseHelper.instance.deleteService(id);
      _loadServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت خدمات'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadServices)]),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _services.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.build, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('هنوز خدمتی ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final s = _services[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: AppTheme.oilBlue.withOpacity(0.2), child: const Icon(Icons.build, color: AppTheme.oilBlue)),
              title: Text(s['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
              subtitle: Text('دستمزد: ${formatPrice(s['price'])} تومان\n${s['description'] ?? ''}', style: const TextStyle(color: AppTheme.textGrey)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showServiceDialog(srv: s)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(s['id'])),
              ]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showServiceDialog(), backgroundColor: AppTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن خدمت')),
    );
  }
}