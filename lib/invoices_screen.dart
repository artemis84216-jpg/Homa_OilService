import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:convert';
import 'database_helper.dart';
import 'app_utils.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllInvoices();
    setState(() { _invoices = data; _isLoading = false; });
  }

  Future<void> _createNewInvoice() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
    if (result == true) _loadInvoices();
  }

  Future<void> _deleteInvoice(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) {
      await DatabaseHelper.instance.deleteInvoice(id);
      _loadInvoices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('فاکتورها'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadInvoices)]),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _invoices.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('هنوز فاکتوری ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _invoices.length,
        itemBuilder: (context, index) {
          final inv = _invoices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold)), child: Text('شماره: ${inv['invoice_number']}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12))),
                  const Spacer(),
                  Text(inv['invoice_date'] ?? '', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.directions_car, size: 16, color: AppTheme.oilBlue),
                  const SizedBox(width: 4),
                  Text('${inv['plate_number'] ?? 'نامشخص'} | ${inv['brand'] ?? ''} ${inv['model'] ?? ''}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.person, size: 16, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text('مشتری: ${inv['customer_name'] ?? 'نامشخص'}', style: const TextStyle(color: AppTheme.textGrey)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.engineering, size: 16, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text('تکنسین: ${inv['employee_name'] ?? 'نامشخص'}', style: const TextStyle(color: AppTheme.textGrey)),
                ]),
                const Divider(color: AppTheme.gold, height: 20),
                Row(children: [
                  const Icon(Icons.attach_money, size: 20, color: AppTheme.gold),
                  const SizedBox(width: 8),
                  Text('مبلغ کل: ${formatPrice(inv['total'])} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteInvoice(inv['id'])),
                ]),
              ]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _createNewInvoice, backgroundColor: AppTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('فاکتور جدید')),
    );
  }
}

