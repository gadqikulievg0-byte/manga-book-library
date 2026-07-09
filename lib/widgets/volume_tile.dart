import 'package:flutter/material.dart';
import '../data/models/volume.dart';

class VolumeTile extends StatelessWidget {
  final Volume volume;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const VolumeTile({
    super.key,
    required this.volume,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(volume.title),
        subtitle: Text(volume.fileName),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
