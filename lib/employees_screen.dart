import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';
import 'license_manager.dart';
import 'app_utils.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllEmployees();
    setState(() {
      _employees = data;
      _isLoading = false;
    });
  }

  // تابع کمکی برای اضافه کردن کاما به اعداد (بدون پسوند تومان)
  String _formatNumberWithCommas(num? number) {
    if (number == null) return '0';
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Future<void> _showEmployeeDialog({Map<String, dynamic>? emp}) async {
    final isEdit = emp != null;
    
    if (!isEdit) {
      final check = await LicenseManager.canAddEmployee();
      if (!check['allowed']) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: AppTheme.cardBlack,
                title: const Row(children: [Icon(Icons.lock, color: Colors.red, size: 28), SizedBox(width: 8), Text('محدودیت پلن', style: TextStyle(color: Colors.red))]),
                content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(check['message'] ?? 'امکان ثبت کارمند جدید وجود ندارد', style: const TextStyle(color: AppTheme.textWhite)),
                  const SizedBox(height: 12),
                  const Text('برای افزایش سقف کارمندان، پلن خود را ارتقا دهید.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                ]),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متوجه شدم', style: TextStyle(color: AppTheme.gold)))],
              ),
            ),
          );
        }
        return;
      }
    }
    
    final nameController = TextEditingController(text: emp?['name']?.toString() ?? '');
    final phoneController = TextEditingController(text: emp?['phone']?.toString() ?? '');
    final passwordController = TextEditingController(text: emp?['password']?.toString() ?? '');
    
    // اصلاح: نمایش حقوق با کاما در حالت ویرایش
    final salaryController = TextEditingController(text: _formatNumberWithCommas(emp?['base_salary']));
    final commissionController = TextEditingController(text: (emp?['commission_rate'] ?? 0).toString());
    
    String role = emp?['role']?.toString() ?? 'technician';
    String status = emp?['status']?.toString() ?? 'active';
    bool _obscurePassword = true;

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش کارمند' : 'افزودن کارمند', style: const TextStyle(color: AppTheme.gold)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', prefixIcon: Icon(Icons.person, color: AppTheme.gold))),
                const SizedBox(height: 12),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شماره تماس', prefixIcon: Icon(Icons.phone, color: AppTheme.gold))),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController, 
                  obscureText: _obscurePassword, 
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    labelText: 'رمز عبور', 
                    prefixIcon: const Icon(Icons.lock, color: AppTheme.gold),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.gold), 
                      onPressed: () => setStateDialog(() => _obscurePassword = !_obscurePassword)
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role, 
                  dropdownColor: AppTheme.cardBlack, 
                  style: const TextStyle(color: AppTheme.textWhite), 
                  decoration: const InputDecoration(labelText: 'نقش', prefixIcon: Icon(Icons.badge, color: AppTheme.gold)), 
                  items: const [
                    DropdownMenuItem(value: 'technician', child: Text('تکنسین')), 
                    DropdownMenuItem(value: 'cashier', child: Text('صندوق‌دار')), 
                    DropdownMenuItem(value: 'manager', child: Text('مدیر داخلی'))
                  ], 
                  onChanged: (v) => setStateDialog(() => role = v!)
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: commissionController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'درصد کمیسیون', prefixIcon: Icon(Icons.percent, color: AppTheme.gold)))),
                  const SizedBox(width: 8),
                  // اصلاح: اضافه کردن CommaSeparatorFormatter به فیلد حقوق
                  Expanded(
                    child: TextField(
                      controller: salaryController, 
                      keyboardType: TextInputType.number, 
                      inputFormatters: [CommaSeparatorFormatter()], // <-- این خط باعث جداسازی ۳ رقمی حین تایپ می‌شود
                      style: const TextStyle(color: AppTheme.textWhite), 
                      decoration: const InputDecoration(labelText: 'حقوق پایه (تومان)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold))
                    )
                  ),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status, 
                  dropdownColor: AppTheme.cardBlack, 
                  style: const TextStyle(color: AppTheme.textWhite), 
                  decoration: const InputDecoration(labelText: 'وضعیت', prefixIcon: Icon(Icons.toggle_on, color: AppTheme.gold)), 
                  items: const [DropdownMenuItem(value: 'active', child: Text('فعال')), DropdownMenuItem(value: 'inactive', child: Text('غیرفعال'))], 
                  onChanged: (v) => setStateDialog(() => status = v!)
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                onPressed: () async {
                  if (nameController.text.isEmpty || passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام و رمز عبور الزامی است'), backgroundColor: Colors.red));
                    return;
                  }
                  
                  // اصلاح: حذف کاما قبل از تبدیل به عدد
                  final cleanSalary = toEnglishDigits(salaryController.text.replaceAll(',', ''));
                  
                  final empData = {
                    'name': nameController.text.trim(), 
                    'phone': phoneController.text.trim(), 
                    'password': passwordController.text.trim(),
                    'role': role, 
                    'commission_rate': double.tryParse(commissionController.text) ?? 0.0,
                    'base_salary': double.tryParse(cleanSalary) ?? 0.0, 
                    'status': status,
                    // اصلاح: ذخیره تاریخ شمسی
                    'created_at': '${Jalali.now().year}/${Jalali.now().month.toString().padLeft(2, '0')}/${Jalali.now().day.toString().padLeft(2, '0')}',
                  };
                  
                  if (isEdit) { 
                    await DatabaseHelper.instance.updateEmployee(emp!['id'], empData); 
                  } else { 
                    await DatabaseHelper.instance.insertEmployee(empData); 
                  }
                  Navigator.pop(ctx);
                  _loadEmployees();
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEmployee(int id) async {
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
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))
          ]
        )
      )
    );
    if (confirm == true) { 
      await DatabaseHelper.instance.deleteEmployee(id); 
      _loadEmployees(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت کارمندان'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadEmployees)]),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) 
        : _employees.isEmpty 
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('هنوز کارمندی ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) 
          : ListView.builder(
              padding: const EdgeInsets.all(12), 
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final emp = _employees[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12), 
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppTheme.gold.withOpacity(0.2), child: Icon(Icons.person, color: AppTheme.gold)),
                    title: Text(emp['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                    subtitle: Text('${emp['role'] == 'technician' ? 'تکنسین' : (emp['role'] == 'cashier' ? 'صندوق‌دار' : 'مدیر')} | حقوق: ${formatPrice(emp['base_salary'])}\nرمز: ${emp['password']}', style: const TextStyle(color: AppTheme.textGrey)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showEmployeeDialog(emp: emp)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteEmployee(emp['id'])),
                    ]),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showEmployeeDialog(), backgroundColor: AppTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن کارمند')),
    );
  }
}