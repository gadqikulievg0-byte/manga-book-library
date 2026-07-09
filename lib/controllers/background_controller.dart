import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BackgroundController extends GetxController {
  static const String _boxName = 'settings';
  late Box _box;

  final RxString backgroundImage = RxString('');
  final RxDouble opacity = 0.15.obs;

  @override
  void onInit() {
    super.onInit();
    _initBox();
  }

  Future<void> _initBox() async {
    _box = Hive.box(_boxName);
    _loadBackground();
  }

  void _loadBackground() {
    try {
      final saved = _box.get('background_image', defaultValue: '');
      if (saved != null && saved.toString().isNotEmpty) {
        backgroundImage.value = saved.toString();
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  Future<void> pickBackground() async {
    try {
      FilePickerResult? result;

      if (kIsWeb) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
      }

      if (result != null) {
        final file = result.files.single;

        String? imageData;
        if (kIsWeb) {
          final bytes = file.bytes;
          if (bytes != null) {
            imageData = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          }
        } else {
          if (file.path != null) {
            imageData = file.path;
          }
        }

        if (imageData != null) {
          backgroundImage.value = imageData;
          await _box.put('background_image', imageData);
          Get.snackbar('Успех', 'Фон изменен');
        }
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить фон: $e');
    }
  }

  void removeBackground() {
    backgroundImage.value = '';
    _box.delete('background_image');
    Get.snackbar('Фон удален', '');
  }

  void setOpacity(double value) {
    opacity.value = value;
  }
}
