import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  void initState() { 
    super.initState(); 
    _loadProducts(); 
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() { 
      _products = data; 
      _filteredProducts = data; 
      _isLoading = false; 
    });
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

  Future<void> _showProductDialog({Map<String, dynamic>? prod}) async {
    final isEdit = prod != null;
    final nameController = TextEditingController(text: prod?['name']?.toString() ?? '');
    final brandController = TextEditingController(text: prod?['brand']?.toString() ?? '');
    
    String rawVolume = prod?['volume']?.toString() ?? '';
    List<String> volumeParts = rawVolume.split(' ');
    final qtyController = TextEditingController(text: volumeParts.isNotEmpty ? volumeParts[0] : '');
    String unit = volumeParts.length > 1 ? volumeParts[1] : 'لیتر';
    
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
                    Expanded(flex: 2, child: TextField(controller: qtyController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'مقدار', prefixIcon: Icon(Icons.straighten, color: AppTheme.gold)))),
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
                      ],
                      Row(children: [
                        Icon(isEdit ? Icons.add_box : Icons.inventory, color: AppTheme.gold, size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(
                          controller: isEdit ? addStockController : qtyController,
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
                    final cost = int.tryParse(toEnglishDigits(costController.text.replaceAll(',', ''))) ?? 0;
                    final sell = int.tryParse(toEnglishDigits(sellController.text.replaceAll(',', ''))) ?? 0;
                    
                    if (sell > 0 && sell < cost) {
                      final confirm = await showDialog<bool>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('هشدار ضرر', style: TextStyle(color: Colors.red)), content: const Text('قیمت فروش کمتر از قیمت خرید است. آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('ثبت', style: TextStyle(color: Colors.red)))])));
                      if (confirm != true) return;
                    }

                    int finalStock;
                    if (isEdit) {
                      final addAmount = int.tryParse(toEnglishDigits(addStockController.text)) ?? 0;
                      finalStock = currentStock + addAmount;
                    } else {
                      finalStock = int.tryParse(toEnglishDigits(qtyController.text)) ?? 0;
                    }

                    final prodData = {
                      'name': nameController.text.trim(), 'category': category, 'brand': brandController.text.trim(), 
                      'viscosity': viscosity, 'volume': '${qtyController.text.trim()} $unit', 
                      'cost_price': cost, 'sell_price': sell, 'stock_quantity': finalStock
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
      await DatabaseHelper.instance.deleteProduct(id); 
      _loadProducts(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت کالاها'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadProducts)]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12), 
            child: Column(
              children: [
                TextField(
                  controller: _searchController, 
                  style: const TextStyle(color: AppTheme.textWhite), 
                  decoration: InputDecoration(
                    hintText: 'جستجو در نام یا برند کالا...', 
                    prefixIcon: const Icon(Icons.search, color: AppTheme.gold), 
                    suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.gold), 
                            onPressed: () { 
                              _searchController.clear(); 
                              _filterProducts(); 
                            }
                          ) 
                        : null, 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  ), 
                  onChanged: (_) => _filterProducts()
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40, 
                  child: ListView(
                    scrollDirection: Axis.horizontal, 
                    children: [_buildCategoryChip('همه'), ..._categories.map((c) => _buildCategoryChip(c))]
                  )
                ),
              ]
            )
          ),
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12), 
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: isLowStock ? Colors.red.withOpacity(0.2) : AppTheme.gold.withOpacity(0.2), child: Icon(isLowStock ? Icons.warning : Icons.inventory_2, color: isLowStock ? Colors.red : AppTheme.gold)),
                              title: Text(p['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: Text('${p['brand'] ?? ''} ${p['viscosity'] ?? ''} ${p['volume'] ?? ''}\nموجودی: ${formatNumber(p['stock_quantity'] ?? 0)} | فروش: ${formatPrice(p['sell_price'])} تومان', style: TextStyle(color: isLowStock ? Colors.red : AppTheme.textGrey)),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showProductDialog(prod: p)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(p['id'])),
                              ]),
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
    return Padding(
      padding: const EdgeInsets.only(left: 8), 
      child: FilterChip(
        label: Text(category, style: TextStyle(color: isSelected ? Colors.black : AppTheme.gold, fontSize: 12)), 
        selected: isSelected, 
        onSelected: (selected) { 
          setState(() => _selectedCategory = category); 
          _filterProducts(); 
        }, 
        selectedColor: AppTheme.gold, 
        backgroundColor: AppTheme.cardBlack, 
        checkmarkColor: Colors.black, 
        side: const BorderSide(color: AppTheme.gold)
      )
    );
  }
}