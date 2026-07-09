import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import '../controllers/book_controller.dart';
import '../data/repositories/book_repository.dart';

class CategorySelector extends StatelessWidget {
  final BookController bookController;

  const CategorySelector({
    super.key,
    required this.bookController,
  });

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    final bookRepository = Get.find<BookRepository>();

    return Obx(() {
      // Объединяем все категории и выбранные
      final allCats = categoryController.allCategories.toList();
      final selected = bookController.selectedCategories.toList();

      // Добавляем выбранные категории, которых нет в общем списке
      for (final cat in selected) {
        if (!allCats.contains(cat)) {
          allCats.add(cat);
        }
      }
      allCats.sort();

      // Подсчет книг в каждой категории
      final allBooks = bookRepository.getAllBooks();
      final categoryCount = <String, int>{};
      for (final book in allBooks) {
        for (final category in book.categories) {
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Категории',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...allCats.map((category) {
                final isSelected = selected.contains(category);
                final count = categoryCount[category] ?? 0;
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category),
                      const SizedBox(width: 4),
                      Text(
                        '($count)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    bookController.toggleCategory(category);
                  },
                  avatar: isSelected ? const Icon(Icons.check, size: 16) : null,
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue[700],
                );
              }),
              // Кнопка для добавления новой категории
              ActionChip(
                label: const Icon(Icons.add, size: 18),
                onPressed: () => _showAddCategoryDialog(context),
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
          if (selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Выбрано: ${selected.join(", ")}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      );
    });
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая категория'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введите название категории',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              bookController.addNewCategory(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                bookController.addNewCategory(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
