import 'package:get/get.dart';
import '../data/models/book.dart';
import '../data/repositories/book_repository.dart';
import 'category_controller.dart';

class LibraryController extends GetxController {
  final BookRepository _repository = Get.find<BookRepository>();

  final books = <Book>[].obs;
  final filteredBooks = <Book>[].obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadBooks();
  }

  // Статистика
  int get totalBooks => books.length;
  int get totalVolumes => books.fold(0, (sum, book) => sum + book.volumeCount);
  int get newBooks => books.where((b) => b.status == BookStatus.newBook).length;
  int get readingBooks =>
      books.where((b) => b.status == BookStatus.reading).length;
  int get readBooks => books.where((b) => b.status == BookStatus.read).length;

  void loadBooks() {
    isLoading.value = true;
    try {
      books.value = _repository.getAllBooks();
      filterBooks();
    } finally {
      isLoading.value = false;
    }
  }

  void filterBooks() {
    var filtered = books.toList();

    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where((book) => book.title
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    try {
      final categoryController = Get.find<CategoryController>();

      if (categoryController.selectedCategories.isNotEmpty) {
        filtered = filtered
            .where((book) => book.categories.any((category) =>
                categoryController.selectedCategories.contains(category)))
            .toList();
      }

      if (categoryController.selectedStatus.isNotEmpty) {
        filtered = filtered
            .where((book) =>
                categoryController.selectedStatus.contains(book.status))
            .toList();
      }
    } catch (e) {
      // Если CategoryController еще не зарегистрирован, игнорируем
    }

    filteredBooks.value = filtered;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    filterBooks();
  }

  Future<void> deleteBook(String id) async {
    await _repository.deleteBook(id);
    loadBooks();
  }

  Future<void> deleteBooks(List<String> ids) async {
    for (final id in ids) {
      await _repository.deleteBook(id);
    }
    loadBooks();
  }

  void openBook(String id) {
    Get.toNamed('/volume-list', arguments: {'bookId': id});
  }

  void addBook() {
    Get.toNamed('/book-edit');
  }

  void editBook(String id) {
    Get.toNamed('/book-edit', arguments: {'bookId': id});
  }
}
