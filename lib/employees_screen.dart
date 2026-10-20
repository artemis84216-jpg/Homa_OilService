import 'package:flutter/material.dart';
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
  void initState() { super.initState(); _loadEmployees(); }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllEmployees();
    setState(() { _employees = data; _isLoading = false; });
 are
  }

  Future<void> _showEmployeeDialog({Map<String, dynamic>? emp}) async {
    final isEdit = emp != null;
    if (!isEdit) {
      final check = await LicenseManager.canAddEmployee();
      if (!check['allowed']) {
        if (mounted) showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Row(children: [Icon(Icons.lock, color: Colors.red, size: 28), SizedBox(width: 8), Text('محدودیت پلن', style: TextStyle(color: Colors.red))]), content: Text(check['message'] ?? '', style: const TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متوجه شدم', style: TextStyle(color: AppTheme.gold)))])));
        return;
      }
    }
    
    final nameController = TextEditingController(text: emp?['name']?.toString() ?? '');
    final phoneController = TextEditingController(text: emp?['phone']?.toString() ?? '');
    final passwordController = TextEditingController(text: emp?['password']?.toString() ?? '');
    final commissionController = TextEditingController(text: (emp?['commission_rate'] ?? 0).toString());
    final salaryController = TextEditingController(text: (emp?['base_salary'] ?? 0).toString()); // مورد ۱
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
                // مورد ۳: نمایش رمز عبور با آیکون چشم
                TextField(
                  controller: passwordController, obscureText: _obscurePassword, style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    labelText: 'رمز عبور', prefixIcon: const Icon(Icons.lock, color: AppTheme.gold),
                    suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.gold), onPressed: () => setStateDialog(() => _obscurePassword = !_obscurePassword)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(value: role, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نقش', prefixIcon: Icon(Icons.badge, color: AppTheme.gold)), items: const [DropdownMenuItem(value: 'technician', child: Text('تکنسین')), DropdownMenuItem(value: 'cashier', child: Text('صندوق‌دار')), DropdownMenuItem(value: 'manager', child: Text('مدیر داخلی'))], onChanged: (v) => setStateDialog(() => role = v!)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: commissionController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'درصد کمیسیون', prefixIcon: Icon(Icons.percent, color: AppTheme.gold)))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: salaryController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'حقوق پایه', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold)))),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(value: status, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'وضعیت', prefixIcon: Icon(Icons.toggle_on, color: AppTheme.gold)), items: const [DropdownMenuItem(value: 'active', child: Text('فعال')), DropdownMenuItem(value: 'inactive', child: Text('غیرفعال'))], onChanged: (v) => setStateDialog(() => status = v!)),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام و رمز عبور الزامی است'), backgroundColor: Colors.red));
                    return;
                  }
                  final empData = {
                    'name': nameController.text.trim(), 'phone': phoneController.text.trim(), 'password': passwordController.text.trim(),
                    'role': role, 'commission_rate': double.tryParse(toEnglishDigits(commissionController.text)) ?? 0.0