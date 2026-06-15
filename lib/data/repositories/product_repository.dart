import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/data/repositories/hybrid_product_repository.dart';
import 'package:warehouse_app/data/repositories/local_product_repository.dart';

// Define the main repository interface for all operations
abstract class ProductRepository {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> getProductById(String id);
  Future<void> addProduct(ProductModel product);
  Future<void> takeProduct(String productId, String userId);
  Future<void> returnProduct(String productId, String userId);
}

// Adapter for local-only operations (fallback when offline)
class LocalProductRepositoryAdapter implements ProductRepository {
  final LocalProductRepository _local;

  LocalProductRepositoryAdapter([LocalProductRepository? local])
      : _local = local ?? LocalProductRepository();

  @override
  Future<List<ProductModel>> getProducts() => _local.getProducts();

  @override
  Future<ProductModel> getProductById(String id) => _local.getProductById(id);

  @override
  Future<void> addProduct(ProductModel product) => _local.addProduct(product);

  @override
  Future<void> takeProduct(String productId, String userId) =>
      _local.takeProduct(productId, userId);

  @override
  Future<void> returnProduct(String productId, String userId) =>
      _local.returnProduct(productId, userId);
}

// Provide the hybrid repository that handles both online and offline modes
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return HybridProductRepository();
});

