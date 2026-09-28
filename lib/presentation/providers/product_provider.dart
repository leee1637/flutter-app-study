import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/data/repositories/product_repository.dart';

/// Список товаров — состояние, которым управляет [ProductsNotifier].
///
/// Раньше здесь был ещё и `FutureProvider` с тем же запросом; он был нужен
/// только как «якорь» для `ref.invalidate`, то есть два провайдера грузили
/// одно и то же. Остался один.
final productsNotifierProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductModel>>>(
  (ref) => ProductsNotifier(ref.watch(productRepositoryProvider)),
);

/// Один товар по идентификатору. `.family` — это «экземпляр провайдера на
/// каждый аргумент»: карточка `abc` и карточка `xyz` кэшируются независимо.
final productProvider =
    FutureProvider.family<ProductModel, String>((ref, id) async {
  return ref.watch(productRepositoryProvider).getProductById(id);
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ProductRepository _repository;

  ProductsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.getProducts());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// После любой мутации список перечитывается: так экраны не расходятся
  /// с источником правды, а `FutureProvider` одного товара сбрасывается
  /// вызывающим кодом через `ref.invalidate`.
  Future<void> takeProduct(String productId, String userId) =>
      _mutate(() => _repository.takeProduct(productId, userId));

  Future<void> returnProduct(String productId, String userId) =>
      _mutate(() => _repository.returnProduct(productId, userId));

  Future<void> addProduct(ProductModel product) =>
      _mutate(() => _repository.addProduct(product));

  Future<void> _mutate(Future<void> Function() action) async {
    try {
      await action();
      await loadProducts();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      // Ошибку не глотаем: вызывающий экран покажет её пользователю.
      rethrow;
    }
  }
}
