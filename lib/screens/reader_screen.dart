import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/reader_controller.dart';
import '../core/reading_mode.dart';
import '../data/models/book.dart';
import '../data/models/volume.dart';
import '../data/repositories/book_repository.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ReaderController _controller;
  late final PdfViewerController _pdfController;
  late final Volume _volume;
  late final String _bookId;
  late final int _initialPage;
  bool _isVertical = true;
  int _totalPages = 1;

  final Map<int, String> _bookmarks = {};

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ReaderController>();
    _pdfController = PdfViewerController();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _bookId = args['bookId'] as String? ?? '';
    final volumeId = args['volumeId'] as String? ?? '';

    final book = Get.find<BookRepository>().getBookById(_bookId);
    _volume = book!.volumes.firstWhere((v) => v.id == volumeId);

    _controller.initReader(bookId: _bookId, volume: _volume);
    _initialPage = (_volume.lastReadPage + 1).clamp(1, 999999);
    _isVertical = _controller.readingMode.value == ReadingMode.vertical;

    _updateBookStatus();
    _loadBookmarks();
  }

  void _updateBookStatus() async {
    final book = Get.find<BookRepository>().getBookById(_bookId);
    if (book != null && book.status == BookStatus.newBook) {
      book.status = BookStatus.reading;
      await Get.find<BookRepository>().saveBook(book);
    }
  }

  void _loadBookmarks() {
    if (_volume.isBookmarked) {
      _bookmarks[_initialPage] = 'Страница $_initialPage';
    }
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    try {
      final page = _pdfController.pageNumber;
      if (page != null && page > 0) {
        await _controller.saveProgress(page - 1);
      }
    } catch (e) {
      // Игнорируем ошибки при сохранении
    }
  }

  void _addBookmark() async {
    final currentPage = _pdfController.pageNumber ?? 1;

    if (_bookmarks.containsKey(currentPage)) {
      _showSnackbar('Закладка уже есть на этой странице');
      return;
    }

    setState(() {
      _bookmarks[currentPage] = 'Страница $currentPage';
    });

    await _controller.saveBookmark(currentPage);
    _showSnackbar('📌 Закладка добавлена на стр. $currentPage');
  }

  void _removeBookmark(int page) async {
    setState(() {
      _bookmarks.remove(page);
    });
    if (_bookmarks.isEmpty) {
      await _controller.saveBookmark(-1);
    }
    _showSnackbar('Закладка удалена');
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        width: 300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showBookmarksDialog() {
    if (_bookmarks.isEmpty) {
      _showSnackbar('Нет сохраненных закладок');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📌 Закладки'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _bookmarks.length,
            itemBuilder: (context, index) {
              final entry = _bookmarks.entries.elementAt(index);
              return ListTile(
                leading: const Icon(Icons.bookmark, color: Colors.yellow),
                title: Text(entry.value),
                subtitle: Text('Страница ${entry.key}'),
                onTap: () {
                  Navigator.pop(context);
                  _pdfController.jumpToPage(entry.key);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _removeBookmark(entry.key);
                    Navigator.pop(context);
                    _showBookmarksDialog();
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _goToPage() async {
    final totalPages = _pdfController.pageCount ?? 1;

    final TextEditingController textController = TextEditingController();

    final pageNumber = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Перейти на страницу'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Введите номер страницы (1-$totalPages)',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null && page >= 1 && page <= totalPages) {
              Navigator.pop(context, page);
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
              final page = int.tryParse(textController.text);
              if (page != null && page >= 1 && page <= totalPages) {
                Navigator.pop(context, page);
              } else {
                _showSnackbar('Введите номер страницы (1-$totalPages)');
              }
            },
            child: const Text('Перейти'),
          ),
        ],
      ),
    );

    if (pageNumber != null) {
      try {
        _pdfController.jumpToPage(pageNumber);
      } catch (e) {
        _showSnackbar('Не удалось перейти на страницу $pageNumber');
      }
    }
  }

  void _toggleReadingMode() {
    _controller.toggleReadingMode();
    _isVertical = _controller.readingMode.value == ReadingMode.vertical;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !File(_volume.filePath).existsSync()) {
      return Scaffold(
        appBar: AppBar(title: Text(_volume.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'PDF-файл не найден:\n${_volume.filePath}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _saveProgress();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.9),
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _volume.title,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(() => Text(
                      '${_controller.currentPage.value}/${_totalPages}',
                      style: const TextStyle(fontSize: 12),
                    )),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmarks),
              onPressed: _showBookmarksDialog,
              tooltip: 'Закладки (${_bookmarks.length})',
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_add),
              onPressed: _addBookmark,
              tooltip: 'Добавить закладку',
            ),
            IconButton(
              icon: const Icon(Icons.numbers),
              onPressed: _goToPage,
              tooltip: 'Перейти на страницу',
            ),
            Obx(
              () => Tooltip(
                message: _controller.readingMode.value.label,
                child: IconButton(
                  icon: Icon(
                    _controller.readingMode.value == ReadingMode.vertical
                        ? Icons.swap_vert
                        : Icons.swap_horiz,
                  ),
                  onPressed: _toggleReadingMode,
                ),
              ),
            ),
            if (!kIsWeb)
              IconButton(
                tooltip: 'Открыть во внешней программе',
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _openExternal(_volume.filePath),
              ),
          ],
        ),
        body: _buildPdfViewer(),
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (kIsWeb) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'PDF: ${_volume.title}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            const Text(
              'Для просмотра PDF в веб-версии,\nпожалуйста, используйте десктопное приложение.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    try {
      return SfPdfViewer.file(
        File(_volume.filePath),
        controller: _pdfController,
        onDocumentLoaded: (details) {
          _totalPages = _pdfController.pageCount ?? 1;
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              _pdfController.jumpToPage(_initialPage);
            } catch (e) {
              // Игнорируем ошибки перехода
            }
          });
        },
        onPageChanged: (details) {
          if (details.newPageNumber != null && details.newPageNumber! > 0) {
            _controller.currentPage.value = details.newPageNumber!;
            _totalPages = _pdfController.pageCount ?? 1;
          }
        },
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки PDF',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openExternal(String filePath) async {
    try {
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackbar('Не удалось открыть PDF');
      }
    } catch (e) {
      _showSnackbar('Не удалось открыть PDF: $e');
    }
  }
}
