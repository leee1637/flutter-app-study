import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:warehouse_app/presentation/providers/product_provider.dart';
import 'package:warehouse_app/presentation/providers/user_provider.dart';
import 'package:warehouse_app/presentation/widgets/product_image.dart';
import 'package:warehouse_app/presentation/widgets/status_indicator.dart';
import 'package:warehouse_app/core/utils/qr_payload.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String id;

  const ProductDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Карточка товара')),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
        data: (product) {
          // Generate QR payload
          final qrPayload = QrPayload(
            id: product.id,
            name: product.name,
            description: product.description,
            imageUrl: product.imageUrl,
          );
          final qrUrl = qrPayload.encode();

          final takenByAsync = product.takenBy != null
              ? ref.watch(userNameProvider(product.takenBy!))
              : null;

          return SingleChildScrollView(
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
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                StatusIndicator(status: product.status),
                if (product.takenBy != null) ...[
                  const SizedBox(height: 16),
                  if (takenByAsync != null)
                    takenByAsync.when(
                      data: (name) => Text(
                        'Взял: ${name ?? product.takenBy}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      loading: () => const Text('Взял: ...'),
                      error: (_, __) => Text('Взял: ${product.takenBy}'),
                    )
                  else
                    Text('Взял: ${product.takenBy}'),
                  if (product.takenAt != null)
                    Text(
                      'Когда: ${DateFormat('dd.MM.yyyy HH:mm').format(product.takenAt!.toLocal())}',
                    ),
                ],
                const SizedBox(height: 24),
                // QR Code section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'QR-код товара',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      QrImageView(
                        data: qrUrl,
                        version: QrVersions.auto,
                        size: 220,
                        gapless: true,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        qrUrl,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: qrUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ссылка скопирована')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Скопировать ссылку'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
