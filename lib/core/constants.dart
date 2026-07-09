/// Константы приложения: имена Hive-боксов и идентификаторы типов.
class AppConstants {
  AppConstants._();

  /// Имя основного бокса для хранения книг.
  static const String booksBoxName = 'books';

  /// Hive typeId для модели [Book].
  static const int bookTypeId = 0;

  /// Hive typeId для модели [Volume].
  static const int volumeTypeId = 1;

  /// Имя бокса настроек приложения.
  static const String settingsBoxName = 'settings';

  /// Ключ режима чтения в боксе настроек.
  static const String readingModeKey = 'reading_mode';
}
