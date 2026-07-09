import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/library_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/import_controller.dart';
import '../controllers/background_controller.dart';
import '../data/models/book.dart';
import '../widgets/book_card.dart';
import '../widgets/search_field.dart';

enum GridSize { small, medium, large }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  GridSize _selectedGridSize = GridSize.medium;
  bool _showGridSettings = false;

  void _importLibrary() async {
    final importController = Get.find<ImportController>();
    await importController.importLibrary();
    Get.find<LibraryController>().loadBooks();
  }

  Widget _buildBackground() {
    final bgController = Get.find<BackgroundController>();

    return Obx(() {
      if (bgController.backgroundImage.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Positioned.fill(
        child: IgnorePointer(
          // ДОБАВЬТЕ ЭТО
          child: Opacity(
            opacity: bgController.opacity.value,
            child: kIsWeb
                ? Image.memory(
                    base64Decode(
                        bgController.backgroundImage.value.split(',').last),
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(bgController.backgroundImage.value),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LibraryController>();
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;

    switch (_selectedGridSize) {
      case GridSize.small:
        crossAxisCount = 6;
        childAspectRatio = 0.55;
        break;
      case GridSize.medium:
        crossAxisCount = 4;
        childAspectRatio = 0.65;
        break;
      case GridSize.large:
        crossAxisCount = 2;
        childAspectRatio = 0.75;
        break;
    }

    if (screenWidth < 400 && crossAxisCount > 3) {
      crossAxisCount = 3;
    } else if (screenWidth < 600 && crossAxisCount > 4) {
      crossAxisCount = 4;
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Chitalka'),
            centerTitle: false,
            backgroundColor: Colors.black.withOpacity(0.85),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _importLibrary,
                tooltip: 'Импортировать библиотеку',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  setState(() {
                    _showGridSettings = !_showGridSettings;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.loadBooks,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SearchField(
                  controller: TextEditingController()
                    ..text = controller.searchQuery.value,
                  hintText: 'Поиск...',
                  onChanged: (value) {
                    if (value != null) controller.setSearchQuery(value);
                  },
                ),
              ),
              if (_showGridSettings)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Настройки',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Размер:',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 8),
                          ...GridSize.values.map((size) {
                            final isSelected = _selectedGridSize == size;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedGridSize = size;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? Colors.blue
                                      : Colors.grey[800],
                                  foregroundColor: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                ),
                                child: Text(
                                  size == GridSize.small
                                      ? 'Мел'
                                      : size == GridSize.medium
                                          ? 'Ср'
                                          : 'Кр',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Get.find<BackgroundController>()
                                  .pickBackground(),
                              icon: const Icon(Icons.wallpaper, size: 18),
                              label: const Text('Выбрать фон'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade800,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Get.find<BackgroundController>()
                                  .removeBackground(),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Удалить фон'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Obx(() {
                        final bgController = Get.find<BackgroundController>();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Прозрачность:',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Slider(
                                    value: bgController.opacity.value,
                                    min: 0.05,
                                    max: 0.4,
                                    divisions: 20,
                                    label:
                                        '${(bgController.opacity.value * 100).round()}%',
                                    onChanged: (value) {
                                      bgController.setOpacity(value);
                                    },
                                  ),
                                ),
                                Text(
                                  '${(bgController.opacity.value * 100).round()}%',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              _buildCategoryFilters(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.filteredBooks.isEmpty) {
                    return const Center(
                      child: Text(
                        'Нет книг',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: controller.filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = controller.filteredBooks[index];
                      return BookCard(
                        book: book,
                        onTap: () => controller.openBook(book.id),
                        onEdit: () => controller.editBook(book.id),
                        onDelete: () =>
                            _showDeleteDialog(context, book.id, controller),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: controller.addBook,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
        _buildBackground(),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    try {
      final categoryController = Get.find<CategoryController>();

      return Obx(() {
        if (categoryController.allCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Фильтр по категориям',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...categoryController.allCategories.map((category) {
                      final isSelected =
                          categoryController.isCategorySelected(category);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) {
                            categoryController.toggleCategory(category);
                            Get.find<LibraryController>().filterBooks();
                          },
                          selectedColor: Colors.blue[300],
                          backgroundColor: Colors.grey[800],
                          checkmarkColor: Colors.blue[700],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                          ),
                          avatar: isSelected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.blue)
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      });
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  void _showDeleteDialog(
      BuildContext context, String bookId, LibraryController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: const Text('Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteBook(bookId);
              Navigator.pop(context);
            },
            child: const Text('Да'),
          ),
        ],
      ),
    );
  }
}
