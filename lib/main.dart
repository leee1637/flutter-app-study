import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/core/app_services.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/core/firebase_options.dart';
import 'package:warehouse_app/data/sync/sync_manager.dart';
import 'package:warehouse_app/presentation/providers/router_provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
  await FirebaseConfig.initialize();
    print('Firebase initialized successfully');

    // Initialize SyncManager but don't wait for it to complete
  AppServices.syncManager = SyncManager();
    // Start initialization in background
    AppServices.syncManager!.initialize().then((_) {
    print('Sync manager initialized successfully');
    }).catchError((e) {
      print('Failed to initialize sync manager: $e');
    });

    runApp(const ProviderScope(child: WarehouseApp()));
  } catch (e) {
    print('Failed to initialize app: $e');

    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
























          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 100,
              ),
              const SizedBox(height: 20),
              const Text('Error starting application'),
            ],
          ),
        ),
      ),
    ));
  }
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