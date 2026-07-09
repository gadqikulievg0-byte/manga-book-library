import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../data/models/volume.dart';

class VolumeTile extends StatefulWidget {
  final Volume volume;
  final int index;
  final Function(int, String) onTitleChanged;
  final Function(int) onDelete;
  final Function(int, String) onCoverChanged;

  const VolumeTile({
    super.key,
    required this.volume,
    required this.index,
    required this.onTitleChanged,
    required this.onDelete,
    required this.onCoverChanged,
  });

  @override
  State<VolumeTile> createState() => _VolumeTileState();
}

class _VolumeTileState extends State<VolumeTile> {
  String? _coverPreview;
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _coverPreview = widget.volume.coverPath;
    _titleController.text = widget.volume.title;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 450,
      );

      if (image != null) {
        String? coverPath;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          coverPath = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        } else {
          coverPath = image.path;
        }
        setState(() {
          _coverPreview = coverPath;
        });
        widget.onCoverChanged(widget.index, coverPath!);
      }
    } catch (e) {
      // Ошибка
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Обложка тома (превью)
            GestureDetector(
              onTap: _pickCover,
              child: Container(
                width: 60,
                height: 85,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                  image: _coverPreview != null && _coverPreview!.isNotEmpty
                      ? DecorationImage(
                          image: kIsWeb
                              ? MemoryImage(
                                  base64Decode(_coverPreview!.split(',').last))
                              : FileImage(File(_coverPreview!))
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _coverPreview == null || _coverPreview!.isEmpty
                    ? const Icon(Icons.add_photo_alternate,
                        size: 24, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Название тома
            Expanded(
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название тома',
                  border: UnderlineInputBorder(),
                ),
                onChanged: (value) {
                  widget.onTitleChanged(widget.index, value);
                },
              ),
            ),
            // Кнопка удаления
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => widget.onDelete(widget.index),
            ),
          ],
        ),
      ),
    );
  }
}
