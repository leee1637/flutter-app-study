import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:warehouse_app/data/local/daos/product_dao.dart';
import 'package:warehouse_app/data/local/daos/user_dao.dart';
import 'package:warehouse_app/data/local/database_helper.dart';
import 'package:warehouse_app/data/repositories/firebase_product_repository.dart';
import 'package:warehouse_app/data/repositories/firebase_auth_repository.dart';

class SyncManager {
  final UserDao _userDao;
  final ProductDao _productDao;
  final FirebaseAuthRepository _firebaseAuth;
  final FirebaseProductRepository _firebaseProducts;

  bool _isInitialized = false;

  SyncManager()
      : _userDao = UserDao(DatabaseHelper()),
        _productDao = ProductDao(DatabaseHelper()),
        _firebaseAuth = FirebaseAuthRepository(),
        _firebaseProducts = FirebaseProductRepository();

  Future<void> initialize() async {
    if (_isInitialized) {
      print('SyncManager already initialized');
      return;
    }
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);

      if (isOnline) {
        await syncAllData();
        _startListeningForUpdates();
        _isInitialized = true;
      } else {
        print('Device is offline, sync will occur when internet is available');
      }
    } catch (e) {
      print('Error initializing SyncManager: $e');
    }
  }

  Future<void> syncAllData() async {
    try {
      final firebaseUsers = await _firebaseAuth.getAllUsers();
      await _userDao.clearTable();
      for (final user in firebaseUsers) {
        await _userDao.insertUser(user);
        print('Synced user: ${user.name}');
      }

      final firebaseProducts = await _firebaseProducts.getAllProducts();
      await _productDao.clearTable();
      for (final product in firebaseProducts) {
        await _productDao.insertProduct(product);
        print('Synced product: ${product.name}');
      }

      print('✅ All data successfully synchronized');
    } catch (e) {
      print('❌ Error during sync: $e');
    }
  }

  void _startListeningForUpdates() {
    _firebaseProducts.productsStream().listen(
      (products) async {
        try {
          await _productDao.clearTable();
            for (final product in products) {
            await _productDao.insertProduct(product);
          }
          print('✅ Product data synchronized');
        } catch (e) {
          print('❌ Error updating real-time products: $e');
        }
      },
      onError: (error) {
        print('❌ Error in products stream: $error');
      },
    );
  }

  Future<void> syncLocalChanges() async {
    try {
      final localProducts = await _productDao.getAllProducts();

      for (final product in localProducts) {
        try {
          if (product.id.startsWith('local_')) {
            await _firebaseProducts.addProduct(product);
            // For offline-generated products, the full upload and ID replacement logic
            // must be handled separately, possibly through monitoring for newly created IDs
            // after the upload completes. Currently, the system cannot track Firebase-
            // generated IDs without a return value from addProduct, so manual sync
            // or background processing would be needed for ID mapping
            print('✅ Uploaded local product to Firebase: ${product.name}');
          } else {
            await _firebaseProducts.updateProduct(product);
            print('✅ Updated product in Firebase: ${product.name}');
          }
        } catch (e) {
          print('⚠️ Failed to sync local change for product ${product.id}: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing local changes: $e');
    }
  }
}

