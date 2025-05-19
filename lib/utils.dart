
import 'dart:io';
import 'package:path/path.dart' as path;

abstract class Err {
  const Err();
  String error();
}

class StringError extends Err {
  final String message;
  const StringError(this.message);

  @override
  String error() {
    return message;
  }
}

/// Ligthweigth class representing an empty value or void
/// but that can be used as an argument in functions
class Void {
  static const _instance = Void._internal();
  const Void._internal();

  /// Ligthweigth class representing an empty value or void
  /// but that can be used as an argument in functions
  factory Void() => _instance;
}

class Result<T extends Object, E extends Err> {
  bool _isSuccess;
  Object _value;

  Result._({required bool tag, required Object value})
      : _value = value,
        _isSuccess = tag;

  @override
  bool operator ==(Object other) {
    if (other is Result<T, E>) {
      return other._isSuccess == _isSuccess && other._value == _value;
    }
    return false;
  }

  factory Result.error(E error) {
    return Result._(tag: false, value: error);
  }

  factory Result.success(T value) {
    return Result._(tag: true, value: value);
  }

  bool isError() {
    return !_isSuccess;
  }

  bool isSuccess() {
    return _isSuccess;
  }

  T unsafeGetSuccess() {
    return _value as T;
  }

  E unsafeGetError() {
    return _value as E;
  }

  R match<R>({required R Function(T) onSuccess, required R Function(E) onError}) {
    if (_isSuccess) {
      return onSuccess(_value as T);
    } else {
      return onError(_value as E);
    }
  }

  @override
  String toString() {
    return match(
      onSuccess: (v) => "Result success $v",
      onError: (e) => "Result error $e",
    );
  }
}

(String lang, String country)? localization() {
  final localization = Platform.environment["LANG"]?.split(".")[0].split("_");
  if (localization == null || localization.length != 2) {
    return null;
  }
  return (localization[0], localization[1]);
}


Iterable<String> getPathDirectories() sync* {
  final pathenv = Platform.environment["PATH"];
  if (pathenv == null) {
    return;
  }
  yield* Platform.environment["PATH"]!.split(":");
}


/// https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
Iterable<String> getDataDirectories() sync* {
  yield Platform.environment['XDG_DATA_HOME'] ?? expandEnvironmentVariables(r'$HOME/.local/share');
  yield* (Platform.environment['XDG_DATA_DIRS'] ?? '/usr/local/share:/usr/share').split(':');
}

/// Returns all potential directories where desktop entries might reside.
/// Some directories might not exist.
Iterable<String> getApplicationDirectories() => getDataDirectories().map((dir) => path.join(dir, 'applications'));

// Only if the dollar sign does not have a backslash before it.
final unescapedVariables = RegExp(r'(?<!\\)\$([a-zA-Z_]+[a-zA-Z0-9_]*)');

/// Resolves environment variables. Replaces all $VARS with their value.
String expandEnvironmentVariables(String path) {
  return path.replaceAllMapped(unescapedVariables, (Match match) {
    String env = match[1]!;
    return Platform.environment[env] ?? '';
  });
}

bool isPrintableAndNotSpace(String char) {
  assert(char.isNotEmpty);
  assert(char.length == 1);

  final codePoint = char.codeUnitAt(0);

  // C0 controls and DEL (0x00-0x1F, 0x7F) // check for 32 because is space
  if (codePoint <= 32 || codePoint == 127) return false;

  // C1 controls (0x80-0x9F)
  if (codePoint >= 128 && codePoint <= 159) return false;

  // Dont allow space
  if (codePoint == 160) return false;

  // Additional control characters (e.g., line/paragraph separators, formatting)
  if ((codePoint >= 0x2028 && codePoint <= 0x2029) || // Line/Paragraph separators
      (codePoint >= 0x200B && codePoint <= 0x200F) || // Zero-width spaces
      (codePoint >= 0x2060 && codePoint <= 0x2064) || // Invisible formatting
      (codePoint >= 0x2066 && codePoint <= 0x2069)) { // Bidirectional controls
    return false;
  }

  return true;
}