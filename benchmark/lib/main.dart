import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:flutter_cache_manager_hive/flutter_cache_manager_hive.dart';
import 'package:flutter_cache_manager_hive/src/hive_cache_object_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'benchmark.dart';

void main() {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  Hive.initFlutter();
  Hive.registerAdapter(HiveCacheObjectAdapter(typeId: 1));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cache Store Benchmark',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Cache Store Benchmark'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({required this.title, Key? key}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<BenchmarkResult>? _results;

  Future<void> _runBenchmark() async {
    await cleanRepo(sqflite);
    await cleanRepo(hive);

    final urls = List<String>.filled(1000, 'https://picsum.photos/200/300');
    final validTill = DateTime.now().add(const Duration(days: 30));

    final samplesSqflite = urls
        .map<CacheObject>((url) => CacheObject(url,
            relativePath: '/relative/$url', validTill: validTill))
        .toList();

    final samplesHive = urls
        .map<CacheObject>((url) => CacheObject(url,
            relativePath: '/relative/$url', validTill: validTill))
        .toList();

    final samplesMap = {'sqflite': samplesSqflite, 'hive': samplesHive};

    final opMap = {'write': opWrite, 'read': opRead, 'delete': opDelete};

    final repoMap = {'sqflite': sqflite, 'hive': hive};

    final results = <BenchmarkResult>[];
    for (final repoKey in ['sqflite', 'hive']) {
      for (final opKey in ['write', 'read', 'delete']) {
        results.add(await benchmark(repoMap[repoKey]!, samplesMap[repoKey]!,
            opMap[opKey]!, '$repoKey:$opKey'));
      }
    }

    results.forEach(print);

    setState(() {
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _results == null
          ? const Center(
              child: Text('Tap Timer to measure cache store performance'))
          : ListView.builder(
              itemCount: _results!.length,
              itemBuilder: (context, index) {
                final item = _results![index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.tag,
                            style: const TextStyle(fontSize: 18.0),
                          ),
                          Text(
                              'Operation Average: ${item.opsAvg.prettyTime()}'),
                          Text(
                              'Operation Median: ${item.opsMedian.prettyTime()}')
                        ]),
                  ),
                );
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: _runBenchmark,
        tooltip: 'Measure',
        child: const Icon(Icons.timer),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

final BenchmarkOperation opWrite = (repo, sample) async {
  await repo.updateOrInsert(sample);
};

final BenchmarkOperation opRead = (repo, sample) async {
  final cacheObject = await repo.get(sample.url);
  if (cacheObject == null) {
    throw StateError(
        'cacheObject null for url=${sample.url} for repo ${repo.runtimeType}');
  }
  if (cacheObject.url != sample.url) {
    throw StateError('url mismatch for repo ${repo.runtimeType}');
  }
};

final BenchmarkOperation opDelete = (repo, sample) async {
  await repo.delete(sample.id!);
};

final RepoMaker sqflite = () async {
  final databasesPath = await getDatabasesPath();
  try {
    await Directory(databasesPath).create(recursive: true);
  } catch (_) {}
  final path = p.join(databasesPath, 'image-cache.db');
  return CacheObjectProvider(path: path);
};

final RepoMaker hive = () async {
  final repo = HiveCacheObjectProvider('image-caching-box');
  return Future.value(repo);
};

Future<void> cleanRepo(RepoMaker r) async {
  final repository = await r.call();

  await repository.open();
  final ids =
      (await repository.getAllObjects()).map<int>((co) => co.id!).toList();
  print('Deleteing ${ids.length} items from ${repository.runtimeType}');
  await repository.deleteAll(ids);
  await repository.close();
}
