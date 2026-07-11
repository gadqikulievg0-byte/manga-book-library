import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import '../data/models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onBookTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;

  const BookCard({
    super.key,
    required this.book,
    required this.onBookTap,
    required this.onEdit,
    required this.onDelete,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double textSize;
    double iconSize;
    double statusSize;
    double paddingSize;

    if (screenWidth < 400) {
      textSize = 7;
      iconSize = 9;
      statusSize = 6;
      paddingSize = 2;
    } else if (screenWidth < 700) {
      textSize = 8;
      iconSize = 10;
      statusSize = 7;
      paddingSize = 2;
    } else if (screenWidth < 1000) {
      textSize = 9;
      iconSize = 12;
      statusSize = 8;
      paddingSize = 3;
    } else {
      textSize = 10;
      iconSize = 13;
      statusSize = 8;
      paddingSize = 3;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: isSelectionMode
            ? BorderSide(
                color: isSelected ? Colors.blue : Colors.white24,
                width: isSelected ? 2 : 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            onSelectionToggle?.call();
          } else {
            onBookTap.call();
          }
        },
        onLongPress: onLongPress,
        child: Stack(
          children: [
            // ЧЕКБОКС ВЫДЕЛЕНИЯ
            if (isSelectionMode)
              Positioned(
                top: paddingSize,
                left: paddingSize,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            // ОБЛОЖКА
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[850],
              child: _buildCover(),
            ),
            // СТАТУС - сверху справа
            Positioned(
              top: paddingSize,
              right: paddingSize,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: paddingSize, vertical: 1),
                decoration: BoxDecoration(
                  color: book.status.color,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      book.status.icon,
                      size: statusSize,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      book.status.label,
                      style: TextStyle(
                        fontSize: statusSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // НАЗВАНИЕ И ИНФОРМАЦИЯ - снизу
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: paddingSize + 2, vertical: paddingSize + 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: textSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: screenWidth < 700 ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Icon(
                          Icons.book,
                          size: iconSize * 0.7,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${book.volumeCount}',
                          style: TextStyle(
                            fontSize: textSize * 0.8,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (book.categories.isNotEmpty)
                          Flexible(
                            child: Text(
                              book.categories.join(', '),
                              style: TextStyle(
                                fontSize: textSize * 0.7,
                                color: Colors.white60,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // КНОПКИ - сверху слева (скрываем в режиме выделения)
            if (!isSelectionMode)
              Positioned(
                top: paddingSize,
                left: paddingSize,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.edit, size: iconSize, color: Colors.white),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: iconSize + 4,
                        minHeight: iconSize + 4,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        padding: EdgeInsets.all(paddingSize),
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: Icon(Icons.delete,
                          size: iconSize, color: Colors.white),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: iconSize + 4,
                        minHeight: iconSize + 4,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: EdgeInsets.all(paddingSize),
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

  Widget _buildCover() {
    // Пытаемся получить обложку книги
    String? coverToUse = book.coverPath;

    // Если обложки нет, пробуем взять из первого тома (по сортировке)
    if (coverToUse == null || coverToUse.isEmpty) {
      if (book.volumes.isNotEmpty) {
        final firstVol = book.sortedVolumes.first;
        if (firstVol.coverPath != null && firstVol.coverPath!.isNotEmpty) {
          coverToUse = firstVol.coverPath;
        }
      }
    }

    if (coverToUse == null || coverToUse.isEmpty) {
      return Container(
        color: Colors.grey[850],
        child: Center(
          child: Icon(
            Icons.book,
            size: 40,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    if (kIsWeb) {
      try {
        if (coverToUse.startsWith('data:image')) {
          final bytes = base64Decode(coverToUse.split(',').last);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 40),
          );
        }
        return Image.network(
          coverToUse,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 40),
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 40);
      }
    } else {
      try {
        final file = File(coverToUse);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 40),
          );
        }
        return Container(
          color: Colors.grey[850],
          child: Center(
            child: Icon(
              Icons.book,
              size: 40,
              color: Colors.grey[600],
            ),
          ),
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 40);
      }
    }
  }
}
