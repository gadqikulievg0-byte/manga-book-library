import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtils {
  static bool get isWeb => kIsWeb;
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Проверка существования файла
  static Future<bool> fileExists(String path) async {
    if (isWeb) {
      // В вебе всегда возвращаем true, так как файлы загружаются в память
      return true;
    }
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  // Получение имени файла из пути
  static String getFileName(String path) {
    if (isWeb) {
      // Для веба извлекаем имя из URL или пути
      return path.split('/').last.split('?').first;
    }
    try {
      return File(path).uri.pathSegments.last;
    } catch (e) {
      return path.split('/').last;
    }
  }
}
