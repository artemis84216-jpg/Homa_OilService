import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class PlansManagementScreen extends StatefulWidget {
  const PlansManagementScreen({super.key});

  @override
  State<PlansManagementScreen> createState() => _PlansManagementScreenState();
}

class _PlansManagementScreenState extends State<PlansManagementScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllPlans();
    setState(() { _plans = data; _isLoading = false; });
  }

  Future<void> _showPlanDialog({Map<String, dynamic>? plan}) async {
    final isEdit = plan != null;
    final nameController = TextEditingController(text: plan?['name']?.toString() ?? '');
    final durationController = TextEditingController(text: plan?['duration_value']?.toString() ?? '');
    final priceController = TextEditingController(text: plan?['price']?.toString() ?? '');
    final maxEmployeesController = TextEditingController(text: plan?['max_employees']?.toString() ?? '');
    final maxVehiclesController = TextEditingController(text: plan?['max_vehicles']?.toString() ?? '');
    String durationType = plan?['duration_type']?.toString() ?? 'months';
    bool unlimitedEmployees = (plan?['max_employees'] ?? 0) == 0;
    bool unlimitedVehicles = (plan?['max_vehicles'] ?? 0) == 0;

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش پلن' : 'افزودن پلن جدید', style: const TextStyle(color: AppTheme.gold)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام پلن', prefixIcon: Icon(Icons.label, color: AppTheme.gold))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: durationController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'مدت', prefixIcon: Icon(Icons.calendar_today, color: AppTheme.gold)))),
                  const SizedBox(width: 8),
                  DropdownButton<String>(value: durationType, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite), items: const [DropdownMenuItem(value: 'days', child: Text('روز')), DropdownMenuItem(value: 'months', child: Text('ماه'))], onChanged: (v) => setStateDialog(() => durationType = v!)),
                ]),
                const SizedBox(height: 12),
                TextField(controller: priceController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'قیمت (0=رایگان)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold))),
                const SizedBox(height: 12),
                CheckboxListTile(title: const Text('کارمندان نامحدود', style: TextStyle(color: AppTheme.textWhite)), value: unlimitedEmployees, activeColor: AppTheme.gold, onChanged: (v) { setStateDialog(() { unlimitedEmployees = v ?? false; if (unlimitedEmployees) maxEmployeesController.text = '0'; }); }),
                if (!unlimitedEmployees) TextField(controller: maxEmployeesController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'سقف کارمندان', prefixIcon: Icon(Icons.people, color: AppTheme.gold))),
                const SizedBox(height: 12),
                CheckboxListTile(title: const Text('خودرو نامحدود', style: TextStyle(color: AppTheme.textWhite)), value: unlimitedVehicles, activeColor: AppTheme.gold, onChanged: (v) { setStateDialog(() { unlimitedVehicles = v ?? false; if (unlimitedVehicles) maxVehiclesController.text = '0'; }); }),
                if (!unlimitedVehicles) TextField(controller: maxVehiclesController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'سقف خودرو', prefixIcon: Icon(Icons.directions_car, color: AppTheme.gold))),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || durationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام و مدت الزامی است')));
                    return;
                  }
                  final planData = {
                    'name': nameController.text.trim(),
                    'duration_value': int.tryParse(toEnglishDigits(durationController.text)) ?? 0,
                    'duration_type': durationType,
                    'price': double.tryParse(toEnglishDigits(priceController.text)) ?? 0,
                    'max_employees': unlimitedEmployees ? 0 : (int.tryParse(toEnglishDigits(maxEmployeesController.text)) ?? 0),
                    'max_vehicles': unlimitedVehicles ? 0 : (int.tryParse(toEnglishDigits(maxVehiclesController.text)) ?? 0),
                    'is_active': 1,
                  };
                  if (isEdit) {
                    await DatabaseHelper.instance.updatePlan(plan!['id'], planData);
                  } else {
                    await DatabaseHelper.instance.insertPlan(planData);
                  }
                  Navigator.pop(ctx);
                  _loadPlans();
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePlan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deletePlan(id);
      _loadPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت پلن‌ها'), centerTitle: true),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _plans.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.subscriptions, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('هنوز پلنی تعریف نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold)), child: Text('${toPersianDigits(plan['duration_value'].toString())} ${plan['duration_type'] == 'days' ? 'روزه' : 'ماهه'}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))),
                  const Spacer(),
                  Text(plan['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                Text('قیمت: ${(plan['price'] ?? 0) == 0 ? "رایگان" : "${formatPrice(plan['price'])} تومان"}', style: const TextStyle(color: AppTheme.textYellow)),
                Text('کارمندان: ${plan['max_employees'] == 0 ? "نامحدود" : toPersianDigits(plan['max_employees'].toString())}', style: const TextStyle(color: AppTheme.textWhite)),
                Text('خودرو: ${plan['max_vehicles'] == 0 ? "نامحدود" : toPersianDigits(plan['max_vehicles'].toString())}', style: const TextStyle(color: AppTheme.textWhite)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(onPressed: () => _showPlanDialog(plan: plan), icon: const Icon(Icons.edit, size: 18), label: const Text('ویرایش', style: TextStyle(fontSize: 14)))),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(onPressed: () => _deletePlan(plan['id']), icon: const Icon(Icons.delete, size: 18), label: const Text('حذف', style: TextStyle(fontSize: 14)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white))),
                ]),
              ]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showPlanDialog(), backgroundColor: AppTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن پلن')),
    );
  }
}