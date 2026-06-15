import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';

class ImageStorageService {
  Future<String> saveProductImageLocally(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'product_images'));
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
    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final request = await HttpClient().postUrl(uri);
    request.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');

    final body = StringBuffer();
    body.writeln('--$boundary');
    body.writeln('Content-Disposition: form-data; name="key"');
    body.writeln();
    body.writeln(AppConstants.imgbbApiKey);
    body.writeln('--$boundary');
    body.writeln('Content-Disposition: form-data; name="image"');
    body.writeln();
    body.writeln(base64Image);
    body.writeln('--$boundary');
    body.writeln('Content-Disposition: form-data; name="name"');
    body.writeln();
    body.writeln(productId);
    body.writeln('--$boundary--');

    request.write(body.toString());
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      throw Exception('imgbb upload failed (${response.statusCode}): $responseBody');
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final url = json['data']?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('imgbb returned no URL');
    }

    return url;
  }
}
