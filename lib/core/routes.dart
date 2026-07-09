import 'package:get/get.dart';
import '../screens/library_screen.dart';
import '../screens/book_edit_screen.dart';
import '../screens/volume_list_screen.dart';
import '../screens/reader_screen.dart';

class Routes {
  static const String library = '/';
  static const String bookEdit = '/book-edit';
  static const String volumeList = '/volume-list';
  static const String reader = '/reader';

  static List<GetPage> routes = [
    GetPage(name: library, page: () => const LibraryScreen()),
    GetPage(name: bookEdit, page: () => const BookEditScreen()),
    GetPage(name: volumeList, page: () => const VolumeListScreen()),
    GetPage(name: reader, page: () => const ReaderScreen()),
  ];
}
