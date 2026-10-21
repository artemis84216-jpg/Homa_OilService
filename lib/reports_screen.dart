import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
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

  double _totalSales = 0;
  double _totalExpenses = 0;
  double _totalSalaries = 0;
  int _invoicesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    final startStr = _startDate != null ? '${_startDate!.year}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.day.toString().padLeft(2, '0')}' : null;
    final endStr = _endDate != null ? '${_endDate!.year}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.day.toString().padLeft(2, '0')}' : null;

    final invoices = startStr != null && endStr != null
        ? await DatabaseHelper.instance.getInvoicesByDateRange(startStr, endStr)
        : await DatabaseHelper.instance.getAllInvoices();

    _invoicesCount = invoices.length;
    _totalSales = invoices.fold(0.0, (sum, i) => sum + ((i['total'] as num?)?.toDouble() ?? 0.0));

    final expenses = await DatabaseHelper.instance.getExpenses(startDate: startStr, endDate: endStr);
    _totalExpenses = expenses.fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));

    // محاسبه کل حقوق کارمندان فعال
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
                                      if (p != null) {
                                        setState(() => _startDate = p);
                                        _loadReports();
                                      }
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
                                      if (p != null) {
                                        setState(() => _endDate = p);
                                        _loadReports();
                                      }
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
                                onPressed: () {
                                  setState(() {
                                    _startDate = null;
                                    _endDate = null;
                                  });
                                  _loadReports();
                                },
                                child: const Text('حذف فیلتر', style: TextStyle(color: Colors.red)),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [Icon(Icons.bar_chart, color: AppTheme.gold, size: 28), SizedBox(width: 8), Text('آمار مالی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold))]),
                            const Divider(height: 24),
                            _buildStatRow('تعداد فاکتورها', '${toPersianDigits(_invoicesCount.toString())} فاکتور', AppTheme.textWhite),
                            _buildStatRow('کل فروش', '${formatPrice(_totalSales.toInt())} تومان', Colors.green),
                            _buildStatRow('کل هزینه‌ها', '${formatPrice(_totalExpenses.toInt())} تومان', Colors.red),
                            _buildStatRow('کل حقوق کارمندان', '${formatPrice(_totalSalaries.toInt())} تومان', Colors.orange),
                            const Divider(height: 16),
                            _buildStatRow(
                              'سود خالص',
                              '${formatPrice((_totalSales - _totalExpenses - _totalSalaries).toInt())} تومان',
                              _totalSales - _totalExpenses - _totalSalaries >= 0 ? Colors.green : Colors.red,
                              isLarge: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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