import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_app/data/models/product_model.dart';

void main() {
  group('ProductModel.fromMap', () {
    test('читает товар из строки SQLite', () {
      final product = ProductModel.fromMap({
        'id': 'abc-123',
        'name': 'Перфоратор',
        'description': '1200 Вт',
        'image_url': 'https://i.ibb.co/xyz/photo.jpg',
        'status': 'taken',
        'taken_by': 'user-1',
        'taken_at': '2026-01-15T10:30:00.000',
      });

      expect(product.id, 'abc-123');
      expect(product.name, 'Перфоратор');
      expect(product.status, 'taken');
      expect(product.takenBy, 'user-1');
      expect(product.takenAt, isNotNull);
    });

    test('NULL в nullable-полях превращается в null, а не в строку "null"', () {
      final product = ProductModel.fromMap({
        'id': 'abc-123',
        'name': 'Молоток',
        'description': '-',
        'image_url': 'https://i.ibb.co/xyz/h.jpg',
        'status': 'available',
        'taken_by': null,
        'taken_at': null,
      });

      expect(product.takenBy, isNull);
      expect(product.takenAt, isNull);
    });

    test('битый taken_at не роняет разбор', () {
      final product = ProductModel.fromMap({
        'id': 'abc-123',
        'name': 'Молоток',
        'description': '-',
        'image_url': 'https://i.ibb.co/xyz/h.jpg',
        'status': 'taken',
        'taken_by': 'user-1',
        'taken_at': 'не дата',
      });

      expect(product.takenBy, 'user-1');
      expect(product.takenAt, isNull);
    });
  });

  group('ProductModel.copyWith', () {
    test('меняет статус и владельца', () {
      final product = ProductModel(
        id: 'abc-123',
        name: 'Перфоратор',
        description: '1200 Вт',
        imageUrl: 'https://i.ibb.co/xyz/photo.jpg',
        status: 'available',
      );

      final taken = product.copyWith(status: 'taken', takenBy: 'user-1');

      expect(taken.status, 'taken');
      expect(taken.takenBy, 'user-1');
      // Остальные поля должны сохраниться.
      expect(taken.id, product.id);
      expect(taken.name, product.name);
      expect(taken.imageUrl, product.imageUrl);
      // Исходный объект не меняется: copyWith возвращает новый.
      expect(product.status, 'available');
      expect(product.takenBy, isNull);
    });

    test('возврат очищает владельца и время', () {
      final product = ProductModel(
        id: 'abc-123',
        name: 'Перфоратор',
        description: '1200 Вт',
        imageUrl: 'https://i.ibb.co/xyz/photo.jpg',
        status: 'taken',
        takenBy: 'user-1',
        takenAt: DateTime(2026, 1, 15, 10, 30),
      );

      final returned = product.copyWith(
        status: 'available',
        takenBy: null,
        takenAt: null,
      );

      expect(returned.status, 'available');
      expect(returned.takenBy, isNull);
      expect(returned.takenAt, isNull);
    });
  });
}
