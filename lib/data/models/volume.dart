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

  Volume({
    String? id,
    required this.title,
    required this.filePath,
    this.lastReadPage = 0,
    this.isBookmarked = false,
  }) : id = id ?? const Uuid().v4();

  // Геттер для имени файла
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
  }) {
    return Volume(
      id: id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