// ===== صفحه ساخت فاکتور =====
class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _services = [];
  
  Map<String, dynamic>? _selectedVehicle;
  Map<String, dynamic>? _selectedEmployee;
  Jalali _invoiceDate = Jalali.now();
  final _mileageController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  
  List<Map<String, dynamic>> _invoiceItems = []; // {type: 'product'|'service', id, name, price, quantity}
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final vehicles = await DatabaseHelper.instance.getAllVehicles();
    final employees = await DatabaseHelper.instance.getAllEmployees();
    final products = await DatabaseHelper.instance.getAllProducts();
    final services = await DatabaseHelper.instance.getAllServices();
    setState(() {
      _vehicles = vehicles;
      _employees = employees.where((e) => e['status'] == 'active').toList();
      _products = products;
      _services = services;
      _isLoading = false;
    });
  }

  void _addProductItem(Map<String, dynamic> product) {
    final existing = _invoiceItems.where((i) => i['type'] == 'product' && i['id'] == product['id']).toList();
    if (existing.isNotEmpty) {
      final idx = _invoiceItems.indexOf(existing.first);
      setState(() => _invoiceItems[idx]['quantity']++);
    } else {
      setState(() => _invoiceItems.add({
        'type': 'product',
        'id': product['id'],
        'name': '${product['name']} ${product['viscosity'] ?? ''} ${product['volume'] ?? ''}',
        'price': (product['sell_price'] ?? 0).toDouble(),
        'quantity': 1,
      }));
    }
  }

  void _addServiceItem(Map<String, dynamic> service) {
    final exists = _invoiceItems.any((i) => i['type'] == 'service' && i['id'] == service['id']);
    if (!exists) {
      setState(() => _invoiceItems.add({
        'type': 'service',
        'id': service['id'],
        'name': service['name'],
        'price': (service['price'] ?? 0).toDouble(),
        'quantity': 1,
      }));
    }
  }

  void _removeItem(int index) {
    setState(() => _invoiceItems.removeAt(index));
  }

  void _updateQuantity(int index, int newQty) {
    if (newQty < 1) return;
    setState(() => _invoiceItems[index]['quantity'] = newQty);
  }

  double get _subtotal {
    return _invoiceItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  double get _discount {
    return double.tryParse(toEnglishDigits(_discountController.text)) ?? 0;
  }

  double get _total {
    return _subtotal - _discount;
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(6)}';
  }

  Future<void> _saveInvoice() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خودرو را انتخاب کنید'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تکنسین را انتخاب کنید'), backgroundColor: Colors.red));
      return;
    }
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک کالا یا خدمت اضافه کنید'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final invoiceNumber = _generateInvoiceNumber();
      final dateStr = '${_invoiceDate.year}/${_invoiceDate.month.toString().padLeft(2, '0')}/${_invoiceDate.day.toString().padLeft(2, '0')}';
      
      // ثبت فاکتور
      await DatabaseHelper.instance.insertInvoice({
        'invoice_number': invoiceNumber,
        'vehicle_id': _selectedVehicle!['id'],
        'customer_id': _selectedVehicle!['customer_id'],
        'employee_id': _selectedEmployee!['id'],
        'invoice_date': dateStr,
        'mileage_at_service': int.tryParse(toEnglishDigits(_mileageController.text)) ?? 0,
        'items_json': jsonEncode(_invoiceItems),
        'subtotal': _subtotal,
        'discount': _discount,
        'total': _total,
        'payment_method': 'cash',
        'status': 'paid',
        'notes': _notesController.text.trim(),
      });

      // کاهش موجودی کالاها
      for (final item in _invoiceItems) {
        if (item['type'] == 'product') {
          final product = _products.firstWhere((p) => p['id'] == item['id']);
          final newStock = (product['stock_quantity'] ?? 0) - item['quantity'];
          await DatabaseHelper.instance.updateProductStock(item['id'], newStock < 0 ? 0 : newStock);
        }
      }

      // به‌روزرسانی کیلومتر خودرو
      final mileage = int.tryParse(toEnglishDigits(_mileageController.text)) ?? 0;
      if (mileage > 0) {
        await DatabaseHelper.instance.updateVehicle(_selectedVehicle!['id'], {
          'current_mileage': mileage,
          'last_service_date': dateStr,
          'last_service_mileage': mileage,
        });
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ فاکتور $invoiceNumber ثبت شد'), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('فاکتور جدید'), centerTitle: true),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // انتخاب خودرو
            const Text('۱. خودرو', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedVehicle,
              dropdownColor: AppTheme.cardBlack,
              decoration: const InputDecoration(labelText: 'انتخاب خودرو', prefixIcon: Icon(Icons.directions_car, color: AppTheme.gold)),
              items: _vehicles.map((v) => DropdownMenuItem<Map<String, dynamic>>(
                value: v,
                child: Text('${v['plate_number']} - ${v['brand'] ?? ''} ${v['model'] ?? ''}', style: const TextStyle(color: AppTheme.textWhite)),
              )).toList(),
              onChanged: (val) => setState(() => _selectedVehicle = val),
            ),
            const SizedBox(height: 16),
            
            // کیلومتر
            TextField(
              controller: _mileageController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: const InputDecoration(labelText: 'کیلومتر فعلی خودرو', prefixIcon: Icon(Icons.speed, color: AppTheme.gold)),
            ),
            const SizedBox(height: 16),
            
            // انتخاب تکنسین
            const Text('۲. تکنسین', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedEmployee,
              dropdownColor: AppTheme.cardBlack,
              decoration: const InputDecoration(labelText: 'انتخاب تکنسین', prefixIcon: Icon(Icons.engineering, color: AppTheme.gold)),
              items: _employees.map((e) => DropdownMenuItem<Map<String, dynamic>>(
                value: e,
                child: Text(e['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite)),
              )).toList(),
              onChanged: (val) => setState(() => _selectedEmployee = val),
            ),
            const SizedBox(height: 16),
            
            // تاریخ
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showPersianDatePicker(context: context, initialDate: _invoiceDate, firstDate: Jalali(1400), lastDate: Jalali(1450));
                if (picked != null) setState(() => _invoiceDate = picked);
              },
              icon: const Icon(Icons.calendar_today, color: AppTheme.gold),
              label: Text('${_invoiceDate.year}/${_invoiceDate.month.toString().padLeft(2, '0')}/${_invoiceDate.day.toString().padLeft(2, '0')}', style: const TextStyle(color: AppTheme.textWhite)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gold)),
            ),
            const SizedBox(height: 24),
            
            // افزودن کالا
            const Text('۳. کالاها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _products.map((p) {
                return ActionChip(
                  label: Text('${p['name']} (${formatNumber(p['stock_quantity'] ?? 0)})', style: const TextStyle(color: AppTheme.textWhite, fontSize: 12)),
                  backgroundColor: AppTheme.cardBlack,
                  side: const BorderSide(color: AppTheme.gold),
                  onPressed: () => _addProductItem(p),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // افزودن خدمت
            const Text('۴. خدمات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _services.map((s) {
                return ActionChip(
                  label: Text('${s['name']} (${formatPrice(s['price'])})', style: const TextStyle(color: AppTheme.textWhite, fontSize: 12)),
                  backgroundColor: AppTheme.cardBlack,
                  side: const BorderSide(color: AppTheme.oilBlue),
                  onPressed: () => _addServiceItem(s),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // لیست آیتم‌های فاکتور
            if (_invoiceItems.isNotEmpty) ...[
              const Text('۵. آیتم‌های فاکتور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
              const SizedBox(height: 8),
              ..._invoiceItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item['name'], style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${formatPrice(item['price'])} × ${toPersianDigits(item['quantity'].toString())} = ${formatPrice(item['price'] * item['quantity'])} تومان', style: const TextStyle(color: AppTheme.textYellow)),
                        ]),
                      ),
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.gold), onPressed: () => _updateQuantity(idx, item['quantity'] - 1)),
                      Text(toPersianDigits(item['quantity'].toString()), style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.gold), onPressed: () => _updateQuantity(idx, item['quantity'] + 1)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeItem(idx)),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 16),
              
              // تخفیف
              TextField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(labelText: 'تخفیف (تومان)', prefixIcon: Icon(Icons.discount, color: AppTheme.gold)),
              ),
              const SizedBox(height: 16),
              
              // یادداشت
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(labelText: 'یادداشت', prefixIcon: Icon(Icons.notes, color: AppTheme.gold)),
              ),
              const SizedBox(height: 16),
              
              // جمع کل
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.gold, width: 2)),
                child: Column(children: [
                  Row(children: [const Text('جمع کل:', style: TextStyle(color: AppTheme.textGrey)), const Spacer(), Text('${formatPrice(_subtotal)} تومان', style: const TextStyle(color: AppTheme.textWhite))]),
                  const SizedBox(height: 8),
                  Row(children: [const Text('تخفیف:', style: TextStyle(color: AppTheme.textGrey)), const Spacer(), Text('${formatPrice(_discount)} تومان', style: const TextStyle(color: Colors.red))]),
                  const Divider(color: AppTheme.gold, height: 20),
                  Row(children: [const Text('مبلغ نهایی:', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 18)), const Spacer(), Text('${formatPrice(_total)} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold, fontSize: 20))]),
                ]),
              ),
              const SizedBox(height: 24),
              
              // دکمه ثبت
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveInvoice,
                  icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.check_circle, size: 24),
                  label: Text(_isSaving ? 'در حال ثبت...' : 'ثبت فاکتور', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.gold.withOpacity(0.3))),
                child: const Center(child: Text('از بخش کالاها و خدمات بالا، آیتم‌ها را اضافه کنید', style: TextStyle(color: AppTheme.textGrey))),
              ),
          ]),
        ),
      ),
    );
  }
}