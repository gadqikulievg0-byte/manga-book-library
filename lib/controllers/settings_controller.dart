import 'dart:io';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import '../data/repositories/book_repository.dart';
import '../core/snackbar_helper.dart';

class SettingsController extends GetxController {
  static const String _boxName = 'settings';
  late Box _box;

  final libraryPath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _box = Hive.box(_boxName);
    _loadSettings();
  }

  void _loadSettings() {
    final saved = _box.get('library_path', defaultValue: '');
    if (saved != null && saved.toString().isNotEmpty) {
      libraryPath.value = saved.toString();
    } else {
      libraryPath.value = path.join(Directory.current.path, 'library');
    }
  }

  Future<void> changeLibraryPath() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        libraryPath.value = result;
        await _box.put('library_path', result);
        SnackbarHelper.success('Путь к библиотеке изменен');
        // Перезагружаем книги
        try {
          final repo = Get.find<BookRepository>();
          repo.loadBooks();
        } catch (e) {
          // Если репозиторий еще не зарегистрирован, игнорируем
        }
      }
    } catch (e) {
      SnackbarHelper.error('Не удалось изменить путь: $e');
    }
  }

  String get currentLibraryPath => libraryPath.value;
}
