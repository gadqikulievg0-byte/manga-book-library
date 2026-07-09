import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'core/routes.dart';
import 'core/themes.dart';
import 'data/models/book.dart';
import 'data/models/volume.dart';
import 'data/services/hive_service.dart';
import 'data/repositories/book_repository.dart';
import 'controllers/library_controller.dart';
import 'controllers/book_controller.dart';
import 'controllers/reader_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/import_controller.dart';
import 'controllers/background_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Hive с учетом платформы
  await HiveService.init();

  // Открываем коробку для настроек
  await Hive.openBox('settings');

  // Регистрация репозиториев и контроллеров в GetX
  Get.put(BookRepository(), permanent: true);
  Get.put(CategoryController(), permanent: true);
  Get.put(BackgroundController(), permanent: true);
  Get.put(ImportController(), permanent: true);
  Get.put(LibraryController(), permanent: true);
  Get.put(BookController(), permanent: true);
  Get.put(ReaderController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Manga Library Pro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: Routes.library,
      getPages: Routes.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
    );
  }
}
