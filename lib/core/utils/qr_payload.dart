import 'dart:convert';

/// QR encodes a browser-openable image URL; scan extracts product ID from it.
class QrPayload {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;

  QrPayload({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  /// Returns a real browser-openable URL to the product photo.
  /// Embeds product_id as query param so scanner can extract it.
  String encode() {
    if (imageUrl != null && imageUrl!.startsWith('http')) {
      final separator = imageUrl!.contains('?') ? '&' : '?';
      return '$imageUrl${separator}product_id=$id';
    }
    return 'product://$id';
  }

  static QrPayload? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    // Try to extract product_id from query params (our own QR format)
    if (uri.queryParameters.containsKey('product_id')) {
      final id = uri.queryParameters['product_id']!;
      if (id.isNotEmpty) {
        return QrPayload(id: id, name: id, imageUrl: trimmed);
      }
    }

    // Try to extract product ID from a Firebase Storage image URL.
    final productId = _extractIdFromImageUrl(trimmed);
    if (productId != null) {
      return QrPayload(id: productId, name: productId, imageUrl: trimmed);
    }

    // Try to extract from a deep-link path like /qr/{id}
    if (uri.pathSegments.isNotEmpty) {
      final segments = uri.pathSegments;
      final qrIndex = segments.indexOf('qr');
      if (qrIndex >= 0 && qrIndex + 1 < segments.length) {
        final id = Uri.decodeComponent(segments[qrIndex + 1]);
        if (id.isNotEmpty) {
          return QrPayload(id: id, name: id, imageUrl: trimmed);
        }
      }
    }

    // Try JSON payload
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
    } catch (_) {}

    // Plain product id
    return QrPayload(id: trimmed, name: trimmed);
  }

  static String? _extractIdFromImageUrl(String url) {
    final match = RegExp(r'products(?:%2F|/)([^&?]+?)\.jpg').firstMatch(url);
    if (match != null) {
      return Uri.decodeComponent(match.group(1)!);
    }
    return null;
  }

  static String? extractProductId(String raw) => tryParse(raw)?.id;
}
