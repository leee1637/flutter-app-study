import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/data/local/daos/product_dao.dart';
import 'package:warehouse_app/data/local/daos/user_dao.dart';
import 'package:warehouse_app/data/local/database_helper.dart';
import 'package:warehouse_app/data/repositories/firebase_auth_repository.dart';
import 'package:warehouse_app/data/repositories/firebase_product_repository.dart';

/// Синхронизация устройства с облаком.
///
/// Направления:
/// * **pull** — при старте приложения Firestore целиком копируется в SQLite,
///   плюс подписка на поток изменений (см. [_startListeningForUpdates]);
/// * **push** — локальные изменения, сделанные офлайн, выталкиваются в облако
///   (см. [syncLocalChanges]).
///
/// Разрешения конфликтов здесь нет: побеждает последняя запись (last-write-wins).
/// Для продакшена понадобится `updatedAt`/`revision` на документе и очередь
/// операций в SQLite.
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

  /// Подготовка синхронизации. Вызывается из `main` без `await`, чтобы
  /// приложение стартовало мгновенно, а сеть не блокировала первый экран.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!await _isOnline()) {
        debugPrint(
            'Устройство офлайн: синхронизация при первом обращении к сети');
        return;
      }

      await syncAllData();
      _startListeningForUpdates();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Не удалось инициализировать синхронизацию: $e');
    }
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Полный снимок Firestore → SQLite.
  Future<void> syncAllData() async {
    try {
      final firebaseUsers = await _firebaseAuth.getAllUsers();
      await _userDao.replaceAll(firebaseUsers);
      for (final user in firebaseUsers) {
        await _userDao.insertUser(user);
      }

      final firebaseProducts = await _firebaseProducts.getProducts();
      await _productDao.replaceAll(firebaseProducts);

      debugPrint('Синхронизировано: ${firebaseUsers.length} польз., '
          '${firebaseProducts.length} товаров');
    } catch (e) {
      debugPrint('Ошибка полной синхронизации: $e');
    }
  }

  /// Постоянная подписка на изменения товаров в облаке.
  ///
  /// Нужна именно для SQLite, а не для UI: экран может быть закрыт, но кэш
  /// всё равно должен быть актуальным, иначе после перезапуска офлайн
  /// пользователь увидит протухшие данные.
  void _startListeningForUpdates() {
    _firebaseProducts.productsStream().listen(
      (products) async {
        try {
          await _productDao.replaceAll(products);
          debugPrint('Кэш товаров обновлён из облака');
        } catch (e) {
          debugPrint('Не удалось обновить кэш товаров: $e');
        }
      },
      onError: (error) => debugPrint('Ошибка потока товаров: $error'),
    );
  }

  /// Выталкивание локальных изменений в облако.
  ///
  /// Использует upsert ([FirebaseProductRepository.addProduct] — это `set`),
  /// поэтому один и тот же метод покрывает и новые товары, и изменения
  /// существующих: `update` на несуществующем документе упал бы с ошибкой.
  Future<void> syncLocalChanges() async {
    if (!await _isOnline()) return;

    try {
      final localProducts = await _productDao.getAllProducts();

      for (final product in localProducts) {
        try {
          if (AppConstants.isLocalId(product.id)) {
            await promoteLocalProduct(product.id);
          } else {
            await _firebaseProducts.addProduct(product);
          }
        } catch (e) {
          // Один битый товар не должен ронять весь цикл.
          debugPrint('Не удалось синхронизировать ${product.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Ошибка выталкивания локальных изменений: $e');
    }
  }

  /// Заменяет временный `local_<timestamp>` идентификатор на постоянный UUID
  /// и переносит товар в облако под новым ключом.
  ///
  /// Возвращает новый ID товара либо `null`, если товар не найден или загрузка
  /// не удалась (тогда он останется локальным и попробует снова позже).
  Future<String?> promoteLocalProduct(String localId) async {
    final product = await _productDao.getProductById(localId);
    if (product == null) return null;

    final permanentId = const Uuid().v4();
    final promoted = product.copyWith(id: permanentId);

    try {
      await _firebaseProducts.addProduct(promoted);
    } catch (e) {
      debugPrint('Не удалось загрузить товар $localId в сеть: $e');
      return null;
    }

    // Облако приняло — переносим и локальную запись на новый ключ,
    // иначе в кэше останется дубль товара.
    await _productDao.insertProduct(promoted);
    await _productDao.deleteProduct(localId);
    debugPrint('Товар $localId переведён в облако как $permanentId');

    return permanentId;
  }
}
