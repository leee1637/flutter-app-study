import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join((await getApplicationDocumentsDirectory()).path, 'warehouse.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS products');
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
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('users');
    await db.delete('products');
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
    await _initDatabase();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

