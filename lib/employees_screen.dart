// ... (بخش import ها و initState مثل قبل)

                Row(children: [
                  // حذف CommaSeparatorFormatter از پورسانت
                  Expanded(child: TextField(controller: commissionController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'درصد کمیسیون', prefixIcon: Icon(Icons.percent, color: AppTheme.gold)))),
                  const SizedBox(width: 8),
                  // حذف CommaSeparatorFormatter از حقوق
                  Expanded(child: TextField(controller: salaryController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'حقوق پایه', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold)))),
                ]),

// ... (بقیه کد مثل قبل است، فقط در بخش onPressed دکمه ذخیره، مطمئن شو که به این شکل است):
                  final empData = {
                    'name': nameController.text.trim(), 
                    'phone': phoneController.text.trim(), 
                    'password': passwordController.text.trim(),
                    'role': role, 
                    'commission_rate': double.tryParse(commissionController.text) ?? 0.0, // بدون toEnglishDigits چون کاما ندارد
                    'base_salary': double.tryParse(salaryController.text) ?? 0.0, 
                    'status': status
                  };