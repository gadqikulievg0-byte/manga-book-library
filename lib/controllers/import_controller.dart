import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../data/models/book.dart';
import '../data/models/volume.dart';
import '../data/repositories/book_repository.dart';
import '../core/snackbar_helper.dart';

// ВЫНОСИМ КЛАСС НАРУЖУ
class MangaInfo {
  String title;
  String? description;
  List<String> categories;
  String status; // new, reading, read

  MangaInfo({
    required this.title,
    this.description,
    this.categories = const [],
    this.status = 'new',
  });

  factory MangaInfo.fromFile(String content) {
    final lines = content.split('\n');
    String? title;
    String? description;
    List<String> categories = [];
    String status = 'new';

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('TITLE:')) {
        title = line.substring(6).trim();
      } else if (line.startsWith('DESCRIPTION:')) {
        description = line.substring(12).trim();
      } else if (line.startsWith('CATEGORIES:')) {
        categories =
            line.substring(11).trim().split(',').map((e) => e.trim()).toList();
      } else if (line.startsWith('STATUS:')) {
        status = line.substring(7).trim().toLowerCase();
      }
    }

    return MangaInfo(
      title: title ?? 'Без названия',
      description: description,
      categories: categories,
      status: status,
    );
  }
}

class ImportController extends GetxController {
  final BookRepository _repository = Get.find<BookRepository>();

  final isImporting = false.obs;
  final importedCount = 0.obs;
  final totalFound = 0.obs;
  final progress = 0.0.obs;

  // Выбор папки и импорт
  Future<void> importLibrary() async {
    if (kIsWeb) {
      SnackbarHelper.error('Импорт доступен только в десктопной версии');
      return;
    }

    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;

    final rootPath = result;
    await _importFromFolder(rootPath);
  }

  // Импорт из выбранной папки
  Future<void> _importFromFolder(String rootPath) async {
    isImporting.value = true;
    importedCount.value = 0;
    totalFound.value = 0;

    try {
      final rootDir = Directory(rootPath);
      if (!await rootDir.exists()) {
        SnackbarHelper.error('Папка не найдена');
        return;
      }

      final mangaFolders = await rootDir.list().where((entity) {
        return entity is Directory;
      }).toList();

      totalFound.value = mangaFolders.length;
      SnackbarHelper.info('Найдено папок: ${mangaFolders.length}');

      for (var i = 0; i < mangaFolders.length; i++) {
        final folder = mangaFolders[i] as Directory;
        progress.value = (i + 1) / mangaFolders.length;

        await _importMangaFolder(folder);
        importedCount.value = i + 1;
      }

      SnackbarHelper.success('Импортировано ${importedCount.value} манг');
    } catch (e) {
      SnackbarHelper.error('Ошибка импорта: $e');
    } finally {
      isImporting.value = false;
      progress.value = 0;
    }
  }

  // Импорт одной папки с мангой
  Future<void> _importMangaFolder(Directory folder) async {
    final folderPath = folder.path;
    final folderName = path.basename(folderPath);

    final existingBooks = _repository.getAllBooks();
    if (existingBooks.any((b) => b.title == folderName)) {
      return;
    }

    String? coverPath;
    final coverFile = File(path.join(folderPath, 'cover.jpg'));
    if (await coverFile.exists()) {
      coverPath = coverFile.path;
    }

    MangaInfo? info;
    final infoFile = File(path.join(folderPath, 'info.txt'));
    if (await infoFile.exists()) {
      final content = await infoFile.readAsString();
      info = MangaInfo.fromFile(content);
    }

    final pdfFiles = await folder.list().where((entity) {
      if (entity is! File) return false;
      return entity.path.endsWith('.pdf') || entity.path.endsWith('.PDF');
    }).toList();

    if (pdfFiles.isEmpty) {
      return;
    }

    pdfFiles.sort((a, b) {
      final nameA = path.basename(a.path);
      final nameB = path.basename(b.path);
      return nameA.compareTo(nameB);
    });

    final volumes = <Volume>[];
    for (var i = 0; i < pdfFiles.length; i++) {
      final file = pdfFiles[i] as File;
      final fileName = path.basename(file.path);

      String title = fileName;
      final regExp = RegExp(r'第(\d+)巻');
      final match = regExp.firstMatch(fileName);
      if (match != null) {
        final number = match.group(1);
        title = 'Том $number';
      }

      volumes.add(Volume(
        title: title,
        filePath: file.path,
      ));
    }

    BookStatus status = BookStatus.newBook;
    if (info != null) {
      switch (info.status) {
        case 'reading':
          status = BookStatus.reading;
          break;
        case 'read':
          status = BookStatus.read;
          break;
        default:
          status = BookStatus.newBook;
      }
    }

    final book = Book(
      title: info?.title ?? folderName,
      description: info?.description,
      coverPath: coverPath,
      volumes: volumes,
      categories: info?.categories ?? [],
      status: status,
    );

    await _repository.saveBook(book);
  }

  // Создание info.txt для папки манги
  Future<void> createInfoFile(String folderPath, Book book) async {
    if (kIsWeb) return;

    try {
      final infoFile = File(path.join(folderPath, 'info.txt'));

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

      await infoFile.writeAsString(content);
      SnackbarHelper.success('Файл info.txt создан в папке манги');
    } catch (e) {
      SnackbarHelper.error('Не удалось создать info.txt: $e');
    }
  }
}
