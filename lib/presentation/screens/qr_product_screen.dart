import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_app/core/utils/qr_payload.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';
import 'package:warehouse_app/presentation/providers/product_provider.dart';
import 'package:warehouse_app/presentation/widgets/product_image.dart';
import 'package:warehouse_app/presentation/widgets/status_indicator.dart';

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
        error: (error, stack) => Center(child: Text('Ошибка: ${error.toString()}')),
        data: (product) {
          String? currentUserId;
          bool isAuthenticated = false;

          if (authState is AuthSuccess) {
            currentUserId = authState.user.id;
            isAuthenticated = true;
          }

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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Взял: ${product.takenBy}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (product.takenAt != null)
                          Text(
                            'Когда: ${DateFormat('dd.MM.yyyy HH:mm').format(product.takenAt!.toLocal())}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isAuthenticated && currentUserId != null
                          ? () async {
                              if (currentUserId == null) return;

                              try {
                                final notifier = ref.read(productsNotifierProvider.notifier);

                                if (product.status == 'available') {
                                  await notifier.takeProduct(product.id, currentUserId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Товар успешно взят')),
                                    );
                                    ref.invalidate(productProvider(product.id));
                                  }
                                } else if (product.status == 'taken' &&
                                    product.takenBy == currentUserId) {
                                  await notifier.returnProduct(product.id, currentUserId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Товар успешно возвращен')),
                                    );
                                    ref.invalidate(productProvider(product.id));
                                  }
                                } else if (product.status == 'taken') {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Товар занят другим пользователем'),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Ошибка: $e')),
                                  );
                                }
                              }
                            }
                          : null,
                        icon: Icon(product.status == 'available'
                            ? Icons.check_outlined
                            : Icons.undo_outlined),
                        label: Text(
                          product.status == 'available'
                              ? 'Взять'
                              : (product.takenBy == currentUserId ? 'Вернуть' : 'Занят'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: product.status == 'available'
                              ? Colors.green
                              : (product.takenBy == currentUserId
                                  ? Colors.orange
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}