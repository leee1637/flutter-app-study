import 'package:warehouse_app/data/local/daos/product_dao.dart';
import 'package:warehouse_app/data/local/daos/transaction_dao.dart';
import 'package:warehouse_app/data/local/database_helper.dart';
import 'package:warehouse_app/data/models/product_model.dart';

/// Локальное хранилище товаров: SQLite + журнал операций.
///
/// Здесь же живут бизнес-правила предметной области («вернуть может только тот,
/// кто взял»), потому что они должны выполняться независимо от того, есть сеть
/// или нет, — иначе правило можно обойти, выключив интернет.
class LocalProductRepository {
  final ProductDao productDao;
  final TransactionDao transactionDao;

  LocalProductRepository(
      {ProductDao? productDao, TransactionDao? transactionDao})
      : productDao = productDao ?? ProductDao(DatabaseHelper()),
        transactionDao = transactionDao ?? TransactionDao(DatabaseHelper());

  Future<List<ProductModel>> getProducts() => productDao.getAllProducts();

  Future<ProductModel> getProductById(String id) async {
    final product = await productDao.getProductById(id);
    if (product == null) {
      throw Exception('Товар не найден: $id');
    }
    return product;
  }

  Future<void> addProduct(ProductModel product) =>
      productDao.insertProduct(product);

  Future<void> updateProduct(ProductModel product) =>
      productDao.updateProduct(product);

  Future<void> deleteProduct(String id) => productDao.deleteProduct(id);

  /// Взять товар. Отказываем, если товар уже взят — это защита от ситуации,
  /// когда два сотрудника одновременно отсканировали один ярлык.
  Future<void> takeProduct(String productId, String userId) async {
    final product = await getProductById(productId);

    if (product.status != 'available') {
      throw Exception(
        product.takenBy == null || product.takenBy == userId
            ? 'Товар уже взят'
            : 'Товар уже взят другим пользователем',
      );
    }

    await updateProduct(
      product.copyWith(
        status: 'taken',
        takenBy: userId,
        takenAt: DateTime.now(),
      ),
    );

    await transactionDao.logTransaction(
      productId: productId,
      userId: userId,
      type: 'take',
    );
  }

  /// Вернуть товар. Тот, кто не брал, вернуть его не может.
  Future<void> returnProduct(String productId, String userId) async {
    final product = await getProductById(productId);

    if (product.takenBy != userId) {
      throw Exception('Вернуть товар может только тот, кто его взял');
    }

    await updateProduct(
      product.copyWith(
        status: 'available',
        takenBy: null,
        takenAt: null,
      ),
    );

    await transactionDao.logTransaction(
      productId: productId,
      userId: userId,
      type: 'return',
    );
  }
}
