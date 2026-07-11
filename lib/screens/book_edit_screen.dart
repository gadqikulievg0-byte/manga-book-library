import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_controller.dart';
import '../widgets/category_selector.dart';
import '../data/models/book.dart';

class BookEditScreen extends StatefulWidget {
  const BookEditScreen({super.key});

  @override
  State<BookEditScreen> createState() => _BookEditScreenState();
}

class _BookEditScreenState extends State<BookEditScreen> {
  late final BookController controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(BookController());
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final bookId = args['bookId'] as String?;

    controller.clear();
    controller.loadBook(bookId);

    _titleController.text = controller.title.value;
    _descriptionController.text = controller.description.value;

    _titleController.addListener(() {
      controller.title.value = _titleController.text;
    });
    _descriptionController.addListener(() {
      controller.description.value = _descriptionController.text;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.isEditing ? 'Редактировать книгу' : 'Новая книга',
            )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Отмена'),
          ),
        ],
      ),
      body: Obx(() => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoverSection(),
                const SizedBox(height: 16),
                _buildTitleField(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 16),
                _buildStatusSection(),
                const SizedBox(height: 16),
                _buildCategoriesSection(),
                const SizedBox(height: 16),
                _buildVolumesSection(),
                const SizedBox(height: 24),
                _buildSaveButton(),
              ],
            ),
          )),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статус книги',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BookStatus.values.map((status) {
            final isSelected = controller.selectedStatus.value == status;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(status.icon, size: 16, color: status.color),
                  const SizedBox(width: 4),
                  Text(status.label),
                ],
              ),
              selected: isSelected,
              onSelected: (_) {
                controller.setStatus(status);
              },
              selectedColor: status.color.withOpacity(0.2),
              checkmarkColor: status.color,
              avatar: isSelected
                  ? Icon(Icons.check, size: 16, color: status.color)
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return CategorySelector(bookController: controller);
  }

  Widget _buildCoverSection() {
    final hasCover = controller.coverPath.value.isNotEmpty;

    return GestureDetector(
      onTap: controller.pickCover,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          image: (hasCover && !kIsWeb)
              ? DecorationImage(
                  image: FileImage(File(controller.coverPath.value)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: !hasCover
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Нажмите для добавления обложки'),
                ],
              )
            : kIsWeb
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 48, color: Colors.green),
                      SizedBox(height: 8),
                      Text('Обложка добавлена (веб)'),
                    ],
                  )
                : null,
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Название книги *',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Описание',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildVolumesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Тома (${controller.volumes.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              onPressed: controller.addMultipleVolumes,
              icon: const Icon(Icons.add),
              label: const Text('Добавить PDF'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (controller.volumes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('Нет добавленных томов'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.volumes.length,
            itemBuilder: (context, index) {
              final volume = controller.volumes[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 40,
                      height: 56,
                      child: _buildVolumeCoverPreview(volume),
                    ),
                  ),
                  title: Text(volume.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditVolumeDialog(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => controller.removeVolume(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showEditVolumeDialog(int index) {
    final volume = controller.volumes[index];
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
            onPressed: () {
              controller.updateVolumeTitle(index, textController.text);
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCoverPreview(volume) {
    if (volume.coverPath == null || volume.coverPath!.isEmpty) {
      return Container(
        color: Colors.grey[850],
        child: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
      );
    }

    if (kIsWeb) {
      try {
        if (volume.coverPath!.startsWith('data:image')) {
          final base64String = volume.coverPath!.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(bytes, fit: BoxFit.cover);
        } else {
          return Image.network(volume.coverPath!, fit: BoxFit.cover);
        }
      } catch (e) {
        return Container(
          color: Colors.grey[850],
          child: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
        );
      }
    } else {
      try {
        final file = File(volume.coverPath!);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        } else {
          return Container(
            color: Colors.grey[850],
            child:
                const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
          );
        }
      } catch (e) {
        return Container(
          color: Colors.grey[850],
          child: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
        );
      }
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : _save,
        child: controller.isLoading.value
            ? const CircularProgressIndicator()
            : const Text('Сохранить книгу'),
      ),
    );
  }

  Future<void> _save() async {
    final saved = await controller.saveBook();
    if (saved) {
      Get.back(result: true);
    }
  }
}
