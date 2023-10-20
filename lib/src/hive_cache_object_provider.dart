library flutter_cache_manager_hive;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:flutter_cache_manager_hive/flutter_cache_manager_hive.dart';
import 'package:hashlib/src/crc64.dart';
import 'package:hive/hive.dart';

import 'hive_cache_object.dart';

class HiveCacheObjectProvider implements CacheInfoRepository {
  // simple crc64 hash for id
  int _hiveId(String key) => crc64code(key);

  final String boxName;
  final String? path;
  late final LazyBox<HiveCacheObject> _box;

  HiveCacheObjectProvider(this.boxName, {this.path});

  @override
  Future<bool> open() async {
    // dumb-proof check
    if (!HiveCacheObjectAdapter.isRegistered) {
      throw UnsupportedError(
          'You need to register the [HiveCacheObjectAdapter] adapter via [Hive.registerAdapter] first!');
    }

    _box = await Hive.openLazyBox(boxName, path: path);
    return true;
  }

  @override
  Future<dynamic> updateOrInsert(CacheObject cacheObject) async {
    return insert(cacheObject);
  }

  @override
  Future<CacheObject> insert(CacheObject cacheObject,
      {bool setTouchedToNow = true}) async {
    final hiveCacheObject = HiveCacheObject(
      cacheObject.url,
      key: cacheObject.key == cacheObject.url ? null : cacheObject.key,
      relativePath: cacheObject.relativePath,
      validTill: cacheObject.validTill,
      eTag: cacheObject.eTag,
      id: _hiveId(cacheObject.key),
      length: cacheObject.length,
      touched: setTouchedToNow ? DateTime.now() : cacheObject.touched,
    );

    await _box.put(hiveCacheObject.id, hiveCacheObject);
    return hiveCacheObject;
  }

  @override
  Future<CacheObject?> get(String key) {
    return _box.get(_hiveId(key));
  }

  @override
  Future<int> delete(int id) async {
    await _box.delete(id);
    return 1;
  }

  @override
  Future<int> deleteAll(Iterable<int> ids) async {
    await _box.deleteAll(ids);
    return ids.length;
  }

  @override
  Future<int> update(CacheObject cacheObject,
      {bool setTouchedToNow = true}) async {
    await insert(cacheObject);
    return 1;
  }

  Iterable<Future<HiveCacheObject>> _allObjectsIterable() =>
      _box.keys.map((key) async => (await _box.get(key))!);

  @override
  Future<List<HiveCacheObject>> getAllObjects() {
    return Future.wait(_allObjectsIterable());
  }

  @override
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) async {
    final dayAgo =
        DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;

    if (capacity > _box.length) {
      return <CacheObject>[];
    }

    /// all objects sorted descending by touched where touched is older than day ago
    final objects = <CacheObject>[];
    for (final future in _allObjectsIterable()) {
      final cacheObject = await future;
      if ((cacheObject.touchedMs ?? 0) < dayAgo) {
        objects.add(cacheObject);
      }
    }

    objects.sort((a, b) => b.touched!.compareTo(a.touched!));

    return objects.sublist(capacity);
  }

  @override
  Future<List<CacheObject>> getOldObjects(Duration maxAge) async {
    final then = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;

    final allOldObjects = (await getAllObjects())
        .where((cacheObject) => (cacheObject.touchedMs ?? 0) < then)
        .toList();

    return allOldObjects;
  }

  @override
  Future<bool> close() async {
    // this is usually never called
    await _box.compact();
    await _box.close();
    return true;
  }

  @override
  Future<void> deleteDataFile() {
    return _box.deleteFromDisk();
  }

  @override
  Future<bool> exists() async {
    return Hive.boxExists(boxName, path: path);
  }
}
