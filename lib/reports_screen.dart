import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:convert';
import 'database_helper.dart';
import 'app_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Jalali? _startDate;
  Jalali? _endDate;
  String _reportType = 'all';
  List<String> _categories = [];
  String _selectedCategory = 'همه';

  double _totalSales = 0;
  double _totalProductSales = 0;
  double _totalServiceSales = 0;
  double _totalExpenses = 0;
  double _totalSalaries = 0;
  int _invoicesCount = 0;
  int _productsSoldCount = 0;
  int _servicesCount = 0;
  Map<String, double> _topProducts = {};
  Map<String, double> _topServices = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadReports();
  }

  Future<void> _loadCategories() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    final cats = products.map((p) => p['category']?.toString() ?? '').where((c) => c.isNotEmpty).toSet().toList();
    setState(() => _categories = ['همه', ...cats]);
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    final startStr = _startDate != null ? '${_startDate!.year}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.day.toString().padLeft(2, '0')}' : null;
    final endStr = _endDate != null ? '${_endDate!.year}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.day.toString().padLeft(2, '0')}' : null;

    final invoices = startStr != null && endStr != null
        ? await DatabaseHelper.instance.getInvoicesByDateRange(startStr, endStr)
        : await DatabaseHelper.instance.getAllInvoices();

    _invoicesCount = invoices.length;
    _totalSales = 0;
    _totalProductSales = 0;
    _totalServiceSales = 0;
    _productsSoldCount = 0;
    _servicesCount = 0;
    _topProducts = {};
    _topServices = {};

    for (var inv in invoices) {
      _totalSales += (inv['total'] as num?)?.toDouble() ?? 0;
      try {
        final items = jsonDecode(inv['items_json'] ?? '[]');
        for (var item in items) {
          final type = item['type']?.toString() ?? '';
          final name = item['name']?.toString() ?? '';
          final price = (item['price'] as num?)?.toDouble() ?? 0;
          final qty = (item['quantity'] as num?)?.toInt() ?? 0;
          final total = price * qty;

          if (type == 'product') {
            _totalProductSales += total;
            _productsSoldCount += qty;
            _topProducts[name] = (_topProducts[name] ?? 0) + total;
          } else if (type == 'service') {
            _totalServiceSales += total;
            _servicesCount += qty;
            _topServices[name] = (_topServices[name] ?? 0) + total;
          }
        }
      } catch (e) {}
    }

    final expenses = await DatabaseHelper.instance.getExpenses(startDate: startStr, endDate: endStr);
    _totalExpenses = expenses.fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));

    final employees = await DatabaseHelper.instance.getAllEmployees();
    final activeEmployees = employees.where((e) => e['status'] == 'active').toList();
    _totalSalaries = activeEmployees.fold(0.0, (sum, e) => sum + ((e['base_salary'] as num?)?.toDouble() ?? 0.0));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ گزارشات بروزرسانی شد'), backgroundColor: AppTheme.gold),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('گزارشات مالی'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadReports),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // فیلتر بازه زمانی
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Row(children: [Icon(Icons.filter_alt, color: AppTheme.gold), SizedBox(width: 8), Text('فیلتر بازه زمانی', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))]),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final p = await showPersianDatePicker(context: context, initialDate: _startDate ?? Jalali.now(), firstDate: Jalali(1400), lastDate: Jalali(1450));
                                      if (p != null) { setState(() => _startDate = p); _loadReports(); }
                                    },
                                    icon: const Icon(Icons.calendar_today, color: AppTheme.gold),
                                    label: Text(_startDate != null ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}' : 'از تاریخ', style: const TextStyle(color: AppTheme.textWhite)),
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final p = await showPersianDatePicker(context: context, initialDate: _endDate ?? Jalali.now(), firstDate: Jalali(1400), lastDate: Jalali(1450));
                                      if (p != null) { setState(() => _endDate = p); _loadReports(); }
                                    },
                                    icon: const Icon(Icons.calendar_today, color: AppTheme.gold),
                                    label: Text(_endDate != null ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}' : 'تا تاریخ', style: const TextStyle(color: AppTheme.textWhite)),
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gold)),
                                  ),
                                ),
                              ],
                            ),
                            if (_startDate != null || _endDate != null) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () { setState(() { _startDate = null; _endDate = null; }); _loadReports(); },
                                child: const Text('حذف فیلتر', style: TextStyle(color: Colors.red)),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // فیلتر نوع گزارش
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [Icon(Icons.category, color: AppTheme.gold), SizedBox(width: 8), Text('نوع گزارش', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))]),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _reportType,
                              dropdownColor: AppTheme.cardBlack,
                              decoration: const InputDecoration(labelText: 'انتخاب نوع گزارش', prefixIcon: Icon(Icons.analytics, color: AppTheme.gold)),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('همه (جامع)')),
                                DropdownMenuItem(value: 'products', child: Text('فقط فروش کالاها')),
                                DropdownMenuItem(value: 'services', child: Text('فقط خدمات')),
                                DropdownMenuItem(value: 'salaries', child: Text('فقط حقوق کارمندان')),
                              ],
                              onChanged: (v) { setState(() => _reportType = v!); },
                            ),
                            if (_reportType == 'products') ...[
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                dropdownColor: AppTheme.cardBlack,
                                decoration: const InputDecoration(labelText: 'دسته‌بندی کالا', prefixIcon: Icon(Icons.category, color: AppTheme.gold)),
                                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (v) { setState(() => _selectedCategory = v!); },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // نمایش گزارش
                    if (_reportType == 'all') _buildFullReport(),
                    if (_reportType == 'products') _buildProductsReport(),
                    if (_reportType == 'services') _buildServicesReport(),
                    if (_reportType == 'salaries') _buildSalariesReport(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFullReport() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.bar_chart, color: AppTheme.gold, size: 28), SizedBox(width: 8), Text('گزارش جامع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold))]),
            const Divider(height: 24),
            _buildStatRow('تعداد فاکتورها', '${toPersianDigits(_invoicesCount.toString())} فاکتور', AppTheme.textWhite),
            _buildStatRow('کل فروش', '${formatPrice(_totalSales.toInt())} تومان', Colors.green),
            _buildStatRow('  - فروش کالاها', '${formatPrice(_totalProductSales.toInt())} تومان', AppTheme.textYellow),
            _buildStatRow('  - خدمات', '${formatPrice(_totalServiceSales.toInt())} تومان', AppTheme.oilBlue),
            _buildStatRow('کل هزینه‌ها', '${formatPrice(_totalExpenses.toInt())} تومان', Colors.red),
            _buildStatRow('کل حقوق کارمندان', '${formatPrice(_totalSalaries.toInt())} تومان', Colors.orange),
            const Divider(height: 16),
            _buildStatRow('سود خالص', '${formatPrice((_totalSales - _totalExpenses - _totalSalaries).toInt())} تومان', _totalSales - _totalExpenses - _totalSalaries >= 0 ? Colors.green : Colors.red, isLarge: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsReport() {
    final sortedProducts = _topProducts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.inventory_2, color: AppTheme.gold, size: 28), SizedBox(width: 8), Text('گزارش فروش کالاها', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold))]),
            const Divider(height: 24),
            _buildStatRow('مجموع فروش کالاها', '${formatPrice(_totalProductSales.toInt())} تومان', Colors.green, isLarge: true),
            _buildStatRow('تعداد کالای فروش رفته', '${toPersianDigits(_productsSoldCount.toString())} عدد', AppTheme.textWhite),
            const SizedBox(height: 16),
            const Text('پرفروش‌ترین کالاها:', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (sortedProducts.isEmpty) const Text('کالایی فروش نرفته است', style: TextStyle(color: AppTheme.textGrey)),
            ...sortedProducts.take(10).map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(e.key, style: const TextStyle(color: AppTheme.textWhite))),
                  Text('${formatPrice(e.value.toInt())} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesReport() {
    final sortedServices = _topServices.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.build, color: AppTheme.gold, size: 28), SizedBox(width: 8), Text('گزارش خدمات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold))]),
            const Divider(height: 24),
            _buildStatRow('مجموع درآمد خدمات', '${formatPrice(_totalServiceSales.toInt())} تومان', Colors.green, isLarge: true),
            _buildStatRow('تعداد خدمات ارائه شده', '${toPersianDigits(_servicesCount.toString())}', AppTheme.textWhite),
            const SizedBox(height: 16),
            const Text('پرفروش‌ترین خدمات:', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (sortedServices.isEmpty) const Text('خدمتی ارائه نشده است', style: TextStyle(color: AppTheme.textGrey)),
            ...sortedServices.take(10).map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(e.key, style: const TextStyle(color: AppTheme.textWhite))),
                  Text('${formatPrice(e.value.toInt())} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSalariesReport() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getAllEmployees(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
        final employees = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.people, color: AppTheme.gold, size: 28), SizedBox(width: 8), Text('گزارش حقوق کارمندان', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold))]),
                const Divider(height: 24),
                _buildStatRow('مجموع حقوق ماهانه', '${formatPrice(_totalSalaries.toInt())} تومان', Colors.orange, isLarge: true),
                _buildStatRow('تعداد کارمندان فعال', '${toPersianDigits(employees.where((e) => e['status'] == 'active').length.toString())} نفر', AppTheme.textWhite),
                const SizedBox(height: 16),
                const Text('جزئیات حقوق:', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...employees.where((e) => e['status'] == 'active').map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(e['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite))),
                      Text('${formatPrice(((e['base_salary'] ?? 0) as num).toInt())} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, Color color, {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isLarge ? 18 : 16, color: AppTheme.textGrey)),
          Text(value, style: TextStyle(fontSize: isLarge ? 20 : 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}