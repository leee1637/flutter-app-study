import 'package:warehouse_app/data/local/daos/product_dao.dart';
import 'package:warehouse_app/data/local/database_helper.dart';
import 'package:warehouse_app/data/models/product_model.dart';

// Локальное хранилище - только для автономного использования
class LocalProductRepository {
  final ProductDao productDao;  // Make DAO public for access from other repos
  LocalProductRepository()
      : productDao = ProductDao(DatabaseHelper());  // Обновляем для использования конструктора

  Future<List<ProductModel>> getProducts() async {
    return await productDao.getAllProducts();
  }

  Future<ProductModel> getProductById(String id) async {
    final product = await productDao.getProductById(id);
    if (product == null) {
      throw Exception('Product not found: $id');
    }
    return product;
  }

  Future<void> addProduct(ProductModel product) async {
    await productDao.insertProduct(product);
  }

  Future<void> updateProduct(ProductModel product) async {
    await productDao.updateProduct(product);
  }

  Future<void> deleteProduct(String id) async {
    await productDao.deleteProduct(id);
  }

  Future<ProductModel?> takeLocalProduct(String productId, String userId) async {
    final product = await getProductById(productId);
    await updateProduct(
      product.copyWith(
        status: 'taken',
        takenBy: userId,
        takenAt: DateTime.now(),
      )
    );
    return await getProductById(productId);  // Return updated version
  }

  Future<ProductModel?> returnLocalProduct(String productId, String userId) async {
    final product = await getProductById(productId);
    // Verify it was taken by the same user
    if (product.takenBy != userId) {
      throw Exception('Product was not taken by this user');
    }

    await updateProduct(
      product.copyWith(
        status: 'available',
        clearTakenBy: true,
        clearTakenAt: true,
      ),
    );
    return await getProductById(productId);  // Return updated version
  }

  Future<void> takeProduct(String productId, String userId) async {
    final product = await getProductById(productId);
    await updateProduct(
      product.copyWith(
        status: 'taken',
        takenBy: userId,
        takenAt: DateTime.now(),
      )
    );
  }

  Future<void> returnProduct(String productId, String userId) async {
    final product = await getProductById(productId);
    // Verify it was taken by the same user
    if (product.takenBy != userId) {
      throw Exception('Product was not taken by this user');
    }

    await updateProduct(
      product.copyWith(
        status: 'available',
        clearTakenBy: true,
        clearTakenAt: true,
      ),
    );
  }
}

