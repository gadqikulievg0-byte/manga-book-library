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
import '../core/snackbar_helper.dart';

class VolumeListScreen extends StatefulWidget {
  const VolumeListScreen({super.key});

  @override
  State<VolumeListScreen> createState() => _VolumeListScreenState();
}

class _VolumeListScreenState extends State<VolumeListScreen> {
  late Book book;
  final BookRepository _repository = Get.find<BookRepository>();
  bool _isGeneratingCovers = false;
  bool _isSelectionMode = false;
  final Set<int> _selectedVolumeIndices = {};

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  void _loadBook() {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final bookId = args['bookId'] as String? ?? '';
    book = _repository.getBookById(bookId)!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateMissingCovers();
    });
  }

  Future<void> _generateMissingCovers({bool showErrors = false}) async {
    if (_isGeneratingCovers || kIsWeb) return;
    bool hasMissing = book.volumes.any(
      (v) => v.coverPath == null || v.coverPath!.isEmpty,
    );
    if (!hasMissing) return;

    _isGeneratingCovers = true;
    setState(() {});

    try {
      if (book.volumes.isEmpty) return;
      final firstPath = book.volumes.first.filePath;
      final bookFolder = Directory(firstPath).parent;
      final coversFolder = Directory(path.join(bookFolder.path, 'covers'));
      if (!await coversFolder.exists()) {
        await coversFolder.create();
      }

      int generated = 0;
      for (var i = 0; i < book.volumes.length; i++) {
        final vol = book.volumes[i];
        if (vol.coverPath != null && vol.coverPath!.isNotEmpty) continue;

        final coverPath = await PdfCoverExtractor.extractCoverFromPdf(
          pdfPath: vol.filePath,
          outputDir: coversFolder.path,
          volumeId: vol.id,
          showErrors: showErrors,
        );
        if (coverPath != null) {
          book.volumes[i] = book.volumes[i].copyWith(coverPath: coverPath);
          generated++;
        }
      }

      if (generated > 0) {
        await _repository.saveBook(book);
        SnackbarHelper.success('Сгенерировано обложек: $generated');
      } else if (showErrors) {
        SnackbarHelper.error('Не удалось сгенерировать обложки');
      }
      setState(() {});
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      _isGeneratingCovers = false;
      setState(() {});
    }
  }

  void _toggleVolumeSelection(int index) {
    setState(() {
      if (_selectedVolumeIndices.contains(index)) {
        _selectedVolumeIndices.remove(index);
        if (_selectedVolumeIndices.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedVolumeIndices.add(index);
        _isSelectionMode = true;
      }
    });
  }

  void _toggleSelectAllVolumes() {
    final volumes = book.sortedVolumes;
    setState(() {
      if (_selectedVolumeIndices.length == volumes.length) {
        _selectedVolumeIndices.clear();
        _isSelectionMode = false;
      } else {
        _selectedVolumeIndices.addAll(List.generate(volumes.length, (i) => i));
        _isSelectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedVolumeIndices.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedVolumes() async {
    if (_selectedVolumeIndices.isEmpty) return;
    final sorted = book.sortedVolumes;
    final indicesToRemove = _selectedVolumeIndices.toList()
      ..sort((a, b) => b.compareTo(a));
    for (final index in indicesToRemove) {
      if (index < sorted.length) {
        final volId = sorted[index].id;
        final origIndex = book.volumes.indexWhere((v) => v.id == volId);
        if (origIndex != -1) {
          book.volumes.removeAt(origIndex);
        }
      }
    }
    await _repository.saveBook(book);
    _exitSelectionMode();
    setState(() {});
    SnackbarHelper.success('Тома удалены');
  }

  @override
  Widget build(BuildContext context) {
    final volumes = book.sortedVolumes;
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = screenWidth < 400 ? 3 : (screenWidth < 600 ? 4 : 5);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('Выбрано: ${_selectedVolumeIndices.length}')
            : Text(book.title),
        backgroundColor: Colors.black.withOpacity(0.85),
        foregroundColor: Colors.white,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectAllVolumes,
              tooltip: 'Выбрать все',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _selectedVolumeIndices.isEmpty
                  ? null
                  : _deleteSelectedVolumes,
              tooltip: 'Удалить выбранные',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitSelectionMode,
              tooltip: 'Отменить',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => setState(() => _isSelectionMode = true),
              tooltip: 'Выделить тома',
            ),
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
                        padding: const EdgeInsets.all(6),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: volumes.length,
                        itemBuilder: (context, index) {
                          return _buildVolumeCard(volumes[index], index);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode || _isGeneratingCovers
          ? null
          : FloatingActionButton(
              onPressed: _addVolumes,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildVolumeCard(Volume volume, int index) {
    final isSelected = _selectedVolumeIndices.contains(index);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (volume.lastReadPage == -1) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Прочитан';
    } else if (volume.lastReadPage > 0) {
      statusColor = Colors.orange;
      statusIcon = Icons.auto_stories;
      statusText = 'Читается';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.fiber_new;
      statusText = 'Новый';
    }

    return GestureDetector(
      onTap: _isSelectionMode
          ? () => _toggleVolumeSelection(index)
          : () => _openReader(volume),
      onLongPress: () {
        if (!_isSelectionMode) {
          _toggleVolumeSelection(index);
        } else {
          _showVolumeActions(volume, index);
        }
      },
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildVolumeCover(volume),
                ),
                Container(
                  color: Colors.black.withOpacity(0.75),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Text(
                    volume.title,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  color: statusColor.withOpacity(0.85),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
          if (_isSelectionMode)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVolumeCover(Volume volume) {
    if (volume.coverPath == null || volume.coverPath!.isEmpty) {
      return Container(
        color: Colors.grey[850],
        child: const Center(
          child: Icon(Icons.picture_as_pdf, size: 32, color: Colors.red),
        ),
      );
    }

    try {
      if (kIsWeb) {
        if (volume.coverPath!.startsWith('data:image')) {
          final base64String = volume.coverPath!.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(bytes, fit: BoxFit.cover);
        }
        return Image.network(volume.coverPath!, fit: BoxFit.cover);
      } else {
        final file = File(volume.coverPath!);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      }
    } catch (_) {}
    return _buildCoverPlaceholder();
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: Icon(Icons.picture_as_pdf, size: 32, color: Colors.red),
      ),
    );
  }

  Widget _buildBookInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black.withOpacity(0.05),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 72,
              child: _buildBookCover(48, 72),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (book.description != null && book.description!.isNotEmpty)
                  Text(
                    book.description!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: book.status.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(book.status.icon,
                              size: 11, color: book.status.color),
                          const SizedBox(width: 3),
                          Text(
                            book.status.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: book.status.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '📚 ${book.volumeCount}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
    String? coverToUse = book.coverPath;

    if (coverToUse == null || coverToUse.isEmpty) {
      if (book.volumes.isNotEmpty) {
        final firstVol = book.sortedVolumes.first;
        if (firstVol.coverPath != null && firstVol.coverPath!.isNotEmpty) {
          coverToUse = firstVol.coverPath;
        }
      }
    }

    if (coverToUse == null || coverToUse.isEmpty) {
      return _buildPlaceholder(width, height);
    }
    try {
      if (kIsWeb) {
        if (coverToUse.startsWith('data:image')) {
          final bytes = base64Decode(coverToUse.split(',').last);
          return Image.memory(bytes,
              width: width, height: height, fit: BoxFit.cover);
        }
        return Image.network(coverToUse,
            width: width, height: height, fit: BoxFit.cover);
      } else {
        final file = File(coverToUse);
        if (file.existsSync()) {
          return Image.file(file,
              width: width, height: height, fit: BoxFit.cover);
        }
      }
    } catch (_) {}
    return _buildPlaceholder(width, height);
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.book, size: 24, color: Colors.grey),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_books, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Нет томов',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Добавьте PDF через "+"',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _editBook() {
    Get.toNamed<void>(Routes.bookEdit, arguments: {'bookId': book.id})
        ?.then((_) {
      final updated = _repository.getBookById(book.id);
      if (updated != null) {
        setState(() => book = updated);
        _generateMissingCovers();
      }
    });
  }

  void _addVolumes() async {
    final controller = Get.find<BookController>();
    await controller.addMultipleVolumes();
    final updated = _repository.getBookById(book.id);
    if (updated != null) {
      setState(() => book = updated);
      _generateMissingCovers();
    }
  }

  void _openReader(Volume volume) {
    Get.toNamed<void>(Routes.reader, arguments: {
      'bookId': book.id,
      'volumeId': volume.id,
    });
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
        content: const Text('Вы уверены?'),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
