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

  Future<void> saveProgress(int page, bool isBookmarked) async {
    if (_bookId != null && _volume != null) {
      try {
        await _repository.saveReadingProgress(
          _bookId!,
          _volume!.id,
          page,
          isBookmarked,
        );
      } catch (e) {
        print('Error saving progress: $e');
      }
    }
  }

  Future<void> markVolumeAsRead() async {
    if (_bookId != null && _volume != null) {
      try {
        await _repository.markVolumeAsRead(_bookId!, _volume!.id);
        // Обновляем локальный volume
        _volume!.lastReadPage = -1;
        currentPage.value = -1;
      } catch (e) {
        print('Error marking volume as read: $e');
      }
    }
  }

  Future<void> saveBookmark(int page) async {
    if (_bookId != null && _volume != null) {
      try {
        final isBookmarked = page >= 0;
        await _repository.saveReadingProgress(
          _bookId!,
          _volume!.id,
          _volume!.lastReadPage,
          isBookmarked,
        );
        _volume!.isBookmarked = isBookmarked;
      } catch (e) {
        print('Error saving bookmark: $e');
      }
    }
  }
}
