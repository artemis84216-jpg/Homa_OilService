import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<String> _categories = List.from(productCategories);
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _selectedCategory = 'همه';

  @override
  void initState() { super.initState(); _loadProducts(); }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() { _products = data; _filteredProducts = data; _isLoading = false; });
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((p) {
        final matchesSearch = _searchController.text.isEmpty || (p['name'] ?? '').toString().toLowerCase().contains(_searchController.text.toLowerCase()) || (p['brand'] ?? '').toString().toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesCategory = _selectedCategory == 'همه' || p['category'] == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _showProductDialog({Map<String, dynamic>? prod}) async {
    final isEdit = prod != null;
    final nameController = TextEditingController(text: prod?['name']?.toString() ?? '');
    final brandController = TextEditingController(text: prod?['brand']?.toString() ?? '');
    
    // جدا کردن عدد از واحد برای نمایش صحیح
    String rawVolume = prod?['volume']?.toString() ?? '';
    List<String> volumeParts = rawVolume.split(' ');
    final volumeController = TextEditingController(text: volumeParts.isNotEmpty ? volumeParts[0] : '');
    String unit = volumeParts.length > 1 ? volumeParts[1] : 'لیتر';
    
    // حذف ممیز از قیمت‌ها
    final costController = TextEditingController(text: (prod?['cost_price'] ?? 0).toInt().toString());
    final sellController = TextEditingController(text: (prod?['sell_price'] ?? 0).toInt().toString());
    
    final currentStock = prod?['stock_quantity'] ?? 0;
    final addStockController = TextEditingController(text: '0'); 
    
    String category = prod?['category']?.toString() ?? _categories.first;
    String viscosity = prod?['viscosity']?.toString() ?? '';
    bool _isCustomCategory = false;
    final _customCategoryController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final isOil = category.contains('روغن');
            return AlertDialog(
              backgroundColor: AppTheme.cardBlack,
              title: Text(isEdit ? 'ویرایش / افزایش موجودی' : 'ثبت کالای جدید (موجودی اولیه)', style: const TextStyle(color: AppTheme.gold)),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام کالا', prefixIcon: Icon(Icons.inventory_2, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  if (_isCustomCategory) ...[
                    TextField(controller: _customCategoryController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام دسته‌بندی جدید', prefixIcon: Icon(Icons.category, color: AppTheme.gold))),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      value: category, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite),
                      decoration: const InputDecoration(labelText: 'دسته‌بندی', prefixIcon: Icon(Icons.category, color: AppTheme.gold)),
                      items: [..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))), const DropdownMenuItem(value: '_add_new_', child: Text('+ افزودن دسته‌بندی جدید', style: TextStyle(color: AppTheme.gold)))],
                      onChanged: (v) {
                        if (v == '_add_new_') { setStateDialog(() { _isCustomCategory = true; category = ''; }); }
                        else { setStateDialog(() { category = v!; _isCustomCategory = false; }); }
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: brandController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'برند', prefixIcon: Icon(Icons.business, color: AppTheme.gold)))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: isOil
                          ? DropdownButtonFormField<String>(
                              value: viscosity.isEmpty ? null : viscosity, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite),
                              decoration: const InputDecoration(labelText: 'گرانروی', prefixIcon: Icon(Icons.water_drop, color: AppTheme.gold)),
                              items: oilViscosities.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              onChanged: (v) => setStateDialog(() => viscosity = v ?? ''),
                            )
                          : TextField(controller: TextEditingController(text: viscosity), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'گرانروی (اختیاری)', prefixIcon: Icon(Icons.water_drop_outlined, color: AppTheme.textGrey)), onChanged: (v) => viscosity = v),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(flex: 2, child: TextField(controller: volumeController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'مقدار (عدد)', prefixIcon: Icon(Icons.straighten, color: AppTheme.gold)))),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButtonFormField<String>(value: unit, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'واحد', prefixIcon: Icon(Icons.straighten, color: AppTheme.gold)), items: const [DropdownMenuItem(value: 'لیتر', child: Text('لیتر')), DropdownMenuItem(value: 'عدد', child: Text('عدد')), DropdownMenuItem(value: 'گالن', child: Text('گالن')), DropdownMenuItem(value: 'بسته', child: Text('بسته'))], onChanged: (v) => setStateDialog(() => unit = v!))),
                  ]),
                  const SizedBox(height: 12),
                  // حذف ممیز با استفاده از CommaSeparatorFormatter و تبدیل به int
                  TextField(controller: costController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite, fontSize: 16), decoration: const InputDecoration(labelText: 'قیمت خرید (تومان)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold), contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12))),
                  const SizedBox(height: 12),
                  TextField(controller: sellController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite, fontSize: 16), decoration: const InputDecoration(labelText: 'قیمت فروش (تومان)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold), contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12))),
                  const SizedBox(height: 12),
                  
                  // منطق هوشمند موجودی انبار
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (isEdit) ...[
                        Text('موجودی فعلی انبار: ${formatNumber(currentStock)}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                      ],
                      Row(children: [
                        Icon(isEdit ? Icons.add_box : Icons.inventory, color: AppTheme.gold, size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(
                          controller: isEdit ? addStockController : volumeController, // در حالت جدید، volumeController همان موجودی اولیه است
                          keyboardType: TextInputType.number, 
                          style: const TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold), 
                          decoration: InputDecoration(labelText: isEdit ? 'مقدار افزودنی به انبار' : 'موجودی اولیه انبار', border: InputBorder.none, contentPadding: EdgeInsets.zero)
                        )),
                      ]),
                    ]),
                  ),
                ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                  onPressed: () async {
                    if (nameController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام کالا الزامی است'), backgroundColor: Colors.red)); return; }
                    
                    if (_isCustomCategory && _customCategoryController.text.trim().isNotEmpty) {
                      if (!_categories.contains(_customCategoryController.text.trim())) {
                        _categories.add(_customCategoryController.text.trim());
                        category = _customCategoryController.text.trim();
                      }
                    }

                    // حذف ممیز و تبدیل به عدد صحیح
                    final cost = int.tryParse(toEnglishDigits(costController.text.replaceAll(',', ''))) ?? 0;
                    final sell = int.tryParse(toEnglishDigits(sellController.text.replaceAll(',', ''))) ?? 0;
                    
                    if (sell > 0 && sell < cost) {
                      final confirm = await showDialog<bool>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('هشدار ضرر', style: TextStyle(color: Colors.red)), content: const Text('قیمت فروش کمتر از قیمت خرید است. آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('ثبت nonetheless', style: TextStyle(color: Colors.red)))])));
                      if (confirm != true) return;
                    }

                    int finalStock;
                    if (isEdit) {
                      final addAmount = int.tryParse(toEnglishDigits(addStockController.text)) ?? 0;
                      finalStock = currentStock + addAmount;
                    } else {
                      finalStock = int.tryParse(toEnglishDigits(volumeController.text)) ?? 0;
                    }

                    final prodData = {
                      'name': nameController.text.trim(), 
                      'category': category, 
                      'brand': brandController.text.trim(), 
                      'viscosity': viscosity, 
                      'volume': '${volumeController.text.trim()} $unit', // ذخیره صحیح: مثلا "10 عدد"
                      'cost_price': cost, 
                      'sell_price': sell, 
                      'stock_quantity': finalStock
                    };
                    if (isEdit) { await DatabaseHelper.instance.updateProduct(prod!['id'], prodData); } 
                    else { await DatabaseHelper.instance.insertProduct(prodData); }
                    Navigator.pop(ctx);
                    _loadProducts();
                  },
                  child: Text(isEdit ? 'ذخیره تغییرات' : 'ثبت کالا', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))]