import 'dart:convert';

/// Формат QR-кода товара.
///
/// В QR кладётся **не** JSON с товаром, а настоящая ссылка на фотографию:
/// `https://i.ibb.co/xxx.jpg?product_id=<uuid>`. Так код остаётся полезным
/// вне приложения — обычная камера телефона откроет его в браузере и покажет
/// фото товара, — а идентификатор для нашего сканера лежит в query-параметре.
class QrPayload {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;

  const QrPayload({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  /// Собирает содержимое QR-кода. Если есть публичная ссылка на фото —
  /// возвращаем её с идентификатором в query-параметре, иначе — `product://id`.
  String encode() {
    if (imageUrl != null && imageUrl!.startsWith('http')) {
      final separator = imageUrl!.contains('?') ? '&' : '?';
      return '$imageUrl${separator}product_id=$id';
    }
    // Фото лежит только на этом устройстве — публичной ссылки нет.
    return 'product://$id';
  }

  /// Разбор содержимого QR-кода.
  ///
  /// Стратегии перебираются по очереди: JSON → свой формат → старые ссылки
  /// Firebase Storage → путь `/qr/{id}` → «просто идентификатор».
  /// Такой каскад нужен, чтобы код работал и с ранними версиями приложения,
  /// и с QR, созданными сторонними инструментами.
  static QrPayload? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. JSON-объект с товаром. Проверяем первым и до разбора ссылки: строка
    // JSON содержит пробелы и кавычки, из-за чего Uri.tryParse вернёт null,
    // и до этой проверки мы бы просто не дошли.
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id'];
        if (id is String && id.isNotEmpty) {
          return QrPayload(
            id: id,
            name: decoded['name'] as String? ?? id,
            description: decoded['description'] as String?,
            imageUrl: decoded['imageUrl'] as String?,
          );
        }
      }
    } catch (_) {
      // Не JSON — значит, попробует следующая стратегия.
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    // 2. Наш собственный формат: ?product_id=<id>
    final queryId = uri.queryParameters['product_id'];
    if (queryId != null && queryId.isNotEmpty) {
      return QrPayload(id: queryId, name: queryId, imageUrl: trimmed);
    }

    // 3. Ссылка на картинку в Firebase Storage: products%2F<id>.jpg
    final storageId = _extractIdFromImageUrl(trimmed);
    if (storageId != null) {
      return QrPayload(id: storageId, name: storageId, imageUrl: trimmed);
    }

    // 4. Deep-link вида /qr/<id>
    final segments = uri.pathSegments;
    final qrIndex = segments.indexOf('qr');
    if (qrIndex >= 0 && qrIndex + 1 < segments.length) {
      final id = Uri.decodeComponent(segments[qrIndex + 1]);
      if (id.isNotEmpty) {
        return QrPayload(id: id, name: id, imageUrl: trimmed);
      }
    }

    // 5. Голый идентификатор. Отсекаем явно мусорный текст, чтобы
    // пользователь увидел «Некорректный QR-код», а не «Товар не найден: ...».
    return _looksLikeId(trimmed) ? QrPayload(id: trimmed, name: trimmed) : null;
  }

  /// Ссылка вида `.../products%2F<uuid>.jpg` (или `.../products/<uuid>.jpg`).
  static String? _extractIdFromImageUrl(String url) {
    final match = RegExp(r'products(?:%2F|/)([^&?]+?)\.jpg').firstMatch(url);
    if (match == null) return null;
    return Uri.decodeComponent(match.group(1)!);
  }

  /// Грубая проверка «это похоже на идентификатор, а не на произвольный текст».
  static bool _looksLikeId(String value) {
    if (value.length > 128) return false;
    return !RegExp(r'\s').hasMatch(value);
  }
}
