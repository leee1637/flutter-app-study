import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';
import 'package:warehouse_app/presentation/providers/product_provider.dart';

class ProductOperationScreen extends ConsumerWidget {
  final String productId;

  const ProductOperationScreen({ super.key, required this.productId });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productFuture = ref.watch(productProvider(productId));
    final authState = ref.watch(authStateProvider);

    String? currentUserId;
    if (authState is AuthSuccess) {
      currentUserId = authState.user.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Операция с товаром'),
      ),
      body: productFuture.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ошибка: $error'),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
        data: (product) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Статус: ${product.status}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (product.takenBy != null && product.takenAt != null)
                          Text(
                            'Взят пользователем: ${product.takenBy}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (product.status == 'available' && currentUserId != null)
                  ElevatedButton(
                    onPressed: () async {
                      final notifier = ref.read(productsNotifierProvider.notifier);
                      try {
                        await notifier.takeProduct(productId, currentUserId!);
                        ref.invalidate(productProvider(productId));
                        ref.invalidate(productsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Товар успешно взят')),
                          );
                          context.pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка при взятии товара: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Взять товар', style: TextStyle(fontSize: 18)),
                  )
                else if (product.status == 'taken' && product.takenBy == currentUserId)
                  ElevatedButton(
                    onPressed: () async {
                      final notifier = ref.read(productsNotifierProvider.notifier);
                      try {
                        await notifier.returnProduct(productId, currentUserId!);
                        ref.invalidate(productProvider(productId));
                        ref.invalidate(productsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Товар успешно возвращен')),
                          );
                          context.pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка при возврате товара: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Вернуть товар', style: TextStyle(fontSize: 18)),
                  )
                else if (product.status == 'taken' && product.takenBy != currentUserId)
                  const Text(
                    'Товар уже занят другим пользователем',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}