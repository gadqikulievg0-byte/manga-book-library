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
import '../controllers/settings_controller.dart';

enum GridSize { small, medium, large }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  GridSize _selectedGridSize = GridSize.medium;
  late final LibraryController _controller;
  bool _isSelectionMode = false;
  final Set<String> _selectedBookIds = {};
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LibraryController>();
    _searchController.text = _controller.searchQuery.value;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _importLibrary() async {
    final importController = Get.find<ImportController>();
    await importController.importLibrary();
    _controller.loadBooks();
  }

  Widget _buildBackground() {
    final bgController = Get.find<BackgroundController>();
    return Obx(() {
      if (bgController.backgroundImage.value.isEmpty) {
        return const SizedBox.shrink();
      }
      return Positioned.fill(
        child: IgnorePointer(
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

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: _buildSettingsPanel(),
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: _buildFilterPanel(),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    final bgController = Get.find<BackgroundController>();
    final settingsController = Get.find<SettingsController>();
    return StatefulBuilder(
      builder: (context, setLocalState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Настройки',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Тема:', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 8),
              Switch(
                value: settingsController.isDarkMode.value,
                onChanged: (_) {
                  settingsController.toggleTheme();
                  setLocalState(() {});
                },
              ),
              Obx(() => Text(
                    settingsController.isDarkMode.value ? 'Темная' : 'Светлая',
                    style: const TextStyle(color: Colors.white70),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Размер сетки:',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 8),
              ...GridSize.values.map((size) {
                final isSelected = _selectedGridSize == size;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedGridSize = size);
                      setLocalState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.blue : Colors.grey[800],
                      foregroundColor:
                          isSelected ? Colors.white : Colors.white70,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    ),
                    child: Text(
                      size == GridSize.small
                          ? 'Малый'
                          : size == GridSize.medium
                              ? 'Средний'
                              : 'Большой',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => bgController.pickBackground(),
                  icon: const Icon(Icons.wallpaper, size: 18),
                  label: const Text('Выбрать фон'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => bgController.removeBackground(),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Удалить фон'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Яркость фона:',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: bgController.opacity.value,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          label:
                              '${(bgController.opacity.value * 100).round()}%',
                          onChanged: (value) => bgController.setOpacity(value),
                        ),
                      ),
                      Text('${(bgController.opacity.value * 100).round()}%',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Get.find<SettingsController>().changeLibraryPath(),
              icon: const Icon(Icons.folder, size: 18),
              label: const Text('Изменить папку библиотеки'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    try {
      final categoryController = Get.find<CategoryController>();
      return StatefulBuilder(
        builder: (context, setLocalState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                  width: 40,
                  height: 4,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.all(Radius.circular(2))))),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Фильтры',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                TextButton(
                    onPressed: () {
                      categoryController.clearFilters();
                      setLocalState(() {});
                    },
                    child: const Text('Сбросить')),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Row(children: [
                        _statItem(Icons.library_books, 'Всего книг',
                            '${_controller.totalBooks}'),
                        const SizedBox(width: 16),
                        _statItem(Icons.book, 'Всего томов',
                            '${_controller.totalVolumes}'),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        _statItem(Icons.fiber_new, 'Новых',
                            '${_controller.newBooks}', Colors.green),
                        const SizedBox(width: 16),
                        _statItem(Icons.auto_stories, 'Читается',
                            '${_controller.readingBooks}', Colors.orange),
                        const SizedBox(width: 16),
                        _statItem(Icons.check_circle, 'Прочитано',
                            '${_controller.readBooks}', Colors.blue),
                      ]),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const Text('По статусу',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BookStatus.values.map((status) {
                final isSelected = categoryController.isStatusSelected(status);
                return FilterChip(
                  label: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(status.icon, size: 16, color: status.color),
                    const SizedBox(width: 4),
                    Text(status.label),
                  ]),
                  selected: isSelected,
                  onSelected: (_) {
                    categoryController.toggleStatus(status);
                    setLocalState(() {});
                  },
                  selectedColor: status.color.withOpacity(0.3),
                  backgroundColor: Colors.grey[800],
                  checkmarkColor: status.color,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (categoryController.allCategories.isNotEmpty) ...[
              const Text('По категориям',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categoryController.allCategories.map((category) {
                  final isSelected =
                      categoryController.isCategorySelected(category);
                  return FilterChip(
                    label: Text(category,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.white70)),
                    selected: isSelected,
                    onSelected: (_) {
                      categoryController.toggleCategory(category);
                      setLocalState(() {});
                    },
                    selectedColor: Colors.blue[800],
                    backgroundColor: Colors.grey[800],
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _statItem(IconData icon, String label, String value, [Color? color]) {
    return Expanded(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color ?? Colors.white70),
        const SizedBox(width: 4),
        Flexible(
            child: Text('$label: $value',
                style: TextStyle(
                    fontSize: 11,
                    color: color ?? Colors.white70,
                    fontWeight: FontWeight.w500))),
      ]),
    );
  }

  void _toggleBookSelection(String bookId) {
    setState(() {
      if (_selectedBookIds.contains(bookId)) {
        _selectedBookIds.remove(bookId);
        if (_selectedBookIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedBookIds.add(bookId);
        _isSelectionMode = true;
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedBookIds.length == _controller.filteredBooks.length) {
        _selectedBookIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedBookIds
            .addAll(_controller.filteredBooks.map((b) => b.id).toList());
        _isSelectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedBookIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedBookIds.isEmpty) return;
    await _controller.deleteBooks(_selectedBookIds.toList());
    _exitSelectionMode();
  }

  Future<void> _confirmAndDeleteSelected() async {
    final count = _selectedBookIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книги?'),
        content: Text('Вы уверены, что хотите удалить $count книг?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Нет')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Да')),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;

    switch (_selectedGridSize) {
      case GridSize.small:
        crossAxisCount = 6;
        childAspectRatio = 0.67;
        break;
      case GridSize.medium:
        crossAxisCount = 4;
        childAspectRatio = 0.67;
        break;
      case GridSize.large:
        crossAxisCount = 3;
        childAspectRatio = 0.67;
        break;
    }

    if (screenWidth < 400 && crossAxisCount > 3)
      crossAxisCount = 3;
    else if (screenWidth < 600 && crossAxisCount > 4) crossAxisCount = 4;

    return Stack(
      children: [
        _buildBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _isSearchMode
              ? AppBar(
                  title: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .appBarTheme
                            .foregroundColor
                            ?.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      _controller.setSearchQuery(value);
                    },
                  ),
                  actions: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _controller.setSearchQuery('');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isSearchMode = false;
                          _searchController.clear();
                        });
                        _controller.setSearchQuery('');
                      },
                    ),
                  ],
                )
              : AppBar(
                  title: _isSelectionMode
                      ? Text('Выбрано: ${_selectedBookIds.length}')
                      : const Text('Chitalka'),
                  centerTitle: false,
                  actions: [
                    if (_isSelectionMode) ...[
                      IconButton(
                          icon: const Icon(Icons.select_all),
                          onPressed: _toggleSelectAll,
                          tooltip: 'Выбрать все'),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _selectedBookIds.isEmpty
                              ? null
                              : _confirmAndDeleteSelected,
                          tooltip: 'Удалить выбранные'),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _exitSelectionMode,
                          tooltip: 'Отменить'),
                    ] else ...[
                      IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => setState(() => _isSearchMode = true),
                          tooltip: 'Поиск'),
                      IconButton(
                          icon: const Icon(Icons.checklist),
                          onPressed: () =>
                              setState(() => _isSelectionMode = true),
                          tooltip: 'Выделить книги'),
                      IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _openFilters,
                          tooltip: 'Фильтры'),
                      IconButton(
                          icon: const Icon(Icons.folder_open),
                          onPressed: _importLibrary,
                          tooltip: 'Импортировать'),
                      IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: _openSettings,
                          tooltip: 'Настройки'),
                      IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _controller.loadBooks),
                    ],
                  ],
                ),
          body: Column(
            children: [
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value)
                    return const Center(child: CircularProgressIndicator());
                  if (_controller.filteredBooks.isEmpty)
                    return const Center(
                        child: Text('Нет книг',
                            style: TextStyle(color: Colors.white70)));

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _controller.filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _controller.filteredBooks[index];
                      final isSelected = _selectedBookIds.contains(book.id);

                      return BookCard(
                        book: book,
                        onBookTap: () {
                          if (_isSelectionMode) {
                            _toggleBookSelection(book.id);
                          } else {
                            _controller.openBook(book.id);
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleBookSelection(book.id);
                          }
                        },
                        onEdit: () => _controller.editBook(book.id),
                        onDelete: () => _showDeleteDialog(context, book.id),
                        isSelected: isSelected,
                        isSelectionMode: _isSelectionMode,
                        onSelectionToggle: () => _toggleBookSelection(book.id),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
          floatingActionButton: _isSelectionMode
              ? null
              : FloatingActionButton(
                  onPressed: _controller.addBook,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, String bookId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: const Text('Вы уверены?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Нет')),
          TextButton(
              onPressed: () {
                _controller.deleteBook(bookId);
                Navigator.pop(context);
              },
              child: const Text('Да')),
        ],
      ),
    );
  }
}
