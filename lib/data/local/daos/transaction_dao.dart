import 'package:warehouse_app/data/local/database_helper.dart';

class TransactionDao {
  final DatabaseHelper dbHelper;

  TransactionDao(this.dbHelper);

  Future<void> logTransaction({
    required String productId,
    required String userId,
    required String type,
  }) async {
    final db = await dbHelper.database;
    await db.insert(
      'transactions',
      {
        'productId': productId,
        'userId': userId,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsForProduct(String productId) async {
    final db = await dbHelper.database;
    return await db.query(
      'transactions',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsForUser(String userId) async {
    final db = await dbHelper.database;
    return await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<void> clearTable() async {
    final db = await dbHelper.database;
    await db.delete('transactions');
  }
}
