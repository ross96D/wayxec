import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/services.dart';
import 'package:wayxec/utils.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart' as fde;
import 'package:path/path.dart' as path;
import 'package:icon_lookup/icon_lookup.dart' as icon_lookup;
import 'package:json_annotation/json_annotation.dart';
part 'search_desktop.g.dart';

typedef Key = fde.DesktopEntryKey;

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

  /// Times this application have been executed
  int timesExec;

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
    this.timesExec = 0,
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
  bool operator ==(covariant Application other) => other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return "Application name: $name filepath: $filepath";
  }

  Future<Result<Void, StringError>> run() async {
    if (dBusActivatable) {
      String dbusname = path.basename(filepath);
      if (dbusname.endsWith(".desktop")) {
        dbusname = dbusname.substring(0, dbusname.length - ".desktop".length);
      }
      final client = DBusClient.session();
      final pathObject = DBusObjectPath("/${dbusname.replaceAll(".", "/")}");
      final remoteObject = DBusRemoteObject(client, name: dbusname, path: pathObject);
      final params = [
        DBusDict(
          DBusSignature.string,
          DBusSignature.variant,
          {
            const DBusString("desktop-startup-id"):
                DBusVariant(DBusString(Platform.environment["DESKTOP_STARTUP_ID"] ?? "")),
            const DBusString("activation-token"):
                DBusVariant(DBusString(Platform.environment["XDG_ACTIVATION_TOKEN"] ?? "")),
          },
        )
      ];
      try {
        await remoteObject.callMethod("org.freedesktop.Application", "Activate", params);
      } on DBusMethodResponseException catch (e) {
        return Result.error(StringError("dbus activation error: $e"));
      }
      await SystemNavigator.pop();
      exit(0);
    } else {
      if (exec == null) {
        const error = StringError("invalid desktop: no exec found when dBusActivable is false");
        return Result.error(error);
      }
      final (cmd, args) = parseExec(exec!);
      if (terminal) {
        // TODO increase the list of terminals to launch and also make it configurable
        await Process.start("alacritty", ["-e", cmd, ...args]);
      } else {
        await Process.start(cmd, args, mode: ProcessStartMode.detached);
      }
      await SystemNavigator.pop();
      exit(0);
    }
  }
}

enum _ParsingExecState {
  insideQuotes,
  inSpace,
  inWord,
}

(String, List<String>) parseExec(String exec) {
  assert(exec != "");
  List<String> arguments = [];

  int start = 0;
  var state = _ParsingExecState.inSpace;
  for (int i = 0; i < exec.length; i++) {
    final char = exec[i];
    switch (state) {
      case _ParsingExecState.inSpace:
        if (char == '"') {
          start = i + 1;
          state = _ParsingExecState.insideQuotes;
        } else if (isPrintableAndNotSpace(char)) {
          start = i;
          state = _ParsingExecState.inWord;
        }
      case _ParsingExecState.insideQuotes:
        // if char is quotes and the previous char is not backslash
        if (char == '"' && !(i > 0 && exec[i - 1] == "\\")) {
          if (i > start) {
            arguments.add(exec.substring(start, i));
          }
          state = _ParsingExecState.inSpace;
        }
      case _ParsingExecState.inWord:
        if (char == " ") {
          if (i > start) {
            arguments.add(exec.substring(start, i));
          }
          state = _ParsingExecState.inSpace;
        }
    }
  }
  final last = exec.substring(start, exec.length).trim();
  if (last.isNotEmpty) {
    arguments.add(last);
  }
  arguments = arguments.map((e) {
    // match %u but not %%u. This is intended because %% is escaping the %
    e = e.replaceAll(RegExp("[^%]{0,1}%[a-zA-Z]"), "");
    e = e.replaceAll("%%", "%");
    return e;
  }).toList();
  arguments = arguments.where((e) => e != "--" && e.isNotEmpty).toList();
  assert(arguments.isNotEmpty, "empty command while parsing $exec");
  if (arguments.length > 1) {
    return (arguments[0], arguments.sublist(1));
  } else {
    return (arguments[0], []);
  }
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

/// Filters out filesystem entities that don't exist.
Iterable<T> whereExists<T extends FileSystemEntity>(Iterable<T> entities) sync* {
  for (T entity in entities) {
    if (entity.existsSync()) {
      yield entity;
    }
  }
}
