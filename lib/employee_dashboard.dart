import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'invoices_screen.dart';
import 'service_history_screen.dart';
import 'app_utils.dart';

class EmployeeDashboard extends StatelessWidget {
  final Map<String, dynamic> employeeData;
  const EmployeeDashboard({super.key, required this.employeeData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.engineering, color: AppTheme.gold, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(employeeData['name'] ?? 'پنل تکنسین', style: const TextStyle(fontSize: 16, color: AppTheme.gold), overflow: TextOverflow.ellipsis)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.gold),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.gold.withOpacity(0.2), AppTheme.gold.withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('خوش آمدید، ${employeeData['name']}', style: const TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('نقش: ${employeeData['role'] == 'technician' ? 'تکنسین' : (employeeData['role'] == 'cashier' ? 'صندوق‌دار' : 'مدیر داخلی')}', style: const TextStyle(color: AppTheme.textGrey)),
                    Text('کمیسیون: ${employeeData['commission_rate'] ?? 0}٪', style: const TextStyle(color: AppTheme.textGrey)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('دسترسی‌های شما:', style: TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCard(context, Icons.receipt_long, 'ثبت فاکتور', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
                  }),
                  _buildCard(context, Icons.receipt, 'فاکتورهای من', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen()));
                  }),
                  _buildCard(context, Icons.history, 'سوابق سرویس', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHistoryScreen()));
                  }),
                  _buildCard(context, Icons.info, 'اطلاعات من', () {
                    _showMyInfo(context);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppTheme.gold),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
          ],
        ),
      ),
    );
  }

  void _showMyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('اطلاعات من', style: TextStyle(color: AppTheme.gold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('نام', employeeData['name'] ?? '-'),
              _infoRow('شماره تماس', employeeData['phone'] ?? '-'),
              _infoRow('نقش', employeeData['role'] == 'technician' ? 'تکنسین' : (employeeData['role'] == 'cashier' ? 'صندوق‌دار' : 'مدیر داخلی')),
              _infoRow('درصد کمیسیون', '${employeeData['commission_rate'] ?? 0}٪'),
              _infoRow('حقوق پایه', '${formatPrice(employeeData['base_salary'])} تومان'),
            ],
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: AppTheme.textGrey)),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}