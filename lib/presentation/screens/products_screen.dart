import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';
import 'package:warehouse_app/presentation/providers/product_provider.dart';
import 'package:warehouse_app/presentation/widgets/product_item_tile.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthUnauthenticated) {
        if (context.mounted) {
                      context.go('/');
        }
      }
    });

    final productsAsync = ref.watch(productsNotifierProvider);
    final authState = ref.watch(authStateProvider);
    String? currentUserId;
    if (authState is AuthSuccess) {
      currentUserId = authState.user.id;
    }

    String searchTerm = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары'),
        actions: [
                  IconButton(
            onPressed: () async {
              if (searchTerm.isNotEmpty) {
                _searchController.clear();
              }
              ref.invalidate(productsProvider);
              await ref.read(productsNotifierProvider.notifier).loadProducts();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'scan',
                child: ListTile(
                  leading: Icon(Icons.qr_code_scanner),
                  title: Text('Сканировать QR'),
      ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Выйти'),
                ),
              ),
              if (currentUserId != null)
                const PopupMenuItem(
                  value: 'add',
                  child: ListTile(
                    leading: Icon(Icons.add),
                    title: Text('Добавить товар'),
                  ),
                ),
            ],
            onSelected: (value) async {
              if (value == 'scan') {
                context.push('/scan');
              } else if (value == 'logout') {
                await ref.read(authStateProvider.notifier).signOut();
                if (context.mounted) context.go('/');
              } else if (value == 'add' && currentUserId != null) {
                context.push('/add-product');
  }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Поиск товаров...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Ошибка: $error')),
              data: (products) {
                List filteredProducts = products;
                if (searchTerm.isNotEmpty) {
                  filteredProducts = products
                      .where((product) =>
                          product.name.toLowerCase().contains(searchTerm) ||
                          product.description.toLowerCase().contains(searchTerm))
                      .toList();
}

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(productsProvider);
                    await ref.read(productsNotifierProvider.notifier).loadProducts();
                  },
                  child: filteredProducts.isEmpty
                      ? const Center(
                          child: Text('Нет товаров для отображения'),
                        )
                      : ListView.separated(
                          itemCount: filteredProducts.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return ProductItemTile(product: product);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

