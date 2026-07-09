// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VolumeAdapter extends TypeAdapter<Volume> {
  @override
  final int typeId = 1;

  @override
  Volume read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Volume(
      id: fields[0] as String?,
      title: fields[1] as String,
      filePath: fields[2] as String,
      lastReadPage: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Volume obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.lastReadPage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolumeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
