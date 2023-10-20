library flutter_cache_manager_hive;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'hive_cache_object_provider.dart';

class HiveCacheManager extends CacheManager {
  static const key = 'libCachedImageDataHive';

  static final Map<int, HiveCacheManager> _instances = {};

  factory HiveCacheManager({
    required String boxName,
    String? boxPath,
    int maxSize = 200,
    Duration maxAge = const Duration(days: 30),
  }) {
    final k = boxName.hashCode + boxPath.hashCode;
    if (!_instances.containsKey(k)) {
      _instances[k] = HiveCacheManager._(
        Config(
          key,
          stalePeriod: maxAge,
          maxNrOfCacheObjects: maxSize,
          repo: HiveCacheObjectProvider(boxName, path: boxPath),
        ),
      );
    }

    return _instances[k]!;
  }

  HiveCacheManager._(Config config) : super(config);
}
