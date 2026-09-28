import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';
import 'package:warehouse_app/presentation/providers/product_provider.dart';

/// Экран операции над товаром: «Взять» / «Вернуть».
///
/// Три состояния кнопки по комбинации `status` и `takenBy`:
/// свободен → взять; занят мной → вернуть; занят другим → ничего нельзя.
class ProductOperationScreen extends ConsumerWidget {
  final String productId;

  const ProductOperationScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));
    final authState = ref.watch(authStateProvider);
    final currentUser = authState is AuthSuccess ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Операция с товаром')),
      body: productAsync.when(
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
          final isTakenByMe = product.status == AppConstants.statusTaken &&
              product.takenBy == currentUser?.id;
          final isTakenByOther =
              product.status == AppConstants.statusTaken && !isTakenByMe;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Статус: ${product.status}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (product.takenBy != null)
                          Text(
                            'Взят пользователем: ${product.takenBy}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (product.status == AppConstants.statusAvailable &&
                    currentUser != null)
                  _ActionButton(
                    label: 'Взять товар',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onPressed: () => _run(
                      context,
                      ref,
                      () => ref
                          .read(productsNotifierProvider.notifier)
                          .takeProduct(productId, currentUser.id),
                      'Товар успешно взят',
                    ),
                  )
                else if (isTakenByMe)
                  _ActionButton(
                    label: 'Вернуть товар',
                    icon: Icons.undo,
                    color: Colors.orange,
                    onPressed: () => _run(
                      context,
                      ref,
                      () => ref
                          .read(productsNotifierProvider.notifier)
                          .returnProduct(productId, currentUser!.id),
                      'Товар успешно возвращён',
                    ),
                  )
                else if (isTakenByOther)
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

  /// Общая часть всех действий: выполнить, обновить кэш, показать результат.
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      ref.invalidate(productProvider(productId));
      ref.invalidate(productsNotifierProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }
}
