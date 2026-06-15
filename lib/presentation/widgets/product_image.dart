import 'dart:io';

import 'package:flutter/material.dart';

/// Safe product thumbnail: local file path or network URL with bounds and fallback.
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.cover,
  });

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _placeholder(context);
    }

    final borderRadius = BorderRadius.circular(8);
    Widget image;

    if (_isNetwork) {
      image = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: (width * 2).toInt(),
        cacheHeight: (height * 2).toInt(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    } else {
      final file = File(imageUrl);
      image = FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          } else if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              file,
      width: width,
      height: height,
              fit: fit,
              cacheWidth: (width * 2).toInt(),
              cacheHeight: (height * 2).toInt(),
              errorBuilder: (_, __, ___) => _placeholder(context),
    );
          } else {
            return _placeholder(context);
  }
        },
      );
}

    return ClipRRect(borderRadius: borderRadius, child: image);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: width * 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

