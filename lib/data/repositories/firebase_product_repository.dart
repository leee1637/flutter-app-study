import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/data/repositories/product_repository.dart';

/// Облачное хранилище товаров: Firestore.
///
/// Firestore — источник правды. Время операций пишется сервером
/// ([FieldValue.serverTimestamp]), потому что часы телефона могут врать,
/// а по этим датам потом разбираются, кто и когда брал инструмент.
class FirebaseProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(AppConstants.productsCollection);

  @override
  Future<List<ProductModel>> getProducts() async {
    final snapshot = await _products.get();
    return snapshot.docs.map(ProductModel.fromFirestore).toList();
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final snapshot = await _products.doc(id).get();
    if (!snapshot.exists) {
      throw Exception('Товар не найден в базе: $id');
    }
    return ProductModel.fromFirestore(snapshot);
  }

  /// Upsert: [DocumentReference.set] создаёт документ или перезаписывает
  /// существующий по ключу `product.id`.
  @override
  Future<void> addProduct(ProductModel product) async {
    await _products.doc(product.id).set(product.toFirestoreMap());
  }

  /// Взять товар атомарно.
  ///
  /// Транзакция нужна, чтобы два человека не взяли один товар одновременно:
  /// внутри транзакции Firestore повторно проверит условие и откатит запись,
  /// если статус успел измениться.
  @override
  Future<void> takeProduct(String productId, String userId) async {
    final ref = _products.doc(productId);

    await _firestore.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) {
        throw Exception('Товар не найден в базе: $productId');
      }

      final data = snapshot.data()!;
      final status = data['status'] as String? ?? AppConstants.statusAvailable;
      if (status != AppConstants.statusAvailable) {
        final takenBy = data['takenBy'] as String?;
        throw Exception(
          takenBy == null || takenBy == userId
              ? 'Товар уже взят'
              : 'Товар уже взят другим пользователем',
        );
      }

      txn.update(ref, {
        'status': AppConstants.statusTaken,
        'takenBy': userId,
        'takenAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> returnProduct(String productId, String userId) async {
    final ref = _products.doc(productId);

    await _firestore.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) {
        throw Exception('Товар не найден в базе: $productId');
      }

      final takenBy = snapshot.data()!['takenBy'] as String?;
      if (takenBy != userId) {
        throw Exception('Вернуть товар может только тот, кто его взял');
      }

      txn.update(ref, {
        'status': AppConstants.statusAvailable,
        'takenBy': null,
        'takenAt': null,
      });
    });
  }

  /// Поток изменений: подписка вместо опроса — как только данные изменились
  /// у кого-то, новая пачка приезжает автоматически.
  Stream<List<ProductModel>> productsStream() {
    return _products.snapshots().map(
          (snapshot) => snapshot.docs.map(ProductModel.fromFirestore).toList(),
        );
  }
}
