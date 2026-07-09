import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import '../core/routes.dart';
import '../data/models/book.dart';
import '../data/models/volume.dart';
import '../data/repositories/book_repository.dart';
import '../controllers/book_controller.dart';
import '../core/pdf_cover_extractor.dart';

class VolumeListScreen extends StatefulWidget {
  const VolumeListScreen({super.key});

  @override
  State<VolumeListScreen> createState() => _VolumeListScreenState();
}

class _VolumeListScreenState extends State<VolumeListScreen> {
  late Book book;
  final BookRepository _repository = Get.find<BookRepository>();
  bool _isGeneratingCovers = false;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  void _loadBook() {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final bookId = args['bookId'] as String? ?? '';
    book = _repository.getBookById(bookId)!;

    // Генерируем обложки для томов, у которых их нет
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateMissingCovers();
    });
  }

  Future<void> _generateMissingCovers({bool showErrors = false}) async {
    if (_isGeneratingCovers || kIsWeb) return;

    bool hasMissingCovers = false;
    for (var i = 0; i < book.volumes.length; i++) {
      final volume = book.volumes[i];
      if (volume.coverPath == null || volume.coverPath!.isEmpty) {
        hasMissingCovers = true;
        break;
      }
    }

    if (!hasMissingCovers) {
      if (showErrors) {
        Get.snackbar('Готово', 'У всех томов уже есть обложки',
            snackPosition: SnackPosition.BOTTOM);
      }
      return;
    }

    _isGeneratingCovers = true;
    setState(() {});

    try {
      // Определяем папку книги по первому тому
      if (book.volumes.isEmpty) return;

      final firstVolumePath = book.volumes.first.filePath;
      final bookFolder = Directory(firstVolumePath).parent;
      final coversFolder = Directory(path.join(bookFolder.path, 'covers'));
      if (!await coversFolder.exists()) {
        await coversFolder.create();
      }

      int generated = 0;
      for (var i = 0; i < book.volumes.length; i++) {
        final volume = book.volumes[i];
        if (volume.coverPath == null || volume.coverPath!.isEmpty) {
          final coverPath = await PdfCoverExtractor.extractCoverFromPdf(
            pdfPath: volume.filePath,
            outputDir: coversFolder.path,
            volumeId: volume.id,
            showErrors: showErrors,
          );
          if (coverPath != null) {
            book.volumes[i] = book.volumes[i].copyWith(coverPath: coverPath);
            generated++;
          }
        }
      }

      if (generated > 0) {
        await _repository.saveBook(book);
        if (showErrors) {
          Get.snackbar('Готово', 'Сгенерировано обложек: $generated',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green);
        }
      } else if (showErrors) {
        Get.snackbar('Ошибка', 'Не удалось сгенерировать обложки',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      }
      setState(() {});
    } catch (e) {
      print('Ошибка генерации обложек: $e');
      if (showErrors) {
        Get.snackbar('Ошибка', 'Не удалось сгенерировать обложки: $e',
            snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      _isGeneratingCovers = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final volumes = book.sortedVolumes;
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth < 400 ? 2 : (screenWidth < 600 ? 3 : 4);

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        backgroundColor: Colors.black.withOpacity(0.85),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isGeneratingCovers
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh),
            onPressed: _isGeneratingCovers
                ? null
                : () => _generateMissingCovers(showErrors: true),
            tooltip: 'Сгенерировать обложки',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editBook,
            tooltip: 'Редактировать книгу',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBookInfo(),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            child: volumes.isEmpty
                ? _buildEmptyState()
                : _isGeneratingCovers
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Генерация обложек...',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: volumes.length,
                        itemBuilder: (context, index) {
                          final volume = volumes[index];
                          return _buildVolumeCard(volume, index);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _isGeneratingCovers
          ? null
          : FloatingActionButton(
              onPressed: _addVolume,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildVolumeCard(Volume volume, int index) {
    return GestureDetector(
      onTap: () => _openReader(volume),
      onLongPress: () => _showVolumeActions(volume, index),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildVolumeCover(volume),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              color: Colors.black.withOpacity(0.8),
              child: Text(
                volume.title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              color: Colors.black.withOpacity(0.6),
              child: Row(
                children: [
                  Icon(
                    volume.lastReadPage == -1
                        ? Icons.check_circle
                        : volume.lastReadPage > 0
                            ? Icons.auto_stories
                            : Icons.fiber_new,
                    size: 12,
                    color: volume.lastReadPage == -1
                        ? Colors.green
                        : volume.lastReadPage > 0
                            ? Colors.orange
                            : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      volume.lastReadPage == -1
                          ? 'Прочитан'
                          : volume.lastReadPage > 0
                              ? 'Читается'
                              : 'Новый',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeCover(Volume volume) {
    if (volume.coverPath == null || volume.coverPath!.isEmpty) {
      return Container(
        color: Colors.grey[850],
        child: const Center(
          child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
        ),
      );
    }

    if (kIsWeb) {
      try {
        if (volume.coverPath!.startsWith('data:image')) {
          final base64String = volume.coverPath!.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
          );
        } else {
          return Image.network(
            volume.coverPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
          );
        }
      } catch (e) {
        return _buildCoverPlaceholder();
      }
    } else {
      try {
        final file = File(volume.coverPath!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
          );
        } else {
          return _buildCoverPlaceholder();
        }
      } catch (e) {
        return _buildCoverPlaceholder();
      }
    }
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
      ),
    );
  }

  Widget _buildBookInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black.withOpacity(0.05),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildBookCover(60, 90),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (book.description != null)
                  Text(
                    book.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: book.status.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(book.status.icon,
                              size: 14, color: book.status.color),
                          const SizedBox(width: 4),
                          Text(
                            book.status.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: book.status.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '📚 ${book.volumeCount} том(ов)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCover(double width, double height) {
    if (book.coverPath == null || book.coverPath!.isEmpty) {
      return _buildPlaceholder(width, height);
    }

    if (kIsWeb) {
      try {
        if (book.coverPath!.startsWith('data:image')) {
          final base64String = book.coverPath!.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(width, height),
          );
        } else {
          return Image.network(
            book.coverPath!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(width, height),
          );
        }
      } catch (e) {
        return _buildPlaceholder(width, height);
      }
    } else {
      try {
        final file = File(book.coverPath!);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(width, height),
          );
        } else {
          return _buildPlaceholder(width, height);
        }
      } catch (e) {
        return _buildPlaceholder(width, height);
      }
    }
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.book, size: 30, color: Colors.grey),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_books, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Нет томов',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте PDF-файлы через кнопку "+"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _editBook() {
    Get.toNamed<void>(
      Routes.bookEdit,
      arguments: {'bookId': book.id},
    )?.then((_) {
      final updated = _repository.getBookById(book.id);
      if (updated != null) {
        setState(() {
          book = updated;
        });
        _generateMissingCovers();
      }
    });
  }

  void _addVolume() async {
    final controller = Get.find<BookController>();
    await controller.addVolume();
    final updated = _repository.getBookById(book.id);
    if (updated != null) {
      setState(() {
        book = updated;
      });
      _generateMissingCovers();
    }
  }

  void _openReader(Volume volume) {
    Get.toNamed<void>(
      Routes.reader,
      arguments: {
        'bookId': book.id,
        'volumeId': volume.id,
      },
    );
  }

  void _showVolumeActions(Volume volume, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.blue),
              title: const Text('Открыть'),
              onTap: () {
                Navigator.pop(context);
                _openReader(volume);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Переименовать'),
              onTap: () {
                Navigator.pop(context);
                _showEditVolumeDialog(volume, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить том'),
              onTap: () {
                Navigator.pop(context);
                _deleteVolume(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditVolumeDialog(Volume volume, int index) {
    final textController = TextEditingController(text: volume.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать том'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Название тома',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              book.volumes[index] =
                  book.volumes[index].copyWith(title: textController.text);
              await _repository.saveBook(book);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deleteVolume(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить том'),
        content: const Text('Вы уверены, что хотите удалить этот том?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              book.volumes.removeAt(index);
              await _repository.saveBook(book);
              setState(() {});
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
