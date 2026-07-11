import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'dart:typed_data';

import '../models/book.dart';
import '../models/volume.dart';

class BookRepository extends GetxController {
  static const String _boxName = 'books';
  late Box<Book> _box;

  @override
  void onInit() {
    super.onInit();
    _box = Hive.box<Book>(_boxName);
  }

  List<Book> getAllBooks() {
    return _box.values.toList();
  }

  Book? getBookById(String id) {
    try {
      return _box.get(id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveBook(Book book) async {
    await _box.put(book.id, book);
  }

  Future<void> deleteBook(String id) async {
    await _box.delete(id);
  }

  Future<void> updateBook(Book book) async {
    await _box.put(book.id, book);
  }

  List<Book> searchBooks(String query) {
    if (query.isEmpty) return getAllBooks();
    return getAllBooks()
        .where((book) => book.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> saveReadingProgress(
      String bookId, String volumeId, int page, bool isBookmarked,
      {int? bookmarkPage}) async {
    final book = getBookById(bookId);
    if (book != null) {
      final volumeIndex = book.volumes.indexWhere((v) => v.id == volumeId);
      if (volumeIndex != -1) {
        book.volumes[volumeIndex].lastReadPage = page;
        book.volumes[volumeIndex].isBookmarked = isBookmarked;
        if (bookmarkPage != null) {
          book.volumes[volumeIndex].bookmarkPage = bookmarkPage;
        }

        // Обновляем статус книги на "Читается", если он еще "Новая"
        if (book.status == BookStatus.newBook) {
          book.status = BookStatus.reading;
        }

        await saveBook(book);
      }
    }
  }

  Future<void> updateBookStatus(String bookId, BookStatus newStatus) async {
    final book = getBookById(bookId);
    if (book != null) {
      book.status = newStatus;
      await saveBook(book);
    }
  }

  // Для веба - сохранение файлов в памяти
  Future<String?> saveFileForWeb(Uint8List fileBytes, String fileName) async {
    if (!kIsWeb) return null;
    // В вебе файлы хранятся в памяти
    return fileName;
  }

  Future<void> saveBookmark(String bookId, String volumeId, int page) async {
    final book = getBookById(bookId);
    if (book != null) {
      final volumeIndex = book.volumes.indexWhere((v) => v.id == volumeId);
      if (volumeIndex != -1) {
        // Если page = -1, значит закладок нет
        book.volumes[volumeIndex].isBookmarked = page >= 0;
        await saveBook(book);
      }
    }
  }

// Добавьте этот метод в BookRepository
  Future<void> markVolumeAsRead(String bookId, String volumeId) async {
    final book = getBookById(bookId);
    if (book != null) {
      final volumeIndex = book.volumes.indexWhere((v) => v.id == volumeId);
      if (volumeIndex != -1) {
        // Отмечаем том как прочитанный (устанавливаем lastReadPage на -1)
        book.volumes[volumeIndex].lastReadPage = -1;
        await saveBook(book);

        // Проверяем, все ли тома прочитаны
        final allRead = book.volumes.every((v) => v.lastReadPage == -1);
        if (allRead && book.status != BookStatus.read) {
          book.status = BookStatus.read;
          await saveBook(book);
        }
      }
    }
  }

  void loadBooks() {
    // Просто вызывает обновление, если нужно
    // Этот метод уже есть, но если нет - добавьте
  }
}
