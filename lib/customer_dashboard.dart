import 'package:flutter/material.dart';
import 'customer_search_screen.dart';
import 'service_history_screen.dart';
import 'app_utils.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('پنل مشتری'),
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('خوش آمدید', style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('به پنل مشتریان تعویض روغنی هما', style: TextStyle(color: AppTheme.textGrey)),
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
                  _buildCard(context, Icons.search, 'جستجوی ملک/خدمات', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSearchScreen()));
                  }),
                  _buildCard(context, Icons.history, 'سوابق سرویس', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHistoryScreen()));
                  }),
                  _buildCard(context, Icons.info, 'درباره ما', () {
                    _showAbout(context);
                  }),
                  _buildCard(context, Icons.phone, 'تماس با ما', () {
                    _showContact(context);
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
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('درباره ما', style: TextStyle(color: AppTheme.gold)),
          content: const Text(
            'Homa_OilService\nسیستم مدیریت تعویض روغنی هما\n\nنسخه ۱.۰.۰\n\nتوسعه‌دهنده:\nگروه نرم‌افزاری هما\nHoma_Software_Group',
            style: TextStyle(color: AppTheme.textWhite, height: 1.6),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن', style: TextStyle(color: AppTheme.gold))),
          ],
        ),
      ),
    );
  }

  void _showContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('تماس با ما', style: TextStyle(color: AppTheme.gold)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📞 تلفن پشتیبانی:', style: TextStyle(color: AppTheme.textGrey)),
              SizedBox(height: 4),
              Text('۰۲۱-۱۲۳۴۵۶۷۸', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('📧 ایمیل:', style: TextStyle(color: AppTheme.textGrey)),
              SizedBox(height: 4),
              Text('info@homa-oil.ir', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن', style: TextStyle(color: AppTheme.gold))),
          ],
        ),
      ),
    );
  }
}