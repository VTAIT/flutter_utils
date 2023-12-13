// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test-object.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TestObjectAdapter extends TypeAdapter<TestObject> {
  @override
  final int typeId = 1;

  @override
  TestObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestObject()
      ..logID = fields[0] as int
      ..plateNo = fields[1] as String
      ..pending = fields[2] as bool
      ..listInt = (fields[3] as List).cast<int>();
  }

  @override
  void write(BinaryWriter writer, TestObject obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.logID)
      ..writeByte(1)
      ..write(obj.plateNo)
      ..writeByte(2)
      ..write(obj.pending)
      ..writeByte(3)
      ..write(obj.listInt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
