// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoginItemAdapter extends TypeAdapter<LoginItem> {
  @override
  final int typeId = 0;

  @override
  LoginItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoginItem(
      title: fields[0] as String,
      username: fields[1] as String,
      password: fields[2] as String,
      firestoreId: fields[3] as String?,
      syncStatus: fields[4] as String,
      passwordFingerprint: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LoginItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.firestoreId)
      ..writeByte(4)
      ..write(obj.syncStatus)
      ..writeByte(5)
      ..write(obj.passwordFingerprint);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
