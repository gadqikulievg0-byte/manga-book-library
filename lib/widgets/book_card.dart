import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import '../data/models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // ПРОСТО ИСПОЛЬЗУЕМ MEDIAQUERY ДЛЯ ОПРЕДЕЛЕНИЯ РАЗМЕРА
    final screenWidth = MediaQuery.of(context).size.width;

    // ОПРЕДЕЛЯЕМ РАЗМЕР КАРТОЧКИ ПО ШИРИНЕ ЭКРАНА
    double textSize;
    double iconSize;
    double statusSize;
    double paddingSize;

    if (screenWidth < 400) {
      // Очень маленький экран
      textSize = 8;
      iconSize = 10;
      statusSize = 7;
      paddingSize = 2;
    } else if (screenWidth < 700) {
      // Маленький экран
      textSize = 9;
      iconSize = 11;
      statusSize = 8;
      paddingSize = 3;
    } else if (screenWidth < 1000) {
      // Средний экран
      textSize = 11;
      iconSize = 14;
      statusSize = 9;
      paddingSize = 4;
    } else {
      // Большой экран
      textSize = 13;
      iconSize = 16;
      statusSize = 10;
      paddingSize = 5;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // ОБЛОЖКА
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
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
                  color: book.status.color.withOpacity(0.85),
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
                      Colors.black.withOpacity(0.75),
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
            // КНОПКИ - сверху слева
            Positioned(
              top: paddingSize,
              left: paddingSize,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: iconSize, color: Colors.white),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: iconSize + 4,
                      minHeight: iconSize + 4,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      padding: EdgeInsets.all(paddingSize),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon:
                        Icon(Icons.delete, size: iconSize, color: Colors.white),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: iconSize + 4,
                      minHeight: iconSize + 4,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.6),
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
    if (book.coverPath == null || book.coverPath!.isEmpty) {
      return Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: Colors.grey[400],
        ),
      );
    }

    if (kIsWeb) {
      try {
        if (book.coverPath!.startsWith('data:image')) {
          final bytes = base64Decode(book.coverPath!.split(',').last);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 40),
          );
        }
        return Image.network(
          book.coverPath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 40),
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 40);
      }
    } else {
      try {
        final file = File(book.coverPath!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 40),
          );
        }
        return Center(
          child: Icon(
            Icons.book,
            size: 40,
            color: Colors.grey[400],
          ),
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 40);
      }
    }
  }
}
