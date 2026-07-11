import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io';

import '../models/book.dart';
import '../models/volume.dart';

class HiveService {
  static Future<void> init() async {
    // Инициализация Hive
    if (!kIsWeb) {
      final appDocumentDir =
          await path_provider.getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
    } else {
      await Hive.initFlutter();
    }

    // Регистрация адаптеров
    Hive.registerAdapter(BookStatusAdapter());
    Hive.registerAdapter(BookAdapter());
    Hive.registerAdapter(VolumeAdapter());

    // Открытие коробок
    await Hive.openBox<Book>('books');
  }
}
