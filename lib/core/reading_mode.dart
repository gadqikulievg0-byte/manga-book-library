/// Режим прокрутки в PDF-читалке.
enum ReadingMode {
  /// Вертикальная прокрутка — для манги и комиксов.
  vertical('Вертикально (манга)'),

  /// Горизонтальная прокрутка — для книг.
  horizontal('Горизонтально (книга)');

  const ReadingMode(this.label);

  final String label;

  ReadingMode get toggled =>
      this == ReadingMode.vertical ? ReadingMode.horizontal : ReadingMode.vertical;
}
