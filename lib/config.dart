import 'package:wayxec/utils.dart';

final class Configuration {
  double _opacity;
  double get opacity => _opacity;

  Configuration({double opacity = 1}) : _opacity = opacity;

  Result<Void, KeyValueParsingError> _set(String key, String value, int lineNumber) {
    assert(!key.startsWith(" "));
    return switch (key) {
      "opacity" => _parseOpacity(value, lineNumber, 0).match(
          onSuccess: (v) {
            _opacity = v;
            return Result.success(Void());
          },
          onError: (e) => Result.error(e),
        ),
      String() => Result.error(KeyNotFound(lineNumber, key)),
    };
  }

  static Result<double, ValueParsingError> _parseOpacity(String value, int lineNumber, int offset) {
    try {
      final r = double.parse(value);
      if (r < 0 || r > 1) {
        return Result.error(ValueParsingError(
          lineNumber: lineNumber,
          offset: offset,
          message: "invalid opacity value $r expected to be between 0 and 1",
        ));
      }
      return Result.success(r);
    } on FormatException catch (e) {
      return Result.error(ValueParsingError(
        message: e.message,
        lineNumber: lineNumber,
        offset: offset + (e.offset ?? 0),
      ));
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is! Configuration) {
      return false;
    }
    return _opacity == other._opacity;
  }

  @override
  int get hashCode => _opacity.hashCode;

  @override
  String toString() {
    return "Configuration { opacity: $_opacity }";
  }
}

enum Gravity {
  fatal,
  warn,
  none,
}

final class ConfigurationParsingErrorList extends Err {
  final List<ConfigurationParsingError> errors;

  const ConfigurationParsingErrorList(this.errors);

  Gravity get gravity {
    if (errors.isEmpty) {
      return Gravity.none;
    }
    for (final e in errors) {
      if (e.gravity == Gravity.fatal) {
        return Gravity.fatal;
      }
    }
    return Gravity.warn;
  }

  @override
  String error() {
    final buffer = StringBuffer();
    for (final e in errors) {
      buffer.write(e.error());
      buffer.write("\n");
    }
    return buffer.toString();
  }
}

sealed class ConfigurationParsingError extends Err {
  final Gravity gravity;
  ConfigurationParsingError([this.gravity = Gravity.fatal]);
}

sealed class KeyValueParsingError extends ConfigurationParsingError {
  KeyValueParsingError([super.gravity]);
}

class KeyNotFound extends KeyValueParsingError {
  final String key;
  final int lineNumber;
  KeyNotFound(this.lineNumber, this.key) : super(Gravity.warn);

  @override
  String error() => "Key $key not found";
}

class ValueParsingError extends KeyValueParsingError {
  final int lineNumber;
  final int offset;
  String message;

  ValueParsingError({
    required this.message,
    required this.offset,
    required this.lineNumber,
    Gravity gravity = Gravity.fatal,
  }) : super(gravity);

  @override
  String error() {
    return "$lineNumber:$offset $message";
  }
}

sealed class LineParsingError extends ConfigurationParsingError {
  final int lineNumber;
  LineParsingError(this.lineNumber, [super.gravity]);
}

class NoEqualFoundError extends LineParsingError {
  NoEqualFoundError(super.lineNumber, [super.gravity]);

  @override
  String error() => "no equal found in line $lineNumber";
}

class EmptyKey extends LineParsingError {
  EmptyKey(super.lineNumber, [super.gravity]);

  @override
  String error() => "empty key in line $lineNumber";
}

class EmptyValue extends LineParsingError {
  EmptyValue(super.lineNumber, [super.gravity]);

  @override
  String error() => "empty value in line $lineNumber";
}

(Configuration, ConfigurationParsingErrorList) parseConfig(String configuration) {
  final lines = configuration.split("\n");

  Configuration response = Configuration();
  List<ConfigurationParsingError> errors = [];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line == "") {
      continue;
    }
    split(line, i + 1).match(
      onSuccess: (v) => response._set(v.$1, v.$2, i + 1).match(
            onSuccess: (v) => {},
            onError: (e) => errors.add(e),
          ),
      onError: (e) => errors.add(e),
    );
  }

  return (response, ConfigurationParsingErrorList(errors));
}


Result<(String, String), ConfigurationParsingError> split(String line, int lineNumber) {
  final index = line.indexOf("=");
  if (index == -1) {
    return Result.error(NoEqualFoundError(lineNumber, Gravity.warn));
  }
  if (index == 0) {
    return Result.error(EmptyKey(lineNumber, Gravity.warn));
  }
  if (index == line.length - 1) {
    return Result.error(EmptyValue(lineNumber, Gravity.warn));
  }
  final (key, value) = (line.substring(0, index), line.substring(index + 1));
  return Result.success((key.trim(), value.trim()));
}
