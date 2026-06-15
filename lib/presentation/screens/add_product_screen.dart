import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:warehouse_app/core/services/image_storage_service.dart';
import 'package:warehouse_app/core/utils/qr_payload.dart';
import 'package:warehouse_app/data/models/product_model.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';
import 'package:warehouse_app/presentation/providers/product_provider.dart';
import 'package:warehouse_app/presentation/widgets/custom_text_field.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _imagePath;
  String? _qrData;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    bool isAdmin = false;

    if (authState is AuthSuccess) {
      isAdmin = authState.user.role == 'admin';
    }

    if (!isAdmin) {
    return Scaffold(
        appBar: AppBar(title: const Text('Недостаточно прав')),
        body: const Center(
          child: Text('Только администратор может добавлять товары'),
              ),
    );
  }

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить товар')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              InkWell(
                onTap: _selectImageFromDialog,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imagePath != null
                      ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                      : const Icon(
                          Icons.camera_alt,
                          size: 60,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                label: 'Название',
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Описание',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAndGenerateQR,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить и создать QR'),
              ),
              if (_qrData != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'QR-код товара',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  _qrData!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _qrData!.startsWith('http') ? Colors.blue : Colors.orange,
                  ),
                ),
                if (!_qrData!.startsWith('http'))
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Ссылка не доступна в браузере (изображение сохранено локально)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 220,
                    gapless: true,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _qrData!));
      ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ссылка скопирована в буфер обмена'),
                      ),
      );
                  },
                  child: const Text('Скопировать ссылку'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectImageFromDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Выбрать изображение'),
          children: [
            SimpleDialogOption(
              onPressed: () async {
                Navigator.of(context).pop();
                await _selectImage(ImageSource.camera);
              },
              child: const Row(
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 16),
                  Text('Сделать фото'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.of(context).pop();
                await _selectImage(ImageSource.gallery);
              },
              child: const Row(
                children: [
                  Icon(Icons.image),
                  SizedBox(width: 16),
                  Text('Выбрать из галереи'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Row(
                children: [
                  Icon(Icons.close),
                  SizedBox(width: 16),
                  Text('Отмена'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        final result = await ImagePicker().pickImage(source: source);
        if (result != null) {
          setState(() => _imagePath = result.path);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Разрешение на камеру отклонено')),
          );
        }
      }
    } else {
      final permission = Platform.isAndroid ? Permission.storage : Permission.photos;
      final status = await permission.request();
      if (status.isGranted || status.isLimited) {
        final result = await ImagePicker().pickImage(source: source);
        if (result != null) {
          setState(() => _imagePath = result.path);
    }
      } else {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Разрешение на доступ к галерее отклонено')),
        );
      }
      }
    }
  }

  Future<void> _saveAndGenerateQR() async {
    if (!_formKey.currentState!.validate()) return;
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
    final imagePath = _imagePath;

    if (imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите изображение')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final id = const Uuid().v4();
      final imageFile = File(imagePath);
      final imageStorage = ImageStorageService();

      String imageUrl;
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      if (!isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет интернета. Подключитесь к сети для создания ссылки на фото.')),
          );
        }
        return;
      }

      imageUrl = await imageStorage.uploadProductImage(imageFile, id);

      final product = ProductModel(
        id: id,
        name: name,
        description: description.isEmpty ? '-' : description,
        imageUrl: imageUrl,
        status: 'available',
      );

      await ref.read(productsNotifierProvider.notifier).addProduct(product);
      ref.invalidate(productsProvider);

      final qr = QrPayload(id: id, name: name, description: description, imageUrl: imageUrl);
      setState(() => _qrData = qr.encode());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки в облако: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
  }
}
}
