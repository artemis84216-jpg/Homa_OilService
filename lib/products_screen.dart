import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
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
        final matchesSearch = _searchController.text.isEmpty || 
            (p['name'] ?? '').toString().toLowerCase().contains(_searchController.text.toLowerCase()) || 
            (p['brand'] ?? '').toString().toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesCategory = _selectedCategory == 'همه' || p['category'] == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _showInventoryHistory(int productId, String productName) async {
    final history = await DatabaseHelper.instance.getInventoryHistoryByProduct(productId);
    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تاریخچه‌ای ثبت نشده'), backgroundColor: AppTheme.gold));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: Text('تاریخچه: $productName', style: const TextStyle(color: AppTheme.gold)),
          content: SizedBox(width: double.maxFinite, child: ListView.builder(
            shrinkWrap: true, itemCount: history.length,
            itemBuilder: (context, index) {
              final h = history[index];
              return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                leading: const Icon(Icons.history, color: AppTheme.gold),
                title: Text('تاریخ: ${h['date']}', style: const TextStyle(color: AppTheme.textWhite)),
                subtitle: Text('قبلی: ${formatNumber(h['previous_stock'])} → افزودن: ${formatNumber(h['quantity_added'])} → جدید: ${formatNumber(h['new_stock'])}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              ));
            },
          )),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن', style: TextStyle(color: AppTheme.gold)))],
        ),
      ),
    );
  }

  Future<void> _showProductDialog({Map<String, dynamic>? prod}) async {
    final isEdit = prod != null;
    final nameController = TextEditingController(text: prod?['name']?.toString() ?? '');
    final brandController = TextEditingController(text: prod?['brand']?.toString() ?? '');
    
    // اصلاح: خواندن quantity به صورت اعشاری
    final qtyController = TextEditingController(text: (prod?['quantity'] ?? 0).toDouble().toString());
    String unit = prod?['unit']?.toString() ?? 'لیتر';
    
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
              title: Text(isEdit ? 'ویرایش / افزایش موجودی' : 'ثبت کالای جدید', style: const TextStyle(color: AppTheme.gold)),
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
                  // اصلاح: جدا کردن برند و گرانروی در دو ردیف
                  TextField(controller: brandController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'برند', prefixIcon: Icon(Icons.business, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  isOil
                      ? DropdownButtonFormField<String>(
                          value: viscosity.isEmpty ? null : viscosity, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite),
                          decoration: const InputDecoration(labelText: 'گرانروی', prefixIcon: Icon(Icons.water_drop, color: AppTheme.gold)),
                          items: oilViscosities.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: (v) => setStateDialog(() => viscosity = v ?? ''),
                        )
                      : TextField(controller: TextEditingController(text: viscosity), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'گرانروی (اختیاری)', prefixIcon: Icon(Icons.water_drop_outlined, color: AppTheme.textGrey)), onChanged: (v) => viscosity = v),
                  const SizedBox(height: 12),
                  // اصلاح: مقدار/تعداد با پشتیبانی اعشاری
                  Row(children: [
                    Expanded(flex: 2, child: TextField(controller: qtyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'مقدار/تعداد', prefixIcon: Icon(Icons.straighten, color: AppTheme.gold)))),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButtonFormField<String>(value: unit, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'واحد', prefixIcon: Icon(Icons.straighten, color: AppTheme.gold)), items: const [DropdownMenuItem(value: 'لیتر', child: Text('لیتر')), DropdownMenuItem(value: 'عدد', child: Text('عدد')), DropdownMenuItem(value: 'گالن', child: Text('گالن')), DropdownMenuItem(value: 'بسته', child: Text('بسته'))], onChanged: (v) => setStateDialog(() => unit = v!))),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: costController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite, fontSize: 16), decoration: const InputDecoration(labelText: 'قیمت خرید (تومان)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold), contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12))),
                  const SizedBox(height: 12),
                  TextField(controller: sellController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite, fontSize: 16), decoration: const InputDecoration(labelText: 'قیمت فروش (تومان)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold), contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (isEdit) ...[
                        Text('موجودی فعلی انبار: ${formatNumber(currentStock)}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.add_box, color: AppTheme.gold, size: 24),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: addStockController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'مقدار افزودنی به انبار', border: InputBorder.none, contentPadding: EdgeInsets.zero))),
                        ]),
                      ] else ...[
                        Row(children: [
                          const Icon(Icons.inventory, color: AppTheme.gold, size: 24),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: qtyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'موجودی اولیه انبار', border: InputBorder.none, contentPadding: EdgeInsets.zero))),
                        ]),
                      ],
                    ]),
                  ),
                ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                  onPressed: () async {
                    if (nameController.text.isEmpty) { 
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام کالا الزامی است'), backgroundColor: Colors.red)); 
                      return; 
                    }
                    if (_isCustomCategory && _customCategoryController.text.trim().isNotEmpty) {
                      if (!_categories.contains(_customCategoryController.text.trim())) {
                        _categories.add(_customCategoryController.text.trim());
                        category = _customCategoryController.text.trim();
                      }
                    }
                    final cost = int.tryParse(toEnglishDigits(costController.text.replaceAll(',', ''))) ?? 0;
                    final sell = int.tryParse(toEnglishDigits(sellController.text.replaceAll(',', ''))) ?? 0;
                    
                    if (sell > 0 && sell < cost) {
                      final confirm = await showDialog<bool>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('هشدار ضرر', style: TextStyle(color: Colors.red)), content: const Text('قیمت فروش کمتر از قیمت خرید است. آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('ثبت', style: TextStyle(color: Colors.red)))])));
                      if (confirm != true) return;
                    }

                    final jalaliNow = Jalali.now();
                    final dateStr = '${jalaliNow.year}/${jalaliNow.month.toString().padLeft(2, '0')}/${jalaliNow.day.toString().padLeft(2, '0')}';

                    if (!isEdit) {
                      final existingProduct = await DatabaseHelper.instance.findExistingProduct(
                        nameController.text.trim(), brandController.text.trim(), viscosity, unit,
                      );
                      if (existingProduct != null) {
                        final addAmount = int.tryParse(toEnglishDigits(qtyController.text.replaceAll(',', ''))) ?? 0;
                        final previousStock = existingProduct['stock_quantity'] ?? 0;
                        final newStock = previousStock + addAmount;
                        await DatabaseHelper.instance.updateProduct(existingProduct['id'], {'stock_quantity': newStock, 'cost_price': cost.toDouble(), 'sell_price': sell.toDouble()});
                        await DatabaseHelper.instance.insertInventoryHistory({'product_id': existingProduct['id'], 'quantity_added': addAmount, 'previous_stock': previousStock, 'new_stock': newStock, 'date': dateStr, 'notes': 'افزایش موجودی'});
                        Navigator.pop(ctx);
                        _loadProducts();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ کالا قبلاً ثبت شده بود. موجودی از ${formatNumber(previousStock)} به ${formatNumber(newStock)} افزایش یافت.'), backgroundColor: Colors.green, duration: const Duration(seconds: 3)));
                        return;
                      }
                    }

                    int finalStock;
                    if (isEdit) {
                      final addAmount = int.tryParse(toEnglishDigits(addStockController.text.replaceAll(',', ''))) ?? 0;
                      finalStock = currentStock + addAmount;
                      if (addAmount > 0) {
                        await DatabaseHelper.instance.insertInventoryHistory({'product_id': prod!['id'], 'quantity_added': addAmount, 'previous_stock': currentStock, 'new_stock': finalStock, 'date': dateStr, 'notes': 'افزایش موجودی'});
                      }
                    } else {
                      finalStock = int.tryParse(toEnglishDigits(qtyController.text.replaceAll(',', ''))) ?? 0;
                    }

                    // اصلاح: ذخیره quantity به صورت REAL (اعشاری)
                    final qty = double.tryParse(toEnglishDigits(qtyController.text.replaceAll(',', ''))) ?? 0;

                    final prodData = {
                      'name': nameController.text.trim(), 
                      'category': category, 
                      'brand': brandController.text.trim(), 
                      'viscosity': viscosity, 
                      'quantity': qty,
                      'unit': unit,
                      'volume': '${qty.toString()} $unit', // برای سازگاری با داده‌های قدیمی
                      'cost_price': cost.toDouble(), 
                      'sell_price': sell.toDouble(), 
                      'stock_quantity': finalStock,
                      'created_at': dateStr,
                    };
                    if (isEdit) { 
                      await DatabaseHelper.instance.updateProduct(prod!['id'], prodData); 
                    } else { 
                      final newId = await DatabaseHelper.instance.insertProduct(prodData);
                      if (!isEdit && finalStock > 0) {
                        await DatabaseHelper.instance.insertInventoryHistory({'product_id': newId, 'quantity_added': finalStock, 'previous_stock': 0, 'new_stock': finalStock, 'date': dateStr, 'notes': 'ثبت اولیه'});
                      }
                    }
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
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) { await DatabaseHelper.instance.deleteProduct(id); _loadProducts(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت کالاها'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadProducts)]),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            TextField(controller: _searchController, style: const TextStyle(color: AppTheme.textWhite), decoration: InputDecoration(hintText: 'جستجو در نام یا برند کالا...', prefixIcon: const Icon(Icons.search, color: AppTheme.gold), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterProducts(); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (_) => _filterProducts()),
            const SizedBox(height: 8),
            SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: [_buildCategoryChip('همه'), ..._categories.map((c) => _buildCategoryChip(c))])),
          ])),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) 
                : _filteredProducts.isEmpty 
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('کالایی یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) 
                    : ListView.builder(
                        padding: const EdgeInsets.all(12), 
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final p = _filteredProducts[index];
                          final isLowStock = (p['stock_quantity'] ?? 0) <= (p['min_stock'] ?? 5);
                          final brand = (p['brand'] ?? '').toString().trim();
                          final viscosity = (p['viscosity'] ?? '').toString().trim();
                          final qty = (p['quantity'] ?? 0).toDouble();
                          final unit = (p['unit'] ?? 'لیتر').toString();
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12), 
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: isLowStock ? Colors.red.withOpacity(0.2) : AppTheme.gold.withOpacity(0.2), child: Icon(isLowStock ? Icons.warning : Icons.inventory_2, color: isLowStock ? Colors.red : AppTheme.gold)),
                              title: Text(p['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    if (brand.isNotEmpty) Text('برند: $brand', style: const TextStyle(color: AppTheme.textWhite, fontSize: 13)),
    if (viscosity.isNotEmpty) Text(viscosity, style: const TextStyle(color: AppTheme.textYellow, fontSize: 13, fontWeight: FontWeight.bold)),
    if (qty > 0) Text('مقدار: ${qty.toString()} $unit', style: const TextStyle(color: AppTheme.textWhite, fontSize: 13)),
    Text('موجودی: ${formatStock(p['stock_quantity'])} | فروش: ${formatPrice(p['sell_price'])} تومان', style: TextStyle(color: isLowStock ? Colors.red : AppTheme.textGrey, fontSize: 12)),
  ],
),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(Icons.history, color: AppTheme.gold), onPressed: () => _showInventoryHistory(p['id'], p['name'] ?? '')),
                                IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showProductDialog(prod: p)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(p['id'])),
                              ]),
                              isThreeLine: true,
                            )
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showProductDialog(), backgroundColor: AppTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن کالا')),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(padding: const EdgeInsets.only(left: 8), child: FilterChip(label: Text(category, style: TextStyle(color: isSelected ? Colors.black : AppTheme.gold, fontSize: 12)), selected: isSelected, onSelected: (selected) { setState(() => _selectedCategory = category); _filterProducts(); }, selectedColor: AppTheme.gold, backgroundColor: AppTheme.cardBlack, checkmarkColor: Colors.black, side: const BorderSide(color: AppTheme.gold)));
  }
}