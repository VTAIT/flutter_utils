// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test-model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TestModelAdapter extends TypeAdapter<TestModel> {
  @override
  final int typeId = 0;

  @override
  TestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestModel()
      ..logID = fields[0] as String
      ..plateNo = fields[1] as String
      ..pending = fields[2] as bool
      ..listObject = (fields[3] as List).cast<TestObject>();
  }

  @override
  void write(BinaryWriter writer, TestModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.logID)
      ..writeByte(1)
      ..write(obj.plateNo)
      ..writeByte(2)
      ..write(obj.pending)
      ..writeByte(3)
      ..write(obj.listObject);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
