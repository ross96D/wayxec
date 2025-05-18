import 'dart:io';

import 'package:flutter_gtk_shell_layer_test/db/isolate_manager.dart';
import 'package:flutter_gtk_shell_layer_test/search_desktop.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart' as path;

final _dataHome =
    Platform.environment['XDG_DATA_HOME'] ?? expandEnvironmentVariables(r'$HOME/.local/share');
final _apppath = path.join(_dataHome, "myapplauncher.db");
final database = MDatabase.open(_apppath);

class MDatabase {
  Database db;
  StoreRef<String, Map<String, Object?>> store;

  MDatabase._(this.db, this.store);

  static Future<MDatabase> open(String path) async {
    final db = await databaseFactoryIo.openDatabase(path);
    return MDatabase._(db, stringMapStoreFactory.store());
  }

  Future<List<Application>> getAll() async {
    final query = await store.find(db, finder: Finder());
    return query.map((e) => Application.fromJson(e.value)).toList();
  }

  Future<void> clean() async {
    await store.delete(db, finder: Finder());
  }

  Future<void> upsert(Application app) async {
    await store.record(app.name).put(db, app.toJson());
  }

  Future<void> saveAll(List<Application> apps) async {
    store.addAll(db, apps.map((e) => e.toJson()).toList());
    await store.records(apps.map((e) => e.name)).put(db, apps.map((e) => e.toJson()).toList());
  }
}

/// File implementing the https://specifications.freedesktop.org/menu-spec for an app launcher
///
/// applications location: $XDG_DATA_DIRS/applications/ ($XDG_DATA_DIRS is an array of directories)

Iterable<String> getApplicationDirectories() =>
    getDataDirectories().map((dir) => path.join(dir, 'applications'));

Iterable<String> getDataDirectories() sync* {
  yield Platform.environment['XDG_DATA_HOME'] ?? expandEnvironmentVariables(r'$HOME/.local/share');
  yield* (Platform.environment['XDG_DATA_DIRS'] ?? '/usr/local/share:/usr/share').split(':');
}

final unescapedVariables = RegExp(r'(?<!\\)\$([a-zA-Z_]+[a-zA-Z0-9_]*)');

String expandEnvironmentVariables(String path) {
  return path.replaceAllMapped(unescapedVariables, (Match match) {
    String env = match[1]!;
    return Platform.environment[env] ?? '';
  });
}

Future<List<Application>> loadApplicationsFromDisk(Map<String, Application> old) async {
  final response = <Application>{};
  final futures = <Future>[];
  final managerSearchIcon = IsolateManager(searchIcon);
  await managerSearchIcon.init();

  for (final dirPath in getApplicationDirectories()) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      continue;
    }
    for (final entry in dir.listSync(followLinks: true, recursive: true)) {
      if (entry is File) {
        final oldApp = old[entry.absolute.path];

        /// if in cache check for lastModified. If lastModified is equal to file is a cache hit
        if (oldApp != null) {
          final oldLastModified = oldApp.lastModified;
          if (oldLastModified == (entry.statSync().modified)) {
            // in case of two apps having the same name, the freedesktop spec says the first one
            // is the valid one
            if (response.contains(oldApp)) {
              continue;
            }
            response.add(oldApp);
            continue;
          }
        }

        final result = Application.parseFromFile(entry);
        if (result.isSuccess()) {
          final app = result.unsafeGetSuccess();
          // in case of two apps having the same name, the freedesktop spec says the first one
          // is the valid one
          if (response.contains(app)) {
            continue;
          }
          if (app.icon != null) {
            futures.add(
              managerSearchIcon.run(app.icon!).then((value) => app.iconPath = value),
            );
          }
          response.add(app);
        }
      }
    }
  }
  await Future.wait(futures);
  return response.toList();
}

Future<List<Application>> loadApplications(MDatabase db) async {
  var list = await db.getAll();
  if (list.isEmpty) {
    list = await loadApplicationsFromDisk({});
    db.saveAll(list);
    return list;
  }
  final map = Map.fromEntries(list.map((e) => MapEntry(e.filepath, e)));
  final apps = await loadApplicationsFromDisk(map);
  for (final app in apps) {
    final old = map[app.filepath];
    if (old != null && old.lastModified == app.lastModified) {
      continue;
    }
    db.upsert(app);
  }
  return apps;
}
