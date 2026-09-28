import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/core/app_services.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/core/firebase_options.dart';
import 'package:warehouse_app/data/sync/sync_manager.dart';
import 'package:warehouse_app/presentation/providers/router_provider.dart';

Future<void> main() async {
  // Обязательная инициализация связки Flutter с платформой.
  // Без неё любой вызов plugin-канала (Firebase, sqflite, камера)
  // упадёт с «Binding has not yet been initialized».
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseConfig.initialize();
  } catch (e) {
    runApp(_StartupErrorApp(message: 'Не удалось подключиться к Firebase: $e'));
    return;
  }

  // Синхронизация запускается в фоне и не блокирует первый экран:
  // на плохой сети ожидание здесь добавило бы секунды к запуску.
  AppServices.syncManager = SyncManager();
  AppServices.syncManager!.initialize();

  runApp(const ProviderScope(child: WarehouseApp()));
}

class WarehouseApp extends ConsumerWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Экран на случай, если приложение не смогло стартовать.
class _StartupErrorApp extends StatelessWidget {
  final String message;

  const _StartupErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'Ошибка запуска приложения',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
