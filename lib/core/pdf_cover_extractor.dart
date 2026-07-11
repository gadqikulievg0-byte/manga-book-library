import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:pdfx/pdfx.dart';
import 'snackbar_helper.dart';

class PdfCoverExtractor {
  /// Извлекает первую страницу PDF и сохраняет как JPEG обложку.
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
}
