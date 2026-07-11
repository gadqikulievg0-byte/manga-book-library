import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'volume.dart';

part 'book.g.dart';

// Enum должен быть снаружи класса
@HiveType(typeId: 2)
enum BookStatus {
  @HiveField(0)
  newBook,
  @HiveField(1)
  reading,
  @HiveField(2)
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
    sorted.sort((a, b) {
      // Пытаемся извлечь числа из названий томов для числовой сортировки
      final aNum = _extractVolumeNumber(a.title);
      final bNum = _extractVolumeNumber(b.title);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      return a.title.compareTo(b.title);
    });
    return sorted;
  }

  /// Извлекает число из названия тома (например "Том 1" -> 1, "Chapter 5" -> 5)
  int? _extractVolumeNumber(String title) {
    final match = RegExp(r'(\d+)').firstMatch(title);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
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
