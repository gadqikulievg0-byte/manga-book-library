import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:pdfx/pdfx.dart';
import 'snackbar_helper.dart';

class PdfCoverExtractor {
  /// Извлекает первую страницу PDF и сохраняет как JPEG обложку.
  /// Если обложка для volumeId уже существует, возвращает ее без генерации.
  static Future<String?> extractCoverFromPdf({
    required String pdfPath,
    required String outputDir,
    String? volumeId,
    bool showErrors = false,
  }) async {
    if (kIsWeb) return null;
    if (!File(pdfPath).existsSync()) {
      final msg = 'PDF файл не существует: $pdfPath';
      print(msg);
      if (showErrors) {
        SnackbarHelper.error(msg);
      }
      return null;
    }

    final outDir = Directory(outputDir);
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    // Проверяем, существует ли уже обложка для этого volumeId
    if (volumeId != null && volumeId.isNotEmpty) {
      final existingCover = _findExistingCover(outDir, volumeId);
      if (existingCover != null) {
        print('Обложка уже существует: $existingCover');
        return existingCover;
      }
    }

    try {
      print('Открываем PDF: $pdfPath');
      final doc = await PdfDocument.openFile(pdfPath);
      print('PDF открыт, страниц: ${doc.pagesCount}');

      if (doc.pagesCount < 1) {
        await doc.close();
        return null;
      }

      final page = await doc.getPage(1);
      print('Страница: ${page.width}x${page.height}');

      double scale = 1.0;
      if (page.width > 512) {
        scale = 512.0 / page.width;
      }

      print('Рендеринг...');
      final pageImage = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: PdfPageImageFormat.jpeg,
        quality: 85,
      );

      if (pageImage == null) {
        print('pageImage is null');
        await page.close();
        await doc.close();
        return null;
      }

      final fileName =
          'volume_${volumeId ?? DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputPath = path.join(outputDir, fileName);

      print('Сохраняем: ${pageImage.bytes.length} байт');
      await File(outputPath).writeAsBytes(pageImage.bytes);

      await page.close();
      await doc.close();

      print('Обложка сохранена: $outputPath');
      return outputPath;
    } catch (e, stack) {
      final msg = 'Ошибка: $e\n$stack';
      print(msg);
      if (showErrors) {
        SnackbarHelper.error('Не удалось извлечь обложку: $e');
      }
      return null;
    }
  }

  /// Ищет существующую обложку по volumeId в папке covers.
  static String? _findExistingCover(Directory coversDir, String volumeId) {
    if (!coversDir.existsSync()) return null;

    final files = coversDir.listSync().where((entity) {
      if (entity is File) {
        final name = path.basenameWithoutExtension(entity.path);
        return name.contains(volumeId);
      }
      return false;
    }).toList();

    if (files.isEmpty) return null;

    // Возвращаем первый найденный файл (проверяем, что он не пустой)
    for (final file in files) {
      final f = File(file.path);
      if (f.existsSync() && f.lengthSync() > 0) {
        return file.path;
      }
    }

    return null;
  }

  /// Удаляет все обложки для указанного volumeId (на случай перегенерации).
  static Future<void> removeCoverByVolumeId(
      String coversDir, String volumeId) async {
    final dir = Directory(coversDir);
    if (!await dir.exists()) return;

    final files = dir.listSync().where((entity) {
      if (entity is File) {
        return path.basenameWithoutExtension(entity.path).contains(volumeId);
      }
      return false;
    }).toList();

    for (final file in files) {
      await File(file.path).delete();
    }
  }
}
