import 'package:get/get.dart';
import '../data/repositories/book_repository.dart';
import '../data/models/book.dart';
import 'library_controller.dart';

class CategoryController extends GetxController {
  final BookRepository _repository = Get.find<BookRepository>();

  final allCategories = <String>[].obs;
  final selectedCategories = <String>[].obs;
  final selectedStatus = <BookStatus>[].obs; // Добавлено

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  void loadCategories() {
    final books = _repository.getAllBooks();
    final categoriesSet = <String>{};

    for (final book in books) {
      categoriesSet.addAll(book.categories);
    }

    allCategories.value = categoriesSet.toList()..sort();
  }

  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
    update();
    // Обновляем фильтр в LibraryController
    try {
      Get.find<LibraryController>().filterBooks();
    } catch (e) {}
  }

  void toggleStatus(BookStatus status) {
    if (selectedStatus.contains(status)) {
      selectedStatus.remove(status);
    } else {
      selectedStatus.add(status);
    }
    update();
    try {
      Get.find<LibraryController>().filterBooks();
    } catch (e) {}
  }

  void clearFilters() {
    selectedCategories.clear();
    selectedStatus.clear();
    update();
    try {
      Get.find<LibraryController>().filterBooks();
    } catch (e) {}
  }

  bool isCategorySelected(String category) {
    return selectedCategories.contains(category);
  }

  bool isStatusSelected(BookStatus status) {
    return selectedStatus.contains(status);
  }

  Future<void> addCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isNotEmpty && !allCategories.contains(trimmed)) {
      allCategories.add(trimmed);
      allCategories.sort();
    }
  }

  Future<void> removeCategory(String category) async {
    final books = _repository.getAllBooks();
    for (final book in books) {
      if (book.categories.contains(category)) {
        book.categories.remove(category);
        await _repository.saveBook(book);
      }
    }

    allCategories.remove(category);
    selectedCategories.remove(category);
    loadCategories();
    try {
      Get.find<LibraryController>().loadBooks();
    } catch (e) {}
  }
}
