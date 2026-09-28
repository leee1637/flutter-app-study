import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/core/utils/qr_payload.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/data/repositories/product_repository.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';
import 'package:warehouse_app/presentation/providers/product_provider.dart';

/// Сканирование QR-кода товара.
///
/// Смысл сценария: сотрудник отсканировал ярлык → товар взят на него.
/// Повторное сканирование того же ярлыка → товар возвращён.
/// Никаких кнопок — каждое перемещение подтверждается физическим действием.
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

    // Поток баркодов приходит каждый кадр (десятки раз в секунду),
    // поэтому без флагов ниже один QR обработался бы множество раз.
    _cameraController.barcodes.listen((barcodes) {
      if (!_isScanning || _isProcessing) return;

      for (final barcode in barcodes.barcodes) {
        final raw = barcode.rawValue;
        if (raw != null && raw.isNotEmpty) {
          _processQrCode(raw);
          break;
        }
      }
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      // Отказали один раз — ведём в настройки, повторный запрос уже не покажут.
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
        _resultMessage = 'Некорректный QR-код';
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
    final repository = ref.read(productRepositoryProvider);

    try {
      final product = await repository.getProductById(parsed.id);
      final message = await _applyOperation(repository, product, userId);

      setState(() => _resultMessage = message);
    } catch (e) {
      setState(() => _resultMessage = 'Ошибка: $e');
    } finally {
      // Списки и карточки на других экранах должны увидеть новое состояние.
      ref.invalidate(productsNotifierProvider);
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      _scheduleResumeScanning();
    }
  }

  /// Возвращает товар, если он свободен; возвращает товар, если его взяли мы.
  Future<String> _applyOperation(
    ProductRepository repository,
    ProductModel product,
    String userId,
  ) async {
    if (product.status == AppConstants.statusAvailable) {
      await repository.takeProduct(product.id, userId);
      return 'Товар «${product.name}» взят';
    }

    if (product.status == AppConstants.statusTaken &&
        product.takenBy == userId) {
      await repository.returnProduct(product.id, userId);
      return 'Товар «${product.name}» возвращён';
    }

    if (product.status == AppConstants.statusTaken) {
      return 'Товар «${product.name}» занят другим пользователем';
    }

    return 'Неизвестный статус товара: ${product.status}';
  }

  void _scheduleResumeScanning() {
    // Показываем результат пару секунд и продолжаем: удобно отсканировать
    // подряд несколько ярлыков, не открывая и не закрывая экран.
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isScanning = true;
        _parsedQr = null;
        _resultMessage = null;
      });
    });
  }

  void _toggleTorch() {
    _cameraController.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final loggedIn = authState is AuthSuccess;

    if (!loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Только авторизованные пользователи могут сканировать QR-коды',
            ),
          ),
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
            tooltip: 'Фонарик',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _cameraController),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
          if (_resultMessage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _ResultBanner(
                payload: _parsedQr,
                message: _resultMessage!,
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final QrPayload? payload;
  final String message;

  const _ResultBanner({required this.payload, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (payload != null) ...[
            Text(
              'ID: ${payload!.id}',
              style: const TextStyle(color: Colors.white),
            ),
            if (payload!.name != payload!.id)
              Text(
                'Название: ${payload!.name}',
                style: const TextStyle(color: Colors.white),
              ),
            const SizedBox(height: 8),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
