import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('homa_oil.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // جدول کاربران (مدیر، کارمند، مشتری)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL, -- 'admin', 'employee', 'customer'
        phone TEXT UNIQUE,
        password TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // جدول خودروها
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER,
        plate_number TEXT UNIQUE NOT NULL,
        model TEXT,
        year TEXT,
        current_mileage INTEGER,
        FOREIGN KEY (owner_id) REFERENCES users (id)
      )
    ''');

    // جدول کالاها (روغن، فیلتر و ...)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT,
        price REAL NOT NULL,
        stock_quantity INTEGER DEFAULT 0,
        min_stock_alert INTEGER DEFAULT 5
      )
    ''');

    // جدول خدمات
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT
      )
    ''');

    // جدول فاکتورها
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER,
        employee_id INTEGER,
        total_amount REAL NOT NULL,
        date TEXT NOT NULL, -- تاریخ شمسی
        status TEXT DEFAULT 'paid',
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id),
        FOREIGN KEY (employee_id) REFERENCES users (id)
      )
    ''');

    // جدول سوابق سرویس خودرو (برای یادآوری)
    await db.execute('''
      CREATE TABLE vehicle_services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER,
        service_date TEXT NOT NULL,
        mileage_at_service INTEGER,
        next_service_mileage INTEGER,
        notes TEXT,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
      )
    ''');
  }
}