import 'package:sqflite/sqflite.dart';
import 'package:warehouse_app/data/local/database_helper.dart';
import 'package:warehouse_app/data/models/product_model.dart';

/// Доступ к таблице `products`. Знает про SQL и ничего не знает про сеть —
/// это позволяет менять источник данных (SQLite / Firestore) на верхних уровнях.
class ProductDao {
  final DatabaseHelper dbHelper;

  ProductDao(this.dbHelper);

  Future<void> insertProduct(ProductModel product) async {
    final db = await dbHelper.database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ProductModel?> getProductById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  Future<List<ProductModel>> getAllProducts() async {
    final db = await dbHelper.database;
    final maps = await db.query('products');
    return List.generate(maps.length, (i) => ProductModel.fromMap(maps[i]));
  }

  Future<void> updateProduct(ProductModel product) async {
    final db = await dbHelper.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Полная перезапись кэша товаров «снимком» из сети.
  ///
  /// Выполняется одной транзакцией: если приложение убить посреди цикла вставок,
  /// кэш останется консистентным (полностью старый или полностью новый),
  /// а не «наполовину обновлённым».
  Future<void> replaceAll(List<ProductModel> products) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('products');
      for (final product in products) {
        await txn.insert(
          'products',
          product.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
