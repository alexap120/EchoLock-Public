// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardItemAdapter extends TypeAdapter<CardItem> {
  @override
  final int typeId = 2;

  @override
  CardItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardItem(
      number: fields[0] as String,
      holderName: fields[1] as String,
      expiryDate: fields[2] as String,
      cvv: fields[3] as String,
      pin: fields[4] as String?,
      firestoreId: fields[5] as String?,
      syncStatus: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CardItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.holderName)
      ..writeByte(2)
      ..write(obj.expiryDate)
      ..writeByte(3)
      ..write(obj.cvv)
      ..writeByte(4)
      ..write(obj.pin)
      ..writeByte(5)
      ..write(obj.firestoreId)
      ..writeByte(6)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
