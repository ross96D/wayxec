import 'dart:io';

import 'package:flutter_gtk_shell_layer_test/utils.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart' as fde;
import 'package:path/path.dart' as path;
import 'package:icon_lookup/icon_lookup.dart' as icon_lookup;
import 'package:json_annotation/json_annotation.dart';
part 'search_desktop.g.dart';

typedef Key = fde.DesktopEntryKey;

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

// Iterable<Application> loadApplications() sync* {
//   for (final dirPath in getApplicationDirectories()) {
//     final dir = Directory(dirPath);
//     if (!dir.existsSync()) {
//       continue;
//     }
//     for (final entry in dir.listSync()) {
//       if (entry is File) {
//         final result = Application.parseFromFile(entry);
//         if (result.isSuccess()) {
//           final app =  result.unsafeGetSuccess();
//           if (app.icon != null) {
//             app.iconPath = searchIcon(app.icon!);
//           }
//           yield app;
//         }
//       }
//     }
//   }
// }

@JsonSerializable()
class Application {
  Map<String, dynamic> toJson() => _$ApplicationToJson(this);
  factory Application.fromJson(Map<String, dynamic> json) => _$ApplicationFromJson(json);

  /// Application name
  final String name;

  /// Additional information about the application that the desktop file entry may provide
  final String? comment;

  /// Icon to display on the ListTile widget. If the value is an absolute path,
  /// the given file will be used. If the value is not an absolute path,
  /// the algorithm described in the
  /// [Icon Theme Specification](https://specifications.freedesktop.org/icon-theme-spec/latest/)
  /// will be used to locate the icon
  final String? icon;
  String? iconPath;

  /// A list of strings identifying the desktop environments that
  /// should display/not display a given desktop entry.
  final List<String>? onlyShownIn;

  /// A list of strings identifying the desktop environments that
  /// should display/not display a given desktop entry.
  final List<String>? notShownIn;

  /// A boolean value specifying if D-Bus activation is supported for this application.
  /// If this key is missing, the default value is false.
  /// If the value is true then implementations should ignore the Exec key
  /// and send a D-Bus message to launch the application.
  /// See D-Bus Activation for more information on how this works.
  /// Applications should still include Exec= lines in their desktop files
  /// for compatibility with implementations that do not understand the DBusActivatable key.
  final bool dBusActivatable;

  /// Path to an executable file on disk used to determine if the program is actually installed.
  /// If the path is not an absolute path, the file is looked up in the $PATH environment variable.
  /// If the file is not present or if it is not executable,
  /// the entry may be ignored (not be used in menus, for example).
  final String? tryExec;

  /// Program to execute, possibly with arguments.
  /// See the [Exec key](https://specifications.freedesktop.org/desktop-entry-spec/latest/exec-variables.html)
  /// for details on how this key works.
  /// The Exec key is required if DBusActivatable is not set to true.
  final String? exec;

  /// Whether the program runs in a terminal window.
  final bool terminal;

  /// Categories in which the application place. Possible values are:
  /// AudioVideo, Audio, Video, Development, Education, Game, Graphics, Network
  /// Office, Science, Settings, System, Utility
  ///
  /// More details on: https://specifications.freedesktop.org/menu-spec/latest/category-registry.html
  final List<Categories>? categories;

  /// A list of strings which may be used in addition to other metadata to describe this entry.
  final List<String>? keywords;

  /// Last date the file was modified, used for caching
  final DateTime lastModified;
  /// Desktop entry absolute filepath
  final String filepath;

  Application({
    required this.name,
    this.exec,
    this.tryExec,
    this.comment,
    this.icon,
    this.categories,
    this.dBusActivatable = false,
    this.terminal = false,
    this.onlyShownIn,
    this.notShownIn,
    this.keywords,
    required this.lastModified,
    required this.filepath,
  });

