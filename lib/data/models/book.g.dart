// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 0;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String?,
      title: fields[1] as String,
      description: fields[2] as String?,
      coverPath: fields[3] as String?,
      volumes: (fields[4] as List?)?.cast<Volume>(),
      categories: (fields[5] as List?)?.cast<String>(),
      status: fields[6] as BookStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.coverPath)
      ..writeByte(4)
      ..write(obj.volumes)
      ..writeByte(5)
      ..write(obj.categories)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookStatusAdapter extends TypeAdapter<BookStatus> {
  @override
  final int typeId = 2;

  @override
  BookStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BookStatus.newBook;
      case 1:
        return BookStatus.reading;
      case 2:
        return BookStatus.read;
      default:
        return BookStatus.newBook;
    }
  }

  @override
  void write(BinaryWriter writer, BookStatus obj) {
    switch (obj) {
      case BookStatus.newBook:
        writer.writeByte(0);
        break;
      case BookStatus.reading:
        writer.writeByte(1);
        break;
      case BookStatus.read:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
