import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/book.dart';
import '../data/models/volume.dart';
import '../data/repositories/book_repository.dart';
import 'category_controller.dart';
import 'import_controller.dart'; // Добавьте эту строку в начале файла

class BookController extends GetxController {
  final BookRepository _repository = Get.find<BookRepository>();
  final CategoryController _categoryController = Get.find<CategoryController>();

  final book = Rxn<Book>();
  final title = ''.obs;
  final description = ''.obs;
  final coverPath = ''.obs;
  final volumes = <Volume>[].obs;
  final selectedCategories = <String>[].obs;
  final selectedStatus = BookStatus.newBook.obs;
  final isLoading = false.obs;

  // Флаг для предотвращения повторного сохранения
  bool _isSaving = false;

  List<Volume>? _originalVolumes;

  void loadBook(String? bookId) {
    if (bookId != null) {
      final existingBook = _repository.getBookById(bookId);
      if (existingBook != null) {
        book.value = existingBook;
        title.value = existingBook.title;
        description.value = existingBook.description ?? '';
        coverPath.value = existingBook.coverPath ?? '';
        selectedCategories.value = List.from(existingBook.categories);
        selectedStatus.value = existingBook.status;
        _originalVolumes = existingBook.volumes
            .map((v) => Volume(
                id: v.id,
                title: v.title,
                filePath: v.filePath,
                lastReadPage: v.lastReadPage))
            .toList();
        volumes.assignAll(existingBook.volumes);
      }
    } else {
      _originalVolumes = null;
      volumes.clear();
      selectedCategories.clear();
      selectedStatus.value = BookStatus.newBook;
    }
  }

  void clear() {
    book.value = null;
    title.value = '';
    description.value = '';
    coverPath.value = '';
    volumes.clear();
    selectedCategories.clear();
    selectedStatus.value = BookStatus.newBook;
    _originalVolumes = null;
    isLoading.value = false;
    _isSaving = false;
  }

  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
  }

  void addNewCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isNotEmpty) {
      final categoryController = Get.find<CategoryController>();
      await categoryController.addCategory(trimmed);
      if (!selectedCategories.contains(trimmed)) {
        selectedCategories.add(trimmed);
      }
    }
  }

  void setStatus(BookStatus status) {
    selectedStatus.value = status;
  }

  Future<void> addVolume() async {
    try {
      FilePickerResult? result;

      if (kIsWeb) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
      }

      if (result != null) {
        final file = result.files.single;
        String filePath;
        String fileName;

        if (kIsWeb) {
          filePath = file.name;
          fileName = file.name;
        } else {
          filePath = file.path!;
          fileName = file.name;
        }

        final volume = Volume(
          title: fileName,
          filePath: filePath,
        );
        volumes.add(volume);
        Get.snackbar('Успех', 'Том добавлен: $fileName');
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось добавить том: $e');
    }
  }

  void removeVolume(int index) {
    volumes.removeAt(index);
  }

  void updateVolumeTitle(int index, String newTitle) {
    if (index < volumes.length) {
      volumes[index] = volumes[index].copyWith(title: newTitle);
      volumes.refresh();
    }
  }

  Future<void> pickCover() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          coverPath.value = 'data:image/jpeg;base64,$base64Image';
        } else {
          coverPath.value = image.path;
        }
        Get.snackbar('Успех', 'Обложка добавлена');
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось выбрать изображение: $e');
    }
  }

  Future<bool> saveBook() async {
    // Защита от повторного сохранения
    if (_isSaving) {
      return false;
    }

    // Валидация: проверяем название
    if (title.value.trim().isEmpty) {
      Get.snackbar('Ошибка', 'Введите название книги');
      return false;
    }

    // Валидация: проверяем, есть ли хотя бы один том
    if (volumes.isEmpty) {
      Get.snackbar('Ошибка', 'Добавьте хотя бы один PDF-файл');
      return false;
    }

    // Проверка на дубликаты (если редактирование, пропускаем)
    if (book.value == null) {
      final existingBooks = _repository.getAllBooks();
      final isDuplicate = existingBooks.any(
          (b) => b.title.toLowerCase() == title.value.trim().toLowerCase());
      if (isDuplicate) {
        Get.snackbar(
          'Ошибка',
          'Книга с таким названием уже существует',
          duration: const Duration(seconds: 2),
        );
        return false;
      }
    }

    _isSaving = true;
    isLoading.value = true;

    try {
      Book savedBook;

      if (book.value != null) {
        savedBook = book.value!.copyWith(
          title: title.value.trim(),
          description: description.value.isNotEmpty ? description.value : null,
          coverPath: coverPath.value.isNotEmpty ? coverPath.value : null,
          volumes: volumes.toList(),
          categories: selectedCategories.toList(),
          status: selectedStatus.value,
        );
        await _repository.saveBook(savedBook);
      } else {
        savedBook = Book(
          title: title.value.trim(),
          description: description.value.isNotEmpty ? description.value : null,
          coverPath: coverPath.value.isNotEmpty ? coverPath.value : null,
          volumes: volumes.toList(),
          categories: selectedCategories.toList(),
          status: selectedStatus.value,
        );
        await _repository.saveBook(savedBook);
      }

      _categoryController.loadCategories();

      // Создаем info.txt для новой книги
      if (!kIsWeb && volumes.isNotEmpty && savedBook.volumes.isNotEmpty) {
        try {
          final firstVolumePath = savedBook.volumes.first.filePath;
          final file = File(firstVolumePath);
          if (await file.exists()) {
            final folderPath = file.parent.path;
            final importController = Get.find<ImportController>();
            await importController.createInfoFile(folderPath, savedBook);
          }
        } catch (e) {
          // Игнорируем ошибки создания info.txt
        }
      }

      Get.snackbar('Успех', 'Книга сохранена');
      return true;
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось сохранить книгу: $e');
      return false;
    } finally {
      isLoading.value = false;
      _isSaving = false;
    }
  }

  bool get isEditing => book.value != null;
}
