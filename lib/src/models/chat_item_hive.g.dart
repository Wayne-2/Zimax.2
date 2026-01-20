// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_item_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatItemHiveAdapter extends TypeAdapter<ChatItemHive> {
  @override
  final int typeId = 1;

  @override
  ChatItemHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatItemHive(
      roomId: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      avatar: fields[3] as String,
      preview: fields[4] as String,
      time: fields[5] as String,
      online: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ChatItemHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.roomId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.avatar)
      ..writeByte(4)
      ..write(obj.preview)
      ..writeByte(5)
      ..write(obj.time)
      ..writeByte(6)
      ..write(obj.online);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatItemHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
