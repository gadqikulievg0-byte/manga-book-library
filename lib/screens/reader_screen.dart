import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/reader_controller.dart';
import '../data/models/book.dart';
import '../data/models/volume.dart';
import '../data/repositories/book_repository.dart';
import '../core/snackbar_helper.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ReaderController _controller;
  late final Volume _volume;
  late final String _bookId;
  late final int _initialPage;
  int _totalPages = 1;
  bool _isBookmarked = false;
  int _currentPage = 1;
  PdfViewerController? _pdfViewerController;
  PdfDocumentRef? _documentRef;

  final Map<int, String> _bookmarks = {};

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ReaderController>();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _bookId = args['bookId'] as String? ?? '';
    final volumeId = args['volumeId'] as String? ?? '';

    final book = Get.find<BookRepository>().getBookById(_bookId);
    _volume = book!.volumes.firstWhere((v) => v.id == volumeId);

    _controller.initReader(bookId: _bookId, volume: _volume);
    _initialPage = (_volume.lastReadPage + 1).clamp(1, 999999);
    _isBookmarked = _volume.isBookmarked;

    _updateBookStatus();
    _loadBookmarks();
    _loadPdf();
  }

  void _handlePageChange() {
    if (_pdfViewerController != null && _pdfViewerController!.isReady) {
      setState(() {
        _currentPage = _pdfViewerController!.pageNumber ?? 1;
      });
    }
  }

  @override
  void dispose() {
    _pdfViewerController?.removeListener(_handlePageChange);
    _saveProgress();
    super.dispose();
  }

  void _updateBookStatus() async {
    final book = Get.find<BookRepository>().getBookById(_bookId);
    if (book != null && book.status == BookStatus.newBook) {
      book.status = BookStatus.reading;
      await Get.find<BookRepository>().saveBook(book);
    }
  }

  void _loadBookmarks() {
    if (_volume.isBookmarked && _volume.bookmarkPage != null) {
      _bookmarks[_volume.bookmarkPage!] = 'Страница ${_volume.bookmarkPage}';
    }
  }

  Future<void> _loadPdf() async {
    try {
      _documentRef = PdfDocumentRefFile(_volume.filePath);
      setState(() {});
    } catch (e) {
      SnackbarHelper.error('Не удалось загрузить PDF');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final page = _currentPage;
      final totalPages = _totalPages;
      if (page > 0) {
        await _controller.saveProgress(page - 1, _isBookmarked);

        final isFinished = page >= totalPages;
        if (isFinished) {
          await _controller.markVolumeAsRead();
          SnackbarHelper.success('Том прочитан!');
        }
      }
    } catch (e) {
      // Игнорируем ошибки при сохранении
    }
  }

  void _addBookmark() async {
    final currentPage = _currentPage;
    if (_bookmarks.containsKey(currentPage)) {
      SnackbarHelper.info('Закладка уже есть на этой странице');
      return;
    }
    setState(() {
      _bookmarks[currentPage] = 'Страница $currentPage';
    });
    await _controller.saveBookmark(currentPage);
    SnackbarHelper.success('Закладка добавлена на стр. $currentPage');
  }

  void _removeBookmark(int page) async {
    setState(() => _bookmarks.remove(page));
    if (_bookmarks.isEmpty) await _controller.saveBookmark(-1);
    SnackbarHelper.info('Закладка удалена');
  }

  void _showBookmarksDialog() {
    if (_bookmarks.isEmpty) {
      SnackbarHelper.info('Нет сохраненных закладок');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Закладки'),
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
                  _goToPageNumber(entry.key);
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
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _goToPageNumber(int page) {
    if (_pdfViewerController != null && _pdfViewerController!.isReady) {
      _pdfViewerController!.goToPage(pageNumber: page);
    }
    setState(() => _currentPage = page);
  }

  void _goToPage() async {
    final totalPages = _totalPages;
    final textController = TextEditingController();
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
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(textController.text);
              if (page != null && page >= 1 && page <= totalPages) {
                Navigator.pop(context, page);
              } else {
                SnackbarHelper.info('Введите номер страницы (1-$totalPages)');
              }
            },
            child: const Text('Перейти'),
          ),
        ],
      ),
    );
    if (pageNumber != null) {
      _goToPageNumber(pageNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !File(_volume.filePath).existsSync()) {
      return Scaffold(
        appBar: AppBar(title: Text(_volume.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('PDF-файл не найден:\n${_volume.filePath}',
                textAlign: TextAlign.center),
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
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Expanded(
                child: Text(_volume.title,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '$_currentPage/$_totalPages',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  if (_pdfViewerController != null &&
                      _pdfViewerController!.isReady) {
                    _pdfViewerController!.zoomUp();
                  }
                },
                tooltip: 'Увеличить'),
            IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  if (_pdfViewerController != null &&
                      _pdfViewerController!.isReady) {
                    _pdfViewerController!.zoomDown();
                  }
                },
                tooltip: 'Уменьшить'),
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_currentPage > 1 &&
                      _pdfViewerController != null &&
                      _pdfViewerController!.isReady) {
                    _pdfViewerController!
                        .goToPage(pageNumber: _currentPage - 1);
                    setState(() => _currentPage--);
                  }
                },
                tooltip: 'Предыдущая страница'),
            IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  if (_currentPage < _totalPages &&
                      _pdfViewerController != null &&
                      _pdfViewerController!.isReady) {
                    _pdfViewerController!
                        .goToPage(pageNumber: _currentPage + 1);
                    setState(() => _currentPage++);
                  }
                },
                tooltip: 'Следующая страница'),
            IconButton(
                icon: const Icon(Icons.bookmarks),
                onPressed: _showBookmarksDialog,
                tooltip: 'Закладки (${_bookmarks.length})'),
            IconButton(
                icon: const Icon(Icons.bookmark_add),
                onPressed: _addBookmark,
                tooltip: 'Добавить закладку'),
            IconButton(
                icon: const Icon(Icons.numbers),
                onPressed: _goToPage,
                tooltip: 'Перейти на страницу'),
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
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('PDF: ${_volume.title}',
                style: const TextStyle(color: Colors.white, fontSize: 18)),
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

    if (_documentRef == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    return PdfViewer(
      _documentRef!,
      params: PdfViewerParams(
        onDocumentChanged: (doc) async {
          if (doc != null) {
            setState(() {
              _totalPages = doc.pages.length;
            });
          }
        },
        onViewerReady: (doc, controller) async {
          _pdfViewerController = controller;
          // Добавляем слушатель для отслеживания страницы
          controller.addListener(_handlePageChange);
          // Переход к начальной странице
          if (_initialPage > 1) {
            controller.goToPage(pageNumber: _initialPage);
          }
        },
      ),
    );
  }

  Future<void> _openExternal(String filePath) async {
    try {
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        SnackbarHelper.error('Не удалось открыть PDF');
      }
    } catch (e) {
      SnackbarHelper.error('Не удалось открыть PDF: $e');
    }
  }
}
