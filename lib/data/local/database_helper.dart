import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Точка доступа к локальной базе SQLite.
///
/// Реализован как синглтон (фабричный конструктор + приватный генеративный),
/// потому что экземпляр создают десятки классов, а [openDatabase] дорогой —
/// база должна открываться один раз на приложение.
class DatabaseHelper {
  /// Текущая версия схемы. При изменении схемы нужно поднять её и дописать
  /// ветку в [_onUpgrade], иначе sqflite не даст обновить файл у старых установок.
  static const int schemaVersion = 3;

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  /// Ленивая инициализация соединения: первый вызов открывает файл, дальше
  /// отдаётся закэшированный [Database].
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(
      (await getApplicationDocumentsDirectory()).path,
      'warehouse.db',
    );
    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Создание БД с нуля (первый запуск приложения).
  Future<void> _onCreate(DatabaseExecutor db, int version) async {
    await _createUsers(db);
    await _createProducts(db);
    await _createTransactions(db);
  }

  /// Миграции для уже установленных приложений.
  Future<void> _onUpgrade(
      DatabaseExecutor db, int oldVersion, int newVersion) async {
    // v1 -> v2: у products появились статус и поля «кем/когда взята».
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS products');
      await _createProducts(db);
    }
    // v2 -> v3: журнал операций (взятие/возврат товара).
    if (oldVersion < 3) {
      await _createTransactions(db);
    }
  }

  static Future<void> _createUsers(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT,
        password TEXT
      )
    ''');
  }

  static Future<void> _createProducts(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        status TEXT NOT NULL,
        taken_by TEXT,
        taken_at TEXT
      )
    ''');
  }

  static Future<void> _createTransactions(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_product ON transactions(product_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id)',
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
