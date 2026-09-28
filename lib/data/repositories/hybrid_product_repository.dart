import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:warehouse_app/core/app_services.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/data/repositories/firebase_product_repository.dart';
import 'package:warehouse_app/data/repositories/local_product_repository.dart';
import 'package:warehouse_app/data/repositories/product_repository.dart';

/// Offline-first репозиторий: работает и без интернета.
///
/// Правила:
/// * **чтение** — сначала сеть (Firestore), результат кладётся в локальный кэш;
///   при любой ошибке (нет сети, таймаут, нет прав) отдаём SQLite;
/// * **запись** — сначала локально, потом в сеть. Так интерфейс отзывчив
///   и данные не теряются, а «зависшие» записи уходят в облако при синке.
class HybridProductRepository implements ProductRepository {
  final LocalProductRepository _local;
  final FirebaseProductRepository _firebase;

  HybridProductRepository({
    LocalProductRepository? local,
    FirebaseProductRepository? firebase,
  })  : _local = local ?? LocalProductRepository(),
        _firebase = firebase ?? FirebaseProductRepository();

  /// Проверка сети — только подсказка, а не гарантия: сеть может быть, а
  /// Firebase всё равно недоступен. Поэтому везде ниже ещё и try/catch.
  Future<bool> get _isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> _syncIfPossible() async {
    final syncManager = AppServices.syncManager;
    if (syncManager == null) return;
    try {
      await syncManager.syncLocalChanges();
    } catch (e) {
      debugPrint('Синхронизация не удалась: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    if (!await _isOnline) return _local.getProducts();

    try {
      final products = await _firebase.getProducts();
      await _local.productDao.replaceAll(products);
      return products;
    } catch (e) {
      debugPrint('Не удалось получить товары из сети, беру локальные: $e');
      return _local.getProducts();
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    if (!await _isOnline) return _local.getProductById(id);

    try {
      final product = await _firebase.getProductById(id);
      // Обновляем кэш, чтобы офлайн-показать ту же карточку.
      await _local.productDao.insertProduct(product);
      return product;
    } catch (e) {
      try {
        return await _local.getProductById(id);
      } on Exception catch (localError) {
        throw Exception('Товар не найден ни в сети, ни локально: $localError');
      }
    }
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final productToSave = product.id.isEmpty
        ? product.copyWith(id: AppConstants.newLocalId())
        : product;

    await _local.addProduct(productToSave);

    if (!await _isOnline) return;

    try {
      if (AppConstants.isLocalId(productToSave.id)) {
        // Товар создан офлайн — выдаём ему постоянный ID и переносим в облако.
        await AppServices.syncManager?.promoteLocalProduct(productToSave.id);
      } else {
        await _firebase.addProduct(productToSave);
        await _syncIfPossible();
      }
    } catch (e) {
      debugPrint('Товар сохранён локально, но не загружен в сеть: $e');
    }
  }

  @override
  Future<void> takeProduct(String productId, String userId) async {
    // Локальная проверка статуса выполняется первой: она мгновенная и работает
    // без сети, поэтому «занято» отсекается даже на офлайн-устройстве.
    await _local.takeProduct(productId, userId);

    if (!await _isOnline) return;

    try {
      if (AppConstants.isLocalId(productId)) {
        await _syncIfPossible();
      } else {
        await _firebase.takeProduct(productId, userId);
      }
    } catch (e) {
      debugPrint('Статус сохранён локально, но не синхронизирован: $e');
    }
  }

  @override
  Future<void> returnProduct(String productId, String userId) async {
    await _local.returnProduct(productId, userId);

    if (!await _isOnline) return;

    try {
      if (AppConstants.isLocalId(productId)) {
        await _syncIfPossible();
      } else {
        await _firebase.returnProduct(productId, userId);
      }
    } catch (e) {
      debugPrint('Возврат сохранён локально, но не синхронизирован: $e');
    }
  }
}
