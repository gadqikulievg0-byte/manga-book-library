import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'volume.g.dart';

@HiveType(typeId: 1)
class Volume extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String filePath;

  @HiveField(3)
  int lastReadPage;

  @HiveField(4)
  bool isBookmarked;

  @HiveField(5) // НОВОЕ ПОЛЕ
  String? coverPath;

  @HiveField(6) // Страница закладки
  int? bookmarkPage;

  Volume({
    String? id,
    required this.title,
    required this.filePath,
    this.lastReadPage = 0,
    this.isBookmarked = false,
    this.coverPath,
    this.bookmarkPage,
  }) : id = id ?? const Uuid().v4();

  // Конструктор для Hive, чтобы избежать ошибок при чтении старых данных
  Volume.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        title = json['title'] as String,
        filePath = json['filePath'] as String,
        lastReadPage = json['lastReadPage'] as int? ?? 0,
        isBookmarked = json['isBookmarked'] as bool? ?? false,
        coverPath = json['coverPath'] as String?,
        bookmarkPage = json['bookmarkPage'] as int?;

  String get fileName {
    if (kIsWeb) {
      return filePath.split('/').last;
    }
    try {
      return File(filePath).uri.pathSegments.last;
    } catch (e) {
      return filePath.split('/').last;
    }
  }

  Volume copyWith({
    String? title,
    String? filePath,
    int? lastReadPage,
    bool? isBookmarked,
    String? coverPath,
    int? bookmarkPage,
  }) {
    return Volume(
      id: id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      coverPath: coverPath ?? this.coverPath,
      bookmarkPage: bookmarkPage ?? this.bookmarkPage,
    );
  }
}
