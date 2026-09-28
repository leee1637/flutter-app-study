import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';

/// Работа с фотографией товара.
///
/// Два сценария:
/// * [uploadProductImage] — заливка на imgbb, нужен интернет. Возвращает
///   публичную ссылку, которую можно зашить в QR-код;
/// * [saveProductImageLocally] — сохранение во внутреннюю папку приложения.
///   Используется в офлайне: фото остаётся доступно на устройстве, а QR
///   получает вид `product://<id>` вместо веб-ссылки.
class ImageStorageService {
  Future<String> saveProductImageLocally(File source) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(documentsDir.path, 'product_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = p.join(imagesDir.path, fileName);
    await source.copy(destPath);
    return destPath;
  }

  Future<String> uploadProductImage(File file, String productId) async {
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final boundary = '----FormBoundary${DateTime.now().millisecondsSinceEpoch}';
    final uri = Uri.parse(AppConstants.imgbbUploadEndpoint);
    final request = await HttpClient().postUrl(uri);
    request.headers
        .set('Content-Type', 'multipart/form-data; boundary=$boundary');

    // imgbb принимает картинку либо как файл, либо как base64-строку.
    // Отправляем base64 — так не нужно вручную подставлять filename
    // и Content-Type каждой части multipart-тела.
    final body = StringBuffer()
      ..writeln('--$boundary')
      ..writeln('Content-Disposition: form-data; name="key"')
      ..writeln()
      ..writeln(AppConstants.imgbbApiKey)
      ..writeln('--$boundary')
      ..writeln('Content-Disposition: form-data; name="image"')
      ..writeln()
      ..writeln(base64Image)
      ..writeln('--$boundary')
      ..writeln('Content-Disposition: form-data; name="name"')
      ..writeln()
      ..writeln(productId)
      ..writeln('--$boundary--');

    request.write(body.toString());
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      throw Exception('imgbb вернул ошибку ${response.statusCode}');
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Неожиданный ответ imgbb');
    }

    final data = decoded['data'];
    final url = data is Map<String, dynamic> ? data['url'] as String? : null;
    if (url == null || url.isEmpty) {
      throw Exception('imgbb не вернул ссылку на изображение');
    }

    return url;
  }
}
