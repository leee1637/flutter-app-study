import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:warehouse_app/core/utils/qr_payload.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';
import 'package:warehouse_app/presentation/providers/product_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  QrPayload? _parsedQr;
  String? _resultMessage;
  bool _isScanning = true;
  bool _torchOn = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();

    _cameraController.barcodes.listen((barcodes) {
      if (!_isScanning || _isProcessing) return;

      for (final barcode in barcodes.barcodes) {
        final raw = barcode.rawValue;
        if (raw?.isNotEmpty ?? false) {
          _processQrCode(raw!);
          break;
        }
      }
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isDenied) {
      await openAppSettings();
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String raw) async {
    setState(() {
      _isScanning = false;
      _isProcessing = true;
    });

    final parsed = QrPayload.tryParse(raw);
    if (parsed == null) {
      setState(() {
        _parsedQr = null;
        _resultMessage = 'Пустой или некорректный QR-код';
        _isProcessing = false;
      });
      _scheduleResumeScanning();
      return;
    }

    setState(() => _parsedQr = parsed);

    final authState = ref.read(authStateProvider);
    if (authState is! AuthSuccess) {
      setState(() {
        _resultMessage = 'Требуется авторизация';
        _isProcessing = false;
      });
      _scheduleResumeScanning();
      return;
    }

    final userId = authState.user.id;
    final repo = ref.read(productRepositoryProviderFromProviders);

    try {
      final product = await repo.getProductById(parsed.id);

      if (product.status == 'available') {
        await repo.takeProduct(parsed.id, userId);
        ref.invalidate(productsProvider);
        ref.invalidate(productProvider(parsed.id));
        setState(() {
          _resultMessage = 'Товар «${product.name}» взят';
        });
      } else if (product.status == 'taken' && product.takenBy == userId) {
        await repo.returnProduct(parsed.id, userId);
        ref.invalidate(productsProvider);
        ref.invalidate(productProvider(parsed.id));
        setState(() {
          _resultMessage = 'Товар «${product.name}» возвращён';
        });
      } else if (product.status == 'taken') {
        setState(() {
          _resultMessage = 'Товар «${product.name}» занят другим пользователем';
        });
      } else {
        setState(() {
          _resultMessage = 'Неизвестный статус товара: ${product.status}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Ошибка: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      _scheduleResumeScanning();
    }
  }

  void _scheduleResumeScanning() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _parsedQr = null;
          _resultMessage = null;
        });
      }
    });
  }

  void _toggleTorch() {
    _cameraController.toggleTorch();
    setState(() {
      _torchOn = !_torchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final loggedIn = authState is AuthSuccess;

    if (!loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: const Center(
          child: Text('Только авторизованные пользователи могут сканировать QR-коды'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование QR'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_resultMessage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_parsedQr != null) ...[
                      Text(
                        'ID: ${_parsedQr!.id}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (_parsedQr!.name != _parsedQr!.id)
                        Text(
                          'Название: ${_parsedQr!.name}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      _resultMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
