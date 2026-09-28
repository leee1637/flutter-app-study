import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_app/core/utils/qr_payload.dart';

void main() {
  group('QrPayload.encode', () {
    test('кладёт ссылку на фото и id в query-параметр', () {
      const qr = QrPayload(
        id: 'abc-123',
        name: 'Перфоратор',
        imageUrl: 'https://i.ibb.co/xyz/photo.jpg',
      );

      expect(qr.encode(), 'https://i.ibb.co/xyz/photo.jpg?product_id=abc-123');
    });

    test('дописывает &, если в ссылке уже есть query', () {
      const qr = QrPayload(
        id: 'abc-123',
        name: 'Перфоратор',
        imageUrl: 'https://i.ibb.co/xyz/photo.jpg?w=800',
      );

      expect(
        qr.encode(),
        'https://i.ibb.co/xyz/photo.jpg?w=800&product_id=abc-123',
      );
    });

    test('без публичной ссылки отдаёт product://', () {
      const qr = QrPayload(
        id: 'abc-123',
        name: 'Перфоратор',
        imageUrl: '/data/user/0/app/product_images/123.jpg',
      );

      expect(qr.encode(), 'product://abc-123');
    });
  });

  group('QrPayload.tryParse', () {
    test('достаёт id из нашего формата', () {
      final parsed = QrPayload.tryParse(
        'https://i.ibb.co/xyz/photo.jpg?product_id=abc-123',
      );

      expect(parsed, isNotNull);
      expect(parsed!.id, 'abc-123');
    });

    test('понимает старую ссылку Firebase Storage с %2F', () {
      final parsed = QrPayload.tryParse(
        'https://firebasestorage.googleapis.com/v0/b/demo/'
        'o/products%2Fabc-123.jpg?alt=media',
      );

      expect(parsed?.id, 'abc-123');
    });

    test('понимает старую ссылку Firebase Storage со слэшем', () {
      final parsed = QrPayload.tryParse(
        'https://firebasestorage.googleapis.com/v0/b/demo/'
        'o/products/abc-123.jpg',
      );

      expect(parsed?.id, 'abc-123');
    });

    test('понимает deep-link /qr/{id}', () {
      final parsed =
          QrPayload.tryParse('https://site.firebaseapp.com/qr/abc-123');

      expect(parsed?.id, 'abc-123');
    });

    test('понимает JSON', () {
      final parsed = QrPayload.tryParse(
        '{"id":"abc-123","name":"Перфоратор","description":"1200 Вт"}',
      );

      expect(parsed?.id, 'abc-123');
      expect(parsed?.name, 'Перфоратор');
      expect(parsed?.description, '1200 Вт');
    });

    test('понимает голый id', () {
      expect(QrPayload.tryParse('abc-123')?.id, 'abc-123');
    });

    test('null на пустой строке', () {
      expect(QrPayload.tryParse('   '), isNull);
    });

    test('null на мусорном тексте вместо id', () {
      expect(QrPayload.tryParse('просто какой-то текст'), isNull);
    });
  });
}
