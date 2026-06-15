import 'package:sqflite/sqflite.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/data/local/database_helper.dart';

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
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ProductModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ProductModel>> getAllProducts() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
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
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> takeProduct(String productId, String userId) async {
    final db = await dbHelper.database;
    await db.update(
      'products',
      {
        'status': 'taken',
        'taken_by': userId,
        'taken_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> returnProduct(String productId) async {
    final db = await dbHelper.database;
    await db.update(
      'products',
      {
        'status': 'available',
        'taken_by': null,
        'taken_at': null,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> clearTable() async {
    final db = await dbHelper.database;
    await db.delete('products');
  }
}
