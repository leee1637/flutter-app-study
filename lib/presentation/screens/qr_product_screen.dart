import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/core/utils/qr_payload.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';
import 'package:warehouse_app/presentation/providers/product_provider.dart';
import 'package:warehouse_app/presentation/widgets/product_image.dart';
import 'package:warehouse_app/presentation/widgets/status_indicator.dart';

/// Просмотр товара, открытый по QR-ссылке: `/qr?code=<ссылка>`.
///
/// Сюда можно попасть deep link'ом с другого устройства, поэтому экран
/// доступен и без авторизации — но действия (взять/вернуть) доступны
/// только залогиненному пользователю.
class QRProductScreen extends ConsumerWidget {
  final String encodedQr;

  const QRProductScreen({super.key, required this.encodedQr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qr = QrPayload.tryParse(encodedQr);
    if (qr == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка QR-кода')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 50),
              SizedBox(height: 16),
              Text('Некорректный QR-код'),
            ],
          ),
        ),
      );
    }

    final productAsync = ref.watch(productProvider(qr.id));
    final authState = ref.watch(authStateProvider);
    final currentUser = authState is AuthSuccess ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Информация о товаре'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
        data: (product) {
          final isTakenByMe = product.status == AppConstants.statusTaken &&
              product.takenBy == currentUser?.id;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ProductImage(
                    imageUrl: product.imageUrl,
                    width: 220,
                    height: 220,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                StatusIndicator(status: product.status),
                if (product.takenBy != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Взял: ${product.takenBy}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (product.takenAt != null)
                    Text(
                      'Когда: '
                      '${DateFormat('dd.MM.yyyy HH:mm').format(product.takenAt!.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: currentUser == null
                        ? null
                        : () =>
                            _handleTap(context, ref, product, currentUser.id),
                    icon: Icon(
                      product.status == AppConstants.statusAvailable
                          ? Icons.check_outlined
                          : Icons.undo_outlined,
                    ),
                    label: Text(
                      product.status == AppConstants.statusAvailable
                          ? 'Взять'
                          : (isTakenByMe ? 'Вернуть' : 'Занят'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          product.status == AppConstants.statusAvailable
                              ? Colors.green
                              : (isTakenByMe ? Colors.orange : Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
    String userId,
  ) async {
    final notifier = ref.read(productsNotifierProvider.notifier);

    try {
      if (product.status == AppConstants.statusAvailable) {
        await notifier.takeProduct(product.id, userId);
      } else if (product.status == AppConstants.statusTaken &&
          product.takenBy == userId) {
        await notifier.returnProduct(product.id, userId);
      } else {
        _show(context, 'Товар занят другим пользователем');
        return;
      }

      ref.invalidate(productProvider(product.id));
      if (context.mounted) {
        _show(
            context,
            product.status == AppConstants.statusAvailable
                ? 'Товар успешно взят'
                : 'Товар успешно возвращён');
      }
    } catch (e) {
      if (context.mounted) {
        _show(context, 'Ошибка: $e');
      }
    }
  }

  void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
