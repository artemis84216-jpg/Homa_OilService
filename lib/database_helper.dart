import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('homa_oilservice.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 4, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL, national_id TEXT, address TEXT, notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE vehicles (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, plate_number TEXT NOT NULL, brand TEXT, model TEXT, year INTEGER, vin TEXT, current_mileage INTEGER DEFAULT 0, last_service_date TEXT, last_service_mileage INTEGER DEFAULT 0, notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE products (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, category TEXT, brand TEXT, volume TEXT, viscosity TEXT, unit TEXT DEFAULT "لیتر", quantity REAL DEFAULT 0, cost_price REAL DEFAULT 0, sell_price REAL DEFAULT 0, stock_quantity INTEGER DEFAULT 0, min_stock INTEGER DEFAULT 5, image TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE services (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price REAL DEFAULT 0, duration_minutes INTEGER DEFAULT 30, description TEXT, is_active INTEGER DEFAULT 1, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE invoices (id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_number TEXT UNIQUE, vehicle_id INTEGER, customer_id INTEGER, employee_id INTEGER, invoice_date TEXT, mileage_at_service INTEGER DEFAULT 0, items_json TEXT, subtotal REAL DEFAULT 0, discount REAL DEFAULT 0, total REAL DEFAULT 0, payment_method TEXT DEFAULT "cash", status TEXT DEFAULT "paid", notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE service_history (id INTEGER PRIMARY KEY AUTOINCREMENT, vehicle_id INTEGER, invoice_id INTEGER, service_type TEXT, oil_brand TEXT, oil_viscosity TEXT, oil_volume REAL, mileage INTEGER, next_service_mileage INTEGER, next_service_date TEXT, technician_notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE employees (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, password TEXT, role TEXT DEFAULT "technician", profile_image TEXT, commission_rate REAL DEFAULT 0.0, base_salary REAL DEFAULT 0.0, status TEXT DEFAULT "active", created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, amount REAL, date TEXT, description TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE expense_categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)');
    await db.execute('INSERT INTO expense_categories (name) VALUES ("خرید کالا"), ("حقوق"), ("اجاره"), ("قبوض"), ("تعمیرات"), ("تبلیغات"), ("سایر")');
    await db.execute('CREATE TABLE plans (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, duration_value INTEGER NOT NULL, duration_type TEXT DEFAULT "months", price REAL NOT NULL, max_employees INTEGER NOT NULL, max_vehicles INTEGER NOT NULL, is_active INTEGER DEFAULT 1, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE licenses (id INTEGER PRIMARY KEY AUTOINCREMENT, shop_name TEXT NOT NULL, device_id TEXT NOT NULL, license_code TEXT NOT NULL, plan_id INTEGER NOT NULL, plan_name TEXT NOT NULL, expiry_date TEXT NOT NULL, issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE invitations (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE, inviter_name TEXT NOT NULL, inviter_role TEXT NOT NULL, target_role TEXT NOT NULL, apk_download_url TEXT, is_used INTEGER DEFAULT 0, used_by_device_id TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('''
      CREATE TABLE inventory_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        quantity_added INTEGER,
        previous_stock INTEGER,
        new_stock INTEGER,
        date TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN unit TEXT DEFAULT "لیتر"');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE inventory_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER,
          quantity_added INTEGER,
          previous_stock INTEGER,
          new_stock INTEGER,
          date TEXT,
          notes TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE products ADD COLUMN quantity REAL DEFAULT 0');
      // انتقال داده‌های قدیمی volume به quantity
      final products = await db.query('products');
      for (var p in products) {
        final volume = p['volume']?.toString() ?? '';
        final parts = volume.split(' ');
        if (parts.isNotEmpty) {
          final qty = double.tryParse(parts[0].replaceAll(',', '')) ?? 0;
          await db.update('products', {'quantity': qty}, where: 'id = ?', whereArgs: [p['id']]);
        }
      }
    }
  }

  // مشتریان
  Future<int> insertCustomer(Map<String, dynamic> c) async { final db = await instance.database; return await db.insert('customers', c); }
  Future<List<Map<String, dynamic>>> getAllCustomers() async { final db = await instance.database; return await db.query('customers', orderBy: 'id DESC'); }
  Future<int> updateCustomer(int id, Map<String, dynamic> c) async { final db = await instance.database; return await db.update('customers', c, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteCustomer(int id) async { final db = await instance.database; return await db.delete('customers', where: 'id = ?', whereArgs: [id]); }

  // خودروها
  Future<int> insertVehicle(Map<String, dynamic> v) async { final db = await instance.database; return await db.insert('vehicles', v); }
  Future<List<Map<String, dynamic>>> getAllVehicles() async { final db = await instance.database; return await db.rawQuery('SELECT v.*, c.name as customer_name, c.phone as customer_phone FROM vehicles v LEFT JOIN customers c ON v.customer_id = c.id ORDER BY v.id DESC'); }
  Future<Map<String, dynamic>?> getVehicleById(int id) async { final db = await instance.database; final result = await db.query('vehicles', where: 'id = ?', whereArgs: [id]); return result.isNotEmpty ? result.first : null; }
  Future<int> updateVehicle(int id, Map<String, dynamic> v) async { final db = await instance.database; return await db.update('vehicles', v, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteVehicle(int id) async { final db = await instance.database; return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]); }

  // کالاها
  Future<int> insertProduct(Map<String, dynamic> p) async { final db = await instance.database; return await db.insert('products', p); }
  Future<List<Map<String, dynamic>>> getAllProducts() async { final db = await instance.database; return await db.query('products', orderBy: 'id DESC'); }
  Future<int> updateProduct(int id, Map<String, dynamic> p) async { final db = await instance.database; return await db.update('products', p, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteProduct(int id) async { final db = await instance.database; return await db.delete('products', where: 'id = ?', whereArgs: [id]); }
  Future<int> updateProductStock(int id, int newStock) async { final db = await instance.database; return await db.update('products', {'stock_quantity': newStock}, where: 'id = ?', whereArgs: [id]); }
  
  Future<Map<String, dynamic>?> findExistingProduct(String name, String brand, String viscosity, String unit) async {
    final db = await instance.database;
    final result = await db.query('products', where: 'name = ? AND brand = ? AND viscosity = ? AND unit = ?', whereArgs: [name, brand, viscosity, unit], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  // تاریخچه موجودی
  Future<int> insertInventoryHistory(Map<String, dynamic> history) async { final db = await instance.database; return await db.insert('inventory_history', history); }
  Future<List<Map<String, dynamic>>> getInventoryHistoryByProduct(int productId) async { final db = await instance.database; return await db.query('inventory_history', where: 'product_id = ?', whereArgs: [productId], orderBy: 'id DESC'); }

  // خدمات
  Future<int> insertService(Map<String, dynamic> s) async { final db = await instance.database; return await db.insert('services', s); }
  Future<List<Map<String, dynamic>>> getAllServices() async { final db = await instance.database; return await db.query('services', where: 'is_active = 1', orderBy: 'id DESC'); }
  Future<int> updateService(int id, Map<String, dynamic> s) async { final db = await instance.database; return await db.update('services', s, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteService(int id) async { final db = await instance.database; return await db.delete('services', where: 'id = ?', whereArgs: [id]); }

  // فاکتورها
  Future<int> insertInvoice(Map<String, dynamic> inv) async { final db = await instance.database; return await db.insert('invoices', inv); }
  Future<List<Map<String, dynamic>>> getAllInvoices() async { final db = await instance.database; return await db.rawQuery('SELECT i.*, v.plate_number, v.brand, v.model, c.name as customer_name, c.phone as customer_phone, e.name as employee_name FROM invoices i LEFT JOIN vehicles v ON i.vehicle_id = v.id LEFT JOIN customers c ON i.customer_id = c.id LEFT JOIN employees e ON i.employee_id = e.id ORDER BY i.id DESC'); }
  Future<List<Map<String, dynamic>>> getInvoicesByDateRange(String start, String end) async { final db = await instance.database; return await db.rawQuery('SELECT i.*, v.plate_number, c.name as customer_name FROM invoices i LEFT JOIN vehicles v ON i.vehicle_id = v.id LEFT JOIN customers c ON i.customer_id = c.id WHERE i.invoice_date >= ? AND i.invoice_date <= ? ORDER BY i.id DESC', [start, end]); }
  Future<int> deleteInvoice(int id) async { final db = await instance.database; return await db.delete('invoices', where: 'id = ?', whereArgs: [id]); }

  // سوابق سرویس
  Future<int> insertServiceHistory(Map<String, dynamic> sh) async { final db = await instance.database; return await db.insert('service_history', sh); }
  Future<List<Map<String, dynamic>>> getServiceHistoryByVehicle(int vehicleId) async { final db = await instance.database; return await db.query('service_history', where: 'vehicle_id = ?', whereArgs: [vehicleId], orderBy: 'id DESC'); }
  Future<List<Map<String, dynamic>>> getAllServiceHistoryWithDetails() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT sh.*, v.plate_number, v.brand, v.model, c.name as customer_name, c.national_id
      FROM service_history sh
      JOIN vehicles v ON sh.vehicle_id = v.id
      LEFT JOIN customers c ON v.customer_id = c.id
      ORDER BY sh.id DESC
    ''');
  }

  // کارمندان
  Future<int> insertEmployee(Map<String, dynamic> e) async { final db = await instance.database; return await db.insert('employees', e); }
  Future<List<Map<String, dynamic>>> getAllEmployees() async { final db = await instance.database; return await db.query('employees', orderBy: 'id DESC'); }
  Future<Map<String, dynamic>?> getEmployeeByCredentials(String name, String password) async { final db = await instance.database; final result = await db.query('employees', where: 'name = ? AND password = ? AND status = "active"', whereArgs: [name, password]); return result.isNotEmpty ? result.first : null; }
  Future<int> updateEmployee(int id, Map<String, dynamic> e) async { final db = await instance.database; return await db.update('employees', e, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteEmployee(int id) async { final db = await instance.database; return await db.delete('employees', where: 'id = ?', whereArgs: [id]); }

  // هزینه‌ها
  Future<List<Map<String, dynamic>>> getExpenseCategories() async { final db = await instance.database; return await db.query('expense_categories', orderBy: 'name ASC'); }
  Future<int> addExpenseCategory(String name) async { final db = await instance.database; return await db.insert('expense_categories', {'name': name}); }
  Future<int> deleteExpenseCategory(int id) async { final db = await instance.database; return await db.delete('expense_categories', where: 'id = ?', whereArgs: [id]); }
  Future<List<Map<String, dynamic>>> getExpenses({String? category, String? startDate, String? endDate, String? searchQuery}) async {
    final db = await instance.database;
    String where = '1=1'; List<dynamic> whereArgs = [];
    if (category != null && category.isNotEmpty && category != 'همه') { where += ' AND category = ?'; whereArgs.add(category); }
    if (startDate != null && startDate.isNotEmpty) { where += ' AND date >= ?'; whereArgs.add(startDate); }
    if (endDate != null && endDate.isNotEmpty) { where += ' AND date <= ?'; whereArgs.add(endDate); }
    if (searchQuery != null && searchQuery.isNotEmpty) { where += ' AND (description LIKE ? OR category LIKE ?)'; whereArgs.add('%$searchQuery%'); whereArgs.add('%$searchQuery%'); }
    return await db.query('expenses', where: where, whereArgs: whereArgs, orderBy: 'id DESC');
  }
  Future<int> insertExpense(Map<String, dynamic> e) async { final db = await instance.database; return await db.insert('expenses', e); }
  Future<int> deleteExpense(int id) async { final db = await instance.database; return await db.delete('expenses', where: 'id = ?', whereArgs: [id]); }

  // پلن‌ها
  Future<List<Map<String, dynamic>>> getAllPlans() async { final db = await instance.database; return await db.query('plans', orderBy: 'duration_value ASC'); }
  Future<int> insertPlan(Map<String, dynamic> p) async { final db = await instance.database; return await db.insert('plans', p); }
  Future<int> updatePlan(int id, Map<String, dynamic> p) async { final db = await instance.database; return await db.update('plans', p, where: 'id = ?', whereArgs: [id]); }
  Future<int> deletePlan(int id) async { final db = await instance.database; return await db.delete('plans', where: 'id = ?', whereArgs: [id]); }

  // لایسنس
  Future<int> insertLicense(Map<String, dynamic> l) async { final db = await instance.database; return await db.insert('licenses', l); }
  Future<List<Map<String, dynamic>>> getAllLicenses() async { final db = await instance.database; return await db.query('licenses', orderBy: 'id DESC'); }
  Future<List<Map<String, dynamic>>> searchLicenses(String query) async { final db = await instance.database; return await db.query('licenses', where: 'shop_name LIKE ? OR device_id LIKE ?', whereArgs: ['%$query%', '%$query%'], orderBy: 'id DESC'); }
  Future<int> deleteLicense(int id) async { final db = await instance.database; return await db.delete('licenses', where: 'id = ?', whereArgs: [id]); }

  // دعوت‌نامه
  Future<int> insertInvitation(Map<String, dynamic> i) async { final db = await instance.database; return await db.insert('invitations', i); }
  Future<List<Map<String, dynamic>>> getAllInvitations() async { final db = await instance.database; return await db.query('invitations', orderBy: 'id DESC'); }

  Future<void> resetDatabase() async {
    final db = await instance.database;
    await db.delete('customers'); await db.delete('vehicles'); await db.delete('products');
    await db.delete('services'); await db.delete('invoices'); await db.delete('service_history');
    await db.delete('employees'); await db.delete('expenses'); await db.delete('plans');
    await db.delete('licenses'); await db.delete('invitations'); await db.delete('inventory_history');
  }
}