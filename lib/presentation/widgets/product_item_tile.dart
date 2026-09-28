import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/presentation/widgets/product_image.dart';
import 'package:warehouse_app/presentation/widgets/status_indicator.dart';

class ProductItemTile extends StatelessWidget {
  final ProductModel product;

  const ProductItemTile({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ProductImage(
        imageUrl: product.imageUrl,
        width: 60,
        height: 60,
      ),
      title: Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        product.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: StatusIndicator(status: product.status),
      onTap: () {
        context.push('/product/${product.id}');
      },
    );
  }
}
