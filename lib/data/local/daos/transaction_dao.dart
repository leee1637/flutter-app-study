import 'package:warehouse_app/data/local/database_helper.dart';

/// Журнал операций: кто, когда и что сделал с товаром (взял / вернул).
///
/// Нужен, потому что само состояние товара хранит только последнюю операцию:
/// без журнала нельзя ответить на вопрос «кто и когда брал этот инструмент
/// на прошлой неделе».
class TransactionDao {
  final DatabaseHelper dbHelper;

  TransactionDao(this.dbHelper);

  Future<void> logTransaction({
    required String productId,
    required String userId,
    required String type,
  }) async {
    final db = await dbHelper.database;
    await db.insert('transactions', {
      'product_id': productId,
      'user_id': userId,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// История операций по конкретному товару.
  ///
  /// Экран истории в UI пока не сделан, поэтому методы чтения пока не
  /// вызываются — удалять их не стоит: без них журнал нельзя прочитать,
  /// и проверять его вручную через SQL придётся.
  Future<List<Map<String, dynamic>>> getTransactionsForProduct(
    String productId,
  ) async {
    final db = await dbHelper.database;
    return db.query(
      'transactions',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
    );
  }

  /// История операций конкретного сотрудника.
  Future<List<Map<String, dynamic>>> getTransactionsForUser(
      String userId) async {
    final db = await dbHelper.database;
    return db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }
}
