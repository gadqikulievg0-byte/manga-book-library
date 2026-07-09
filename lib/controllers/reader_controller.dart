import 'package:get/get.dart';
import '../core/reading_mode.dart';
import '../data/models/volume.dart';
import '../data/repositories/book_repository.dart';

class ReaderController extends GetxController {
  final BookRepository _repository = Get.find<BookRepository>();

  final readingMode = ReadingMode.vertical.obs;
  final currentPage = 0.obs;

  String? _bookId;
  Volume? _volume;

  void initReader({required String bookId, required Volume volume}) {
    _bookId = bookId;
    _volume = volume;
    currentPage.value = volume.lastReadPage;
  }

  void toggleReadingMode() {
    if (readingMode.value == ReadingMode.vertical) {
      readingMode.value = ReadingMode.horizontal;
    } else {
      readingMode.value = ReadingMode.vertical;
    }
  }

  Future<void> saveProgress(int page) async {
    if (_bookId != null && _volume != null) {
      try {
        // Передаем 4 параметра: bookId, volumeId, page, isBookmarked
        await _repository.saveReadingProgress(
          _bookId!,
          _volume!.id,
          page,
          _volume!.isBookmarked, // Передаем текущее состояние закладки
        );
      } catch (e) {
        print('Error saving progress: $e');
      }
    }
  }

  Future<void> saveBookmark(int page) async {
    if (_bookId != null && _volume != null) {
      try {
        // Сохраняем закладку: если page >= 0, то закладка есть
        final isBookmarked = page >= 0;
        await _repository.saveReadingProgress(
          _bookId!,
          _volume!.id,
          _volume!.lastReadPage, // Сохраняем текущую страницу
          isBookmarked,
        );
        // Обновляем состояние закладки в объекте volume
        _volume!.isBookmarked = isBookmarked;
      } catch (e) {
        print('Error saving bookmark: $e');
      }
    }
  }
}
