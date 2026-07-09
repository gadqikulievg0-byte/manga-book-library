import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'volume.dart';

part 'book.g.dart';

// Enum должен быть снаружи класса
enum BookStatus {
  newBook,
  reading,
  read,
}

extension BookStatusExtension on BookStatus {
  String get label {
    switch (this) {
      case BookStatus.newBook:
        return 'Новая';
      case BookStatus.reading:
        return 'Читается';
      case BookStatus.read:
        return 'Прочитана';
    }
  }

  IconData get icon {
    switch (this) {
      case BookStatus.newBook:
        return Icons.fiber_new;
      case BookStatus.reading:
        return Icons.auto_stories;
      case BookStatus.read:
        return Icons.check_circle;
    }
  }

  Color get color {
    switch (this) {
      case BookStatus.newBook:
        return Colors.green;
      case BookStatus.reading:
        return Colors.orange;
      case BookStatus.read:
        return Colors.blue;
    }
  }
}

@HiveType(typeId: 0)
class Book extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? coverPath;

  @HiveField(4)
  List<Volume> volumes;

  @HiveField(5)
  List<String> categories;

  @HiveField(6)
  BookStatus status;

  Book({
    String? id,
    required this.title,
    this.description,
    this.coverPath,
    List<Volume>? volumes,
    List<String>? categories,
    this.status = BookStatus.newBook, // Значение по умолчанию
  })  : id = id ?? const Uuid().v4(),
        volumes = volumes ?? [],
        categories = categories ?? [];

  int get volumeCount => volumes.length;

  List<Volume> get sortedVolumes {
    final sorted = List<Volume>.from(volumes);
    sorted.sort((a, b) => a.title.compareTo(b.title));
    return sorted;
  }

  Book copyWith({
    String? title,
    String? description,
    String? coverPath,
    List<Volume>? volumes,
    List<String>? categories,
    BookStatus? status,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverPath: coverPath ?? this.coverPath,
      volumes: volumes ?? this.volumes,
      categories: categories ?? this.categories,
      status: status ?? this.status,
    );
  }
}
