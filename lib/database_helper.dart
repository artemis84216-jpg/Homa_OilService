import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDB();

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'homa_oil_service.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int v) async {
    await db.execute('''CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, 
      password_hash TEXT, role TEXT, full_name TEXT, phone TEXT, 
      is_active INTEGER DEFAULT 1, created_at TEXT DEFAULT CURRENT_TIMESTAMP)''');
      
    await db.execute('''CREATE TABLE licenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT, license_key TEXT UNIQUE, 
      device_id TEXT, plan_type TEXT, start_date TEXT, end_date TEXT, 
      is_active INTEGER DEFAULT 1, created_at TEXT DEFAULT CURRENT_TIMESTAMP)''');
      
    await db.execute('''CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)''');
  }
}