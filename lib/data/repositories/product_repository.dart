import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/data/repositories/hybrid_product_repository.dart';

/// Контракт работы с товарами.
///
/// Реализации: [LocalProductRepository] — только SQLite, [FirebaseProductRepository] —
/// только облако, [HybridProductRepository] — то, что реально используется
/// (выбирает источник по наличию сети).
abstract class ProductRepository {
  Future<List<ProductModel>> getProducts();

  Future<ProductModel> getProductById(String id);

  Future<void> addProduct(ProductModel product);

  Future<void> takeProduct(String productId, String userId);

  Future<void> returnProduct(String productId, String userId);
}

/// Единственная точка подмены реализации: UI работает с абстракцией,
/// а провайдер отдаёт hybrid-реализацию.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return HybridProductRepository();
});
