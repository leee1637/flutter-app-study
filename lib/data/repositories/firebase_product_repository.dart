import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/data/repositories/product_repository.dart';
class FirebaseProductRepository implements ProductRepository {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection(AppConstants.productsCollection);

  Future<List<ProductModel>> getAllProducts() async {
    final snapshot = await _productsCollection.get();
    return snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    final QuerySnapshot snapshot = await _productsCollection.get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final DocumentSnapshot snapshot = await _productsCollection.doc(id).get();
    if (snapshot.exists) {
      return ProductModel.fromFirestore(snapshot);
    } else {
      throw Exception('Product with ID $id not found in Firebase');
    }
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    await _productsCollection.doc(product.id).set(product.toFirestoreMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _productsCollection
        .doc(product.id)
        .update(product.toFirestoreMap());
  }

  @override
  Future<void> takeProduct(String productId, String userId) async {
    await _productsCollection.doc(productId).update({
      'status': 'taken',
      'takenBy': userId,
      'takenAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> returnProduct(String productId, String userId) async {
    await _productsCollection.doc(productId).update({
      'status': 'available',
      'takenBy': null,
      'takenAt': null,
    });
  }

  Stream<List<ProductModel>> productsStream() {
    return _productsCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }
}

