import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../data/models/book.dart';
import '../data/models/volume.dart';
import 'settings_controller.dart';
import '../data/repositories/book_repository.dart';
import 'category_controller.dart';
import '../core/pdf_cover_extractor.dart';
import '../core/snackbar_helper.dart';

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

  bool _isSaving = false;
  List<Volume>? _originalVolumes;

  String get _libraryPath {
    final settings = Get.find<SettingsController>();
    return settings.libraryPath.value;
  }

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
        SnackbarHelper.success('Обложка добавлена');
      }
    } catch (e) {
      SnackbarHelper.error('Не удалось выбрать изображение: $e');
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

  Future<String> _createBookFolder(String bookTitle) async {
    final folderName = _sanitizeFolderName(bookTitle);
    final bookFolderPath = path.join(_libraryPath, folderName);

    final folder = Directory(bookFolderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final coversFolder = Directory(path.join(bookFolderPath, 'covers'));
    if (!await coversFolder.exists()) {
      await coversFolder.create();
    }

    return bookFolderPath;
  }

  String _sanitizeFolderName(String name) {
    final illegalChars = RegExp(r'[<>:"/\\|?*]');
    return name.replaceAll(illegalChars, '').trim();
  }

  Future<String> _copyFileToBookFolder(
      String sourcePath, String bookFolderPath) async {
    final fileName = path.basename(sourcePath);
    final destPath = path.join(bookFolderPath, fileName);

    String finalDestPath = destPath;
    int counter = 1;
    while (await File(finalDestPath).exists()) {
      final ext = path.extension(fileName);
      final nameWithoutExt = path.basenameWithoutExtension(fileName);
      finalDestPath =
          path.join(bookFolderPath, '${nameWithoutExt}_$counter$ext');
      counter++;
    }

    await File(sourcePath).copy(finalDestPath);
    return finalDestPath;
  }

  Future<void> _createInfoFile(String bookFolderPath, Book book) async {
    final infoFile = File(path.join(bookFolderPath, 'info.txt'));

    String content = 'TITLE: ${book.title}\n';
    if (book.description != null) {
      content += 'DESCRIPTION: ${book.description}\n';
    }
    if (book.categories.isNotEmpty) {
      content += 'CATEGORIES: ${book.categories.join(', ')}\n';
    }

    String status = 'new';
    switch (book.status) {
      case BookStatus.reading:
        status = 'reading';
        break;
      case BookStatus.read:
        status = 'read';
        break;
      default:
        status = 'new';
    }
    content += 'STATUS: $status\n';

    content += '\nVOLUMES:\n';
    for (var i = 0; i < book.volumes.length; i++) {
      final volume = book.volumes[i];
      final volumeStatus = volume.lastReadPage > 0 ? 'reading' : 'new';
      content += '  ${i + 1}: ${volume.title}|$volumeStatus\n';
    }

    await infoFile.writeAsString(content);
  }

  /// Добавляет один PDF том
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
        String fileName;
        String filePath;

        if (kIsWeb) {
          fileName = file.name;
          filePath = file.name;
        } else {
          fileName = file.name;
          filePath = file.path!;
        }

        final volume = Volume(
          title: fileName,
          filePath: filePath,
          lastReadPage: 0,
        );
        volumes.add(volume);
        SnackbarHelper.success('Том добавлен: $fileName');
      }
    } catch (e) {
      SnackbarHelper.error('Ошибка: $e');
    }
  }

  /// Добавляет несколько PDF томов за раз
  Future<void> addMultipleVolumes() async {
    try {
      FilePickerResult? result;

      if (kIsWeb) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
          allowMultiple: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        int added = 0;
        for (final file in result.files) {
          String fileName;
          String filePath;

          if (kIsWeb) {
            fileName = file.name;
            filePath = file.name;
          } else {
            fileName = file.name;
            filePath = file.path!;
          }

          // Проверяем, нет ли уже такого файла
          bool exists = volumes.any((v) => v.filePath == filePath);
          if (!exists) {
            final volume = Volume(
              title: fileName,
              filePath: filePath,
              lastReadPage: 0,
            );
            volumes.add(volume);
            added++;
          }
        }
        SnackbarHelper.success('Добавлено томов: $added');
      }
    } catch (e) {
      SnackbarHelper.error('Ошибка: $e');
    }
  }

  Future<bool> saveBook() async {
    if (_isSaving) return false;

    if (title.value.trim().isEmpty) {
      SnackbarHelper.error('Введите название книги');
      return false;
    }

    if (volumes.isEmpty) {
      SnackbarHelper.error('Добавьте хотя бы один PDF-файл');
      return false;
    }

    _isSaving = true;
    isLoading.value = true;

    try {
      String? bookFolderPath;
      if (!kIsWeb) {
        bookFolderPath = await _createBookFolder(title.value.trim());
      }

      List<Volume> processedVolumes = [];
      for (var volume in volumes) {
        String finalPath;
        String? volumeCoverPath;

        if (!kIsWeb && bookFolderPath != null) {
          finalPath =
              await _copyFileToBookFolder(volume.filePath, bookFolderPath);

          // Генерируем обложку тома из первой страницы PDF
          final coversFolder = Directory(path.join(bookFolderPath, 'covers'));
          if (!await coversFolder.exists()) {
            await coversFolder.create();
          }

          volumeCoverPath = await PdfCoverExtractor.extractCoverFromPdf(
            pdfPath: finalPath,
            outputDir: coversFolder.path,
            volumeId: volume.id,
          );

          // Если не удалось сгенерировать обложку, используем старую если была
          if (volumeCoverPath == null && volume.coverPath != null) {
            volumeCoverPath = volume.coverPath;
          }
        } else {
          finalPath = volume.filePath;
        }

        processedVolumes.add(Volume(
          id: volume.id,
          title: volume.title,
          filePath: finalPath,
          lastReadPage: volume.lastReadPage,
          coverPath: volumeCoverPath,
        ));
      }

      // Определяем обложку книги
      String? finalCoverPath;
      if (!kIsWeb && coverPath.value.isNotEmpty && bookFolderPath != null) {
        final coverFileName = 'cover${path.extension(coverPath.value)}';
        final destCoverPath = path.join(bookFolderPath, coverFileName);
        await File(coverPath.value).copy(destCoverPath);
        finalCoverPath = destCoverPath;
      } else if (!kIsWeb &&
          bookFolderPath != null &&
          processedVolumes.isNotEmpty) {
        // Если пользователь не указал обложку, используем обложку первого тома
        final firstVol = processedVolumes.first;
        if (firstVol.coverPath != null && firstVol.coverPath!.isNotEmpty) {
          final coverExt = path.extension(firstVol.coverPath!);
          final destCoverPath = path.join(bookFolderPath, 'cover$coverExt');
          try {
            await File(firstVol.coverPath!).copy(destCoverPath);
            finalCoverPath = destCoverPath;
          } catch (_) {
            finalCoverPath = firstVol.coverPath;
          }
        }
      } else {
        finalCoverPath = coverPath.value;
      }

      Book savedBook;
      if (book.value != null) {
        savedBook = book.value!.copyWith(
          title: title.value.trim(),
          description: description.value.isNotEmpty ? description.value : null,
          coverPath: finalCoverPath,
          volumes: processedVolumes,
          categories: selectedCategories.toList(),
          status: selectedStatus.value,
        );
        await _repository.saveBook(savedBook);
      } else {
        savedBook = Book(
          title: title.value.trim(),
          description: description.value.isNotEmpty ? description.value : null,
          coverPath: finalCoverPath,
          volumes: processedVolumes,
          categories: selectedCategories.toList(),
          status: selectedStatus.value,
        );
        await _repository.saveBook(savedBook);
      }

      if (!kIsWeb && bookFolderPath != null) {
        await _createInfoFile(bookFolderPath, savedBook);
      }

      _categoryController.loadCategories();

      SnackbarHelper.success('Книга сохранена');
      return true;
    } catch (e) {
      SnackbarHelper.error('Не удалось сохранить книгу: $e');
      return false;
    } finally {
      isLoading.value = false;
      _isSaving = false;
    }
  }

  bool get isEditing => book.value != null;
}
