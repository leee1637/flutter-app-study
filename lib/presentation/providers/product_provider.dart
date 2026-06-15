import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/data/repositories/product_repository.dart';

final productRepositoryProviderFromProviders = Provider<ProductRepository>((ref) {
  final repo = ref.read(productRepositoryProvider);
  return repo;
});

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProviderFromProviders);
  return await repo.getProducts();
});

final productProvider = FutureProvider.family<ProductModel, String>((ref, id) async {
  final repo = ref.watch(productRepositoryProviderFromProviders);
  return await repo.getProductById(id);
});

final productsNotifierProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductModel>>>((ref) {
  return ProductsNotifier(ref.watch(productRepositoryProviderFromProviders));
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ProductRepository _repository;

  ProductsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await _repository.getProducts();
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> takeProduct(String productId, String userId) async {
    try {
      await _repository.takeProduct(productId, userId);
      await loadProducts();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> returnProduct(String productId, String userId) async {
    try {
      await _repository.returnProduct(productId, userId);
      await loadProducts();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _repository.addProduct(product);
      await loadProducts();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