  static Result<Application, ParseApplicationError> _getAppFromEntries(
    Map<String, String> entries,
    File file,
  ) {
    if (entries[Key.dBusActivatable.string] == null && entries[Key.exec.string] == null) {
      return Result.error(
        const DesktopEntryInvalidState(InvalidStateEnum.missingExecAndDBusActivatable),
      );
    }

    final name = entries[Key.name.string];
    if (name == null) {
      return Result.error(const DesktopEntryInvalidState(InvalidStateEnum.missingName));
    }

    final hidden = entries[Key.hidden.string];
    if (hidden?.toLowerCase() == "true") {
      return Result.error(const DesktopEntryInvalidState(InvalidStateEnum.hidden));
    }
    final noDisplay = entries[Key.noDisplay.string];
    if (noDisplay?.toLowerCase() == "true") {
      return Result.error(const DesktopEntryInvalidState(InvalidStateEnum.hidden));
    }

    final categories = Categories.fromList(entries[Key.categories.string]?.split(";"));
    final keywords = entries[Key.categories.string]?.split(";");
    return Result.success(Application(
      name: name,
      exec: entries[Key.exec.string],
      tryExec: entries[Key.tryExec.string],
      comment: entries[Key.comment.string],
      icon: entries[Key.icon.string],
      dBusActivatable: entries[Key.dBusActivatable.string]?.toLowerCase() == "true",
      terminal: entries[Key.terminal.string]?.toLowerCase() == "true",
      categories: categories?.toList(growable: false),
      keywords: keywords,
      notShownIn: entries["NotShowIn"]?.split(";"),
      onlyShownIn: entries["OnlyShownIn"]?.split(";"),
      lastModified: file.statSync().modified,
      filepath: file.absolute.path,
    ));
  }

  static Result<Application, ParseApplicationError> parseFromFile(File file) {
    String contents;
    try {
      contents = file.readAsStringSync();
    } on FileSystemException catch (e) {
      return Result.error(FileSystemError(e));
    }

    final desktopEntry = fde.DesktopEntry.parse(contents);
    final local = localization();

    if (local != null) {
      final (lang, country) = local;
      final desktopEntryL = desktopEntry.localize(lang: lang, country: country);

      return _getAppFromEntries(desktopEntryL.entries, file);
    }

    final data = desktopEntry.entries.map((key, value) => MapEntry(key, value.value));
    return _getAppFromEntries(data, file);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Application) {
      return false;
    }
    return other.filepath == filepath;
  }
  
  @override
  int get hashCode => filepath.hashCode;
}

enum Categories {
  audioVideo("AudioVideo"),
  audio("Audio"),
  video("Video"),
  development("Development"),
  education("Education"),
  game("Game"),
  graphics("Graphics"),
  network("Network"),
  office("Office"),
  science("Science"),
  settings("Settings"),
  system("System"),
  utility("Utility");

  final String value;
  const Categories(this.value);

  static Iterable<Categories>? fromList(List<String>? categoriesStr) {
    if (categoriesStr == null) {
      return null;
    }
    return categoriesStr
        .map((e) => switch (e) {
              "AudioVideo" => Categories.audioVideo,
              "Audio" => Categories.audio,
              "Video" => Categories.video,
              "Development" => Categories.development,
              "Education" => Categories.education,
              "Game" => Categories.game,
              "Graphics" => Categories.graphics,
              "Network" => Categories.network,
              "Office" => Categories.office,
              "Science" => Categories.science,
              "Settings" => Categories.settings,
              "System" => Categories.system,
              "Utility" => Categories.utility,
              String() => null,
            })
        .nonNulls;
  }
}

sealed class ParseApplicationError extends Err {
  const ParseApplicationError();
}

enum InvalidStateEnum {
  missingExecAndDBusActivatable("exec and dBusActivatable where missing"),
  missingName("name is missing"),
  hidden("application is hidden");

  final String _message;
  const InvalidStateEnum(this._message);

  @override
  String toString() {
    return _message;
  }
}

class DesktopEntryInvalidState extends ParseApplicationError {
  final InvalidStateEnum _state;
  const DesktopEntryInvalidState(this._state);

  @override
  String error() {
    return _state.toString();
  }
}

class FileSystemError extends ParseApplicationError {
  final FileSystemException err;
  const FileSystemError(this.err);

  @override
  String error() => err.toString();
}

/// cache for searchIcon
Map<String, (String?,)> _searchIconCache = {};

String? searchIcon(String iconpath) {
  if (path.isAbsolute(iconpath)) {
    return iconpath;
  }
  final cached = _searchIconCache[iconpath];
  if (cached != null) {
    return cached.$1;
  }
  final result = icon_lookup.iconLookup(iconpath);
  if (result == null) {
    _searchIconCache[iconpath] = (null,);
    return null;
  } else {
    _searchIconCache[iconpath] = (result.value,);
    return result.value;
  }
}

/// Returns all the places where icons *could* reside. These directories might
/// not actually exist.
Iterable<String> _getIconBaseDirectories() sync* {
  String? home = Platform.environment['HOME'];

  if (home != null) {
    yield path.join(home, '.icons');
  }
  yield* getDataDirectories().map((dir) => path.join(dir, 'icons'));
  yield '/usr/share/pixmaps';
}

/// Filters out filesystem entities that don't exist.
Iterable<T> whereExists<T extends FileSystemEntity>(Iterable<T> entities) sync* {
  for (T entity in entities) {
    if (entity.existsSync()) {
      yield entity;
    }
  }
}
