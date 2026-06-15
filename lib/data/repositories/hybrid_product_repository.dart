import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:warehouse_app/core/app_services.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/data/repositories/firebase_product_repository.dart';
import 'package:warehouse_app/data/repositories/local_product_repository.dart';
import 'package:warehouse_app/data/repositories/product_repository.dart';

class HybridProductRepository implements ProductRepository {
  final LocalProductRepository _local;
  final FirebaseProductRepository _firebase;

  HybridProductRepository({
    LocalProductRepository? local,
    FirebaseProductRepository? firebase,
  })  : _local = local ?? LocalProductRepository(),
        _firebase = firebase ?? FirebaseProductRepository();

  Future<bool> get _isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> _syncIfPossible() async {
    // Only sync if online and sync service is initialized
    if (!await _isOnline || AppServices.syncManager == null) return;
    try {
      await AppServices.syncManager!.syncLocalChanges();
    } catch (e) {
      print('Error during sync: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    // When online, fetch from Firebase, otherwise use local
    if (await _isOnline) {
      try {
        final products = await _firebase.getProducts();
        await _local.productDao.clearTable(); // Clear local cache and replace with Firebase data

        for (final product in products) {
        await _local.productDao.insertProduct(product);
      }
        return products;
      } catch (e) {
        // On network error, fall back to local data
        print('Failed to fetch products from Firebase: $e. Falling back to local storage.');
        return _local.getProducts();
      }
        } else {
      // Offline - return cached data from local database
      return _local.getProducts();
        }
      }
  @override
  Future<ProductModel> getProductById(String id) async {
    // Prioritize getting fresh data from Firebase when online
    if (await _isOnline) {
      try {
        final product = await _firebase.getProductById(id);
        // Update local cache with fresh data
        await _local.productDao.insertProduct(product);
        return product;
      } catch (e) {
        // If online request fails, fall back to local data
        try {
          return await _local.getProductById(id);
        } catch (localError) {
          throw Exception('Neither remote nor local product found: $localError');
      }
    }
    } else {
      // Offline - serve from local db
      return await _local.getProductById(id);
  }
}

  @override
  Future<void> addProduct(ProductModel product) async {
    // Add to local cache with a temporary ID starting with "local_"
    final localProduct = product.id.isEmpty || product.id.startsWith('local_')
        ? product.copyWith(id: 'local_${DateTime.now().millisecondsSinceEpoch}')
        : product;

    await _local.addProduct(localProduct);

    // If online, immediately sync to Firebase
    if (await _isOnline) {
      try {
        await _firebase.addProduct(localProduct);
        _syncIfPossible();
      } catch (e) {
        print('Error uploading product to Firebase: $e');
      }
    }
  }

  @override
  Future<void> takeProduct(String productId, String userId) async {
    bool isOnline = await _isOnline;

    // Update local database first
    await _local.takeProduct(productId, userId);

    // Update Firebase if online
    if (isOnline) {
      try {
        if (!productId.startsWith('local_')) {
          await _firebase.takeProduct(productId, userId);
        } else {
          // If local-only product, defer updates until synced to Firebase
          _syncIfPossible();
        }
      } catch (e) {
        print('Error updating product status in Firebase: $e');
      }
    }
  }

  @override
  Future<void> returnProduct(String productId, String userId) async {
    bool isOnline = await _isOnline;

    // Update local database first
    await _local.returnProduct(productId, userId);

    // Update Firebase if online
    if (isOnline) {
      try {
        if (!productId.startsWith('local_')) {
          await _firebase.returnProduct(productId, userId);
        } else {
          // If local-only product, defer updates until synced to Firebase
          _syncIfPossible();
}
      } catch (e) {
        print('Error updating product status in Firebase: $e');
      }
    }
  }
}

