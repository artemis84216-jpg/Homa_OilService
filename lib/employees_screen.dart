import 'package:flutter/material.dart';
import 'database_helper.dart';
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
    setState(() { _employees = data; _isLoading = false; });
  }

  Future<void> _showEmployeeDialog({Map<String, dynamic>? emp}) async {
    final isEdit = emp != null;
    final nameController = TextEditingController(text: emp?['name']?.toString() ?? '');
    final phoneController = TextEditingController(text: emp?['phone']?.toString() ?? '');
    final passwordController = TextEditingController(text: emp?['password']?.toString() ?? '');
    final commissionController = TextEditingController(text: emp?['commission_rate']?.toString() ?? '0');
    String role = emp?['role']?.toString() ?? 'technician';
    String status = emp?['status']?.toString() ?? 'active';

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
                TextField(controller: passwordController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز عبور', prefixIcon: Icon(Icons.lock, color: AppTheme.gold))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(value: role, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نقش', prefixIcon: Icon(Icons.badge, color: AppTheme.gold)), items: const [DropdownMenuItem(value: 'technician', child: Text('تکنسین')), DropdownMenuItem(value: 'cashier', child: Text('صندوق‌دار')), DropdownMenuItem(value: 'manager', child: Text('مدیر داخلی'))], onChanged: (v) => setStateDialog(() => role = v!)),
                const SizedBox(height: 12),
                TextField(controller: commissionController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'درصد کمیسیون', prefixIcon: Icon(Icons.percent, color: AppTheme.gold))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(value: status, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'وضعیت', prefixIcon: Icon(Icons.toggle_on, color: AppTheme.gold)), items: const [DropdownMenuItem(value: 'active', child: Text('فعال')), DropdownMenuItem(value: 'inactive', child: Text('غیرفعال'))], onChanged: (v) => setStateDialog(() => status = v!)),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام و رمز عبور الزامی است')));
                    return;
                  }
                  final empData = {'name': nameController.text.trim(), 'phone': phoneController.text.trim(), 'password': passwordController.text.trim(), 'role': role, 'commission_rate': double.tryParse(commissionController.text) ?? 0.0, 'status': status};
                  if (isEdit) {
                    await DatabaseHelper.instance.updateEmployee(emp!['id'], empData);
                  } else {
                    await DatabaseHelper.instance.insertEmployee(empData);
                  }
                  Navigator.pop(ctx);
                  _loadEmployees();
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEmployee(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
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
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _employees.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('هنوز کارمندی ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final emp = _employees[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: AppTheme.gold.withOpacity(0.2), child: Icon(Icons.person, color: AppTheme.gold)),
              title: Text(emp['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
              subtitle: Text('${emp['role'] == 'technician' ? 'تکنسین' : (emp['role'] == 'cashier' ? 'صندوق‌دار' : 'مدیر')} | رمز: ${emp['password']}', style: const TextStyle(color: AppTheme.textGrey)),
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