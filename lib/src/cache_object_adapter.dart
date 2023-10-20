library flutter_cache_manager_hive;

import 'package:hive/hive.dart';

import 'hive_cache_object.dart';

class HiveCacheObjectAdapter extends TypeAdapter<HiveCacheObject> {
  static bool _isRegistered = false;
  static bool get isRegistered => _isRegistered;

  static const TYPE_ID = 101;
  HiveCacheObjectAdapter({this.typeId = TYPE_ID}) {
    _isRegistered = true;
  }

  @override
  final int typeId;

  @override
  HiveCacheObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return HiveCacheObject(
      fields[0] as String,
      key: fields[1] as String?,
      relativePath: fields[2] as String,
      validTill: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      eTag: fields[4] as String?,
      id: fields[5] as int?,
      length: fields[6] as int?,
      touched: fields[7] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
    );
  }

  @override
  void write(BinaryWriter writer, HiveCacheObject obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.actualKey)
      ..writeByte(2)
      ..write(obj.relativePath)
      ..writeByte(3)
      ..write(obj.validTillMs)
      ..writeByte(4)
      ..write(obj.eTag)
      ..writeByte(5)
      ..write(obj.id)
      ..writeByte(6)
      ..write(obj.length)
      ..writeByte(7)
      ..write(obj.touchedMs);
  }
}
