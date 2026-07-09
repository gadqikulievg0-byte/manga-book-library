import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../core/routes.dart';
import '../data/models/book.dart';
import '../data/models/volume.dart';
import '../data/repositories/book_repository.dart';
import '../widgets/volume_tile.dart';

class VolumeListScreen extends StatefulWidget {
  const VolumeListScreen({super.key});

  @override
  State<VolumeListScreen> createState() => _VolumeListScreenState();
}

class _VolumeListScreenState extends State<VolumeListScreen> {
  late Book book;
  final BookRepository _repository = Get.find<BookRepository>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final bookId = args['bookId'] as String? ?? '';
    book = _repository.getBookById(bookId)!;
  }

  @override
  Widget build(BuildContext context) {
    final volumes = book.sortedVolumes;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editBook,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBookInfo(),
          Expanded(
            child: volumes.isEmpty
                ? _buildEmptyState()
                : _buildVolumeList(volumes),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVolume,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildCover(80, 120),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Томов: ${book.volumeCount}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (book.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    book.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(double width, double height) {
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
      child: const Icon(Icons.book, size: 40, color: Colors.grey),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_books, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Нет томов',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите на кнопку "+", чтобы добавить PDF-файл',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeList(List<Volume> volumes) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: volumes.length,
      itemBuilder: (context, index) {
        final volume = volumes[index];
        return VolumeTile(
          volume: volume,
          onTap: () => _openReader(volume),
          onDelete: () => _deleteVolume(index),
        );
      },
    );
  }

  void _editBook() {
    Get.toNamed<void>(
      Routes.bookEdit,
      arguments: {'bookId': book.id},
    );
  }

  void _addVolume() async {
    try {
      FilePickerResult? result;

      if (kIsWeb) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
      }

      if (result != null) {
        final file = result.files.single;
        String filePath;
        String fileName;

        if (kIsWeb) {
          filePath = file.name;
          fileName = file.name;
          Get.snackbar(
            'Информация',
            'В веб-версии PDF открывается временно',
            duration: const Duration(seconds: 3),
          );
        } else {
          filePath = file.path!;
          fileName = file.name;
        }

        final volume = Volume(
          title: fileName,
          filePath: filePath,
        );
        book.volumes.add(volume);
        await _repository.saveBook(book);
        setState(() {});
        Get.snackbar('Успех', 'Том добавлен: $fileName');
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось добавить том: $e');
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

  void _deleteVolume(int index) {
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
            onPressed: () {
              book.volumes.removeAt(index);
              _repository.saveBook(book);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
