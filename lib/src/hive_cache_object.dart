library flutter_cache_manager_hive;

import 'package:flutter_cache_manager/src/storage/cache_object.dart';

class HiveCacheObject extends CacheObject {
  final String? _key;

  @override
  String get key => _key ?? url;

  String? get actualKey => _key;

  HiveCacheObject(
    String url, {
    String? key,
    required String relativePath,
    required DateTime validTill,
    String? eTag,
    int? id,
    int? length,
    DateTime? touched,
  })  : _touched = touched,
        touchedMs = touched!.millisecondsSinceEpoch,
        validTillMs = validTill.millisecondsSinceEpoch,
        _key = key,
        super(url,
            key: key,
            relativePath: relativePath,
            validTill: validTill,
            eTag: eTag,
            id: id,
            length: length);

  int validTillMs;
  int? touchedMs;

  DateTime? _touched;
  void setTouched(DateTime touched) {
    _touched = touched;
    touchedMs = _touched!.millisecondsSinceEpoch;
  }

  @override
  DateTime? get touched => _touched;
}
