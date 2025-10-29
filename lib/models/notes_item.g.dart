// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteItemAdapter extends TypeAdapter<NoteItem> {
  @override
  final int typeId = 1;

  @override
  NoteItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteItem(
      title: fields[0] as String,
      content: fields[1] as String,
      firestoreId: fields[2] as String?,
      syncStatus: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NoteItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.firestoreId)
      ..writeByte(3)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
