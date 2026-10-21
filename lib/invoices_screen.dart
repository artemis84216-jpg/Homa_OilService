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
  List<Map<String, dynamic>> _filteredInvoices = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllInvoices();
    setState(() {
      _invoices = data;
      _filteredInvoices = data;
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ لیست فاکتورها بروزرسانی شد'), backgroundColor: AppTheme.gold),
      );
    }
  }

  void _filterInvoices(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredInvoices = List.from(_invoices);
      } else {
        _filteredInvoices = _invoices.where((inv) {
          return (inv['invoice_number'] ?? '').toString().toLowerCase().contains(q) ||
              (inv['plate_number'] ?? '').toString().toLowerCase().contains(q) ||
              (inv['customer_name'] ?? '').toString().toLowerCase().contains(q) ||
              (inv['brand'] ?? '').toString().toLowerCase().contains(q) ||
              (inv['employee_name'] ?? '').toString().toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _showInvoiceItems(Map<String, dynamic> inv) {
    List<dynamic> items = [];
    try {
      items = jsonDecode(inv['items_json'] ?? '[]');
    } catch (e) {}

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: Text('اقلام فاکتور ${inv['invoice_number']}', style: const TextStyle(color: AppTheme.gold)),
          content: SizedBox(
            width: double.maxFinite,
            child: items.isEmpty
                ? const Text('موردی یافت نشد', style: TextStyle(color: AppTheme.textGrey))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: Icon(item['type'] == 'product' ? Icons.inventory_2 : Icons.build, color: AppTheme.gold),
                        title: Text(item['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite)),
                        trailing: Text('${formatPrice((item['price'] * item['quantity']).toInt())} تومان', style: const TextStyle(color: AppTheme.textYellow)),
                        subtitle: Text('${formatPrice(item['price'].toInt())} × ${toPersianDigits(item['quantity'].toString())}', style: const TextStyle(color: AppTheme.textGrey)),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('بستن', style: TextStyle(color: AppTheme.gold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteInvoice(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)),
          content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteInvoice(id);
      _loadInvoices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('فاکتورها'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadInvoices),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'جستجو بر اساس شماره فاکتور، پلاک یا نام مشتری...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.gold),
                        onPressed: () {
                          _searchController.clear();
                          _filterInvoices('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filterInvoices,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _filteredInvoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 80, color: AppTheme.textGrey),
                            const SizedBox(height: 16),
                            Text('فاکتوری یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final inv = _filteredInvoices[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showInvoiceItems(inv),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.gold.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppTheme.gold),
                                          ),
                                          child: Text('شماره: ${inv['invoice_number']}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        const Spacer(),
                                        Text(inv['invoice_date'] ?? '', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_car, size: 16, color: AppTheme.oilBlue),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${inv['plate_number'] ?? 'نامشخص'} | ${inv['brand'] ?? ''} ${inv['model'] ?? ''}',
                                            style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: AppTheme.textGrey),
                                        const SizedBox(width: 4),
                                        Text('مشتری: ${inv['customer_name'] ?? 'نامشخص'}', style: const TextStyle(color: AppTheme.textGrey)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.engineering, size: 16, color: AppTheme.textGrey),
                                        const SizedBox(width: 4),
                                        Text('تکنسین: ${inv['employee_name'] ?? 'نامشخص'}', style: const TextStyle(color: AppTheme.textGrey)),
                                      ],
                                    ),
                                    const Divider(color: AppTheme.gold, height: 20),
                                    Row(
                                      children: [
                                        const Icon(Icons.attach_money, size: 20, color: AppTheme.gold),
                                        const SizedBox(width: 8),
                                        Text('مبلغ کل: ${formatPrice(inv['total'])} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold, fontSize: 16)),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteInvoice(inv['id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
          if (result == true) _loadInvoices();
        },
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('فاکتور جدید'),
      ),
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
  final _nextMileageController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _invoiceItems = [];
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

  // جستجوی خودرو با Bottom Sheet
  Future<Map<String, dynamic>?> _showSearchableVehicleList() async {
    List<Map<String, dynamic>> filtered = List.from(_vehicles);
    final screenHeight = MediaQuery.of(context).size.height;

    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppTheme.cardBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SizedBox(
          height: screenHeight * 0.75,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text('انتخاب خودرو', style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      hintText: 'جستجوی پلاک، برند یا نام مالک...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      final q = val.toLowerCase();
                      setModalState(() {
                        filtered = _vehicles.where((v) {
                          return (v['plate_number'] ?? '').toString().toLowerCase().contains(q) ||
                              (v['brand'] ?? '').toString().toLowerCase().contains(q) ||
                              (v['model'] ?? '').toString().toLowerCase().contains(q) ||
                              (v['customer_name'] ?? '').toString().toLowerCase().contains(q);
                        }).toList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('خودرویی یافت نشد', style: TextStyle(color: AppTheme.textGrey)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final v = filtered[index];
                            return ListTile(
                              leading: const CircleAvatar(backgroundColor: AppTheme.oilBlue, child: Icon(Icons.directions_car, color: Colors.white)),
                              title: Text(v['plate_number'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: Text('${v['brand'] ?? ''} ${v['model'] ?? ''} - ${v['customer_name'] ?? 'بدون مالک'}', style: const TextStyle(color: AppTheme.textGrey)),
                              onTap: () => Navigator.pop(ctx, v),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  double get _subtotal => _invoiceItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get _discount => double.tryParse(toEnglishDigits(_discountController.text.replaceAll(',', ''))) ?? 0.0;
  double get _total => _subtotal - _discount;

  Future<void> _saveInvoice() async {
    if (_selectedVehicle == null || _selectedEmployee == null || _invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً خودرو، تکنسین و حداقل یک آیتم را انتخاب کنید'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final invoiceNumber = await generateDailyInvoiceNumber();
      final dateStr = '${_invoiceDate.year}/${_invoiceDate.month.toString().padLeft(2, '0')}/${_invoiceDate.day.toString().padLeft(2, '0')}';
      final currentMileage = int.tryParse(toEnglishDigits(_mileageController.text)) ?? 0;
      final nextMileage = int.tryParse(toEnglishDigits(_nextMileageController.text)) ?? 0;

      await DatabaseHelper.instance.insertInvoice({
        'invoice_number': invoiceNumber,
        'vehicle_id': _selectedVehicle!['id'],
        'customer_id': _selectedVehicle!['customer_id'],
        'employee_id': _selectedEmployee!['id'],
        'invoice_date': dateStr,
        'mileage_at_service': currentMileage,
        'items_json': jsonEncode(_invoiceItems),
        'subtotal': _subtotal,
        'discount': _discount,
        'total': _total,
        'payment_method': 'cash',
        'status': 'paid',
        'notes': _notesController.text.trim(),
      });

      for (final item in _invoiceItems) {
        if (item['type'] == 'product') {
          final product = _products.firstWhere((p) => p['id'] == item['id']);
          final newStock = (product['stock_quantity'] ?? 0) - item['quantity'];
          await DatabaseHelper.instance.updateProductStock(item['id'], newStock < 0 ? 0 : newStock);
        }
      }

      if (currentMileage > 0) {
        await DatabaseHelper.instance.updateVehicle(_selectedVehicle!['id'], {
          'current_mileage': currentMileage,
          'last_service_date': dateStr,
          'last_service_mileage': currentMileage,
        });
      }

      final hasOilService = _invoiceItems.any((i) => i['name'].toString().contains('روغن') || i['name'].toString().contains('فیلتر'));
      if (hasOilService) {
        final oilItem = _invoiceItems.firstWhere((i) => i['name'].toString().contains('روغن'), orElse: () => {'name': 'سرویس دوره'});
        await DatabaseHelper.instance.insertServiceHistory({
          'vehicle_id': _selectedVehicle!['id'],
          'invoice_id': null,
          'service_type': 'تعویض روغن و سرویس',
          'oil_brand': oilItem['name'] ?? 'نامشخص',
          'oil_viscosity': '',
          'oil_volume': 0.0,
          'mileage': currentMileage,
          'next_service_mileage': nextMileage > 0 ? nextMileage : null,
          'next_service_date': null,
          'technician_notes': _notesController.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ثبت: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('فاکتور جدید'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('۱. خودرو', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final selected = await _showSearchableVehicleList();
                        if (selected != null) {
                          setState(() => _selectedVehicle = selected);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF444444)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car, color: AppTheme.gold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedVehicle != null
                                    ? '${_selectedVehicle!['plate_number']} - ${_selectedVehicle!['brand'] ?? ''} ${_selectedVehicle!['model'] ?? ''}'
                                    : 'انتخاب خودرو (کلیک کنید)',
                                style: TextStyle(color: _selectedVehicle != null ? AppTheme.textWhite : AppTheme.textGrey),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppTheme.gold),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedVehicle != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.gold, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('پلاک: ${_selectedVehicle!['plate_number']}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('مالک: ${_selectedVehicle!['customer_name'] ?? 'ثبت نشده'}', style: const TextStyle(color: AppTheme.textGrey)),
                            Text('کیلومتر فعلی: ${formatNumber((_selectedVehicle!['current_mileage'] ?? 0).toInt())}', style: const TextStyle(color: AppTheme.textGrey)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _mileageController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'کیلومتر فعلی', prefixIcon: Icon(Icons.speed, color: AppTheme.gold)))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _nextMileageController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'کیلومتر سرویس بعدی', prefixIcon: Icon(Icons.next_plan, color: AppTheme.gold)))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('۲. تکنسین', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedEmployee,
                      dropdownColor: AppTheme.cardBlack,
                      decoration: const InputDecoration(labelText: 'انتخاب تکنسین', prefixIcon: Icon(Icons.engineering, color: AppTheme.gold)),
                      items: _employees.map((e) => DropdownMenuItem<Map<String, dynamic>>(value: e, child: Text(e['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite)))).toList(),
                      onChanged: (val) => setState(() => _selectedEmployee = val),
                    ),
                    const SizedBox(height: 16),
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
                    const Text('۳. کالاها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _products.map((p) => ActionChip(
                        label: Text('${p['name']} (${formatNumber((p['stock_quantity'] ?? 0).toInt())})', style: const TextStyle(color: AppTheme.textWhite, fontSize: 12)),
                        backgroundColor: AppTheme.cardBlack,
                        side: const BorderSide(color: AppTheme.gold),
                        onPressed: () => _addProductItem(p),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('۴. خدمات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _services.map((s) => ActionChip(
                        label: Text('${s['name']} (${formatPrice(s['price'])})', style: const TextStyle(color: AppTheme.textWhite, fontSize: 12)),
                        backgroundColor: AppTheme.cardBlack,
                        side: const BorderSide(color: AppTheme.oilBlue),
                        onPressed: () => _addServiceItem(s),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
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
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'], style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('${formatPrice(item['price'].toInt())} × ${toPersianDigits(item['quantity'].toString())} = ${formatPrice((item['price'] * item['quantity']).toInt())} تومان', style: const TextStyle(color: AppTheme.textYellow)),
                                    ],
                                  ),
                                ),
                                IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.gold), onPressed: () => _updateQuantity(idx, item['quantity'] - 1)),
                                Text(toPersianDigits(item['quantity'].toString()), style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.gold), onPressed: () => _updateQuantity(idx, item['quantity'] + 1)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeItem(idx)),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CommaSeparatorFormatter()],
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'تخفیف (تومان)', prefixIcon: Icon(Icons.discount, color: AppTheme.gold)),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'یادداشت', prefixIcon: Icon(Icons.notes, color: AppTheme.gold)),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.gold, width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(children: [const Text('جمع کل:', style: TextStyle(color: AppTheme.textGrey)), const Spacer(), Text('${formatPrice(_subtotal.toInt())} تومان', style: const TextStyle(color: AppTheme.textWhite))]),
                            const SizedBox(height: 8),
                            Row(children: [const Text('تخفیف:', style: TextStyle(color: AppTheme.textGrey)), const Spacer(), Text('${formatPrice(_discount.toInt())} تومان', style: const TextStyle(color: Colors.red))]),
                            const Divider(color: AppTheme.gold, height: 20),
                            Row(children: [const Text('مبلغ نهایی:', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 18)), const Spacer(), Text('${formatPrice(_total.toInt())} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold, fontSize: 20))]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                          onPressed: _isSaving ? null : _saveInvoice,
                          icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.check_circle, size: 24),
                          label: Text(_isSaving ? 'در حال ثبت...' : 'ثبت فاکتور', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                        ),
                        child: const Center(child: Text('از بخش کالاها و خدمات بالا، آیتم‌ها را اضافه کنید', style: TextStyle(color: AppTheme.textGrey))),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}