import 'dart:io';

import 'package:config/config.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/web.dart';

final class _SetValuesUtility<T extends Object> {
  final String key;

  final ValidationError? Function(T)? _validator;
  ValidationError? validator(Object v) => _validator != null ? _validator!(v as T) : null;

  final void Function(T) _setter;
  void setter(Object v) => _setter(v as T);

  Type get type => T;

  _SetValuesUtility(this.key, this._setter, [this._validator]);
}

final class Configuration {
  double _opacity;
  double get opacity => _opacity;

  double _width;
  double get width => _width;

  double _height;
  double get height => _height;

  Level _logLevel;
  Level get logLevel => _logLevel;
  static const _levels = <String, Level>{
    "trace": Level.trace,
    "debug": Level.debug,
    "info": Level.info,
    "warning": Level.warning,
    "error": Level.error,
    "fatal": Level.fatal,
  };
  void _setLogLevel(String levelstr) {
    final level = _levels[levelstr.toLowerCase()];
    if (level != null) {
      _logLevel = level;
    }
  }

  ExepectedValidationError? _validateLogLevel(String levelstr) {
    final level = _levels[levelstr.toLowerCase()];
    if (level == null) {
      return ExepectedValidationError(levelstr, _levels.keys.toList());
    } else {
      return null;
    }
  }

  Configuration({double opacity = 1, double width = 400, double height = 400})
      : _opacity = opacity,
        _width = width,
        _height = height,
        _logLevel = kReleaseMode ? Level.info : Level.debug;

  List<ReadConfigError> _setValues(MapValue values) {
    final mapSetter = <_SetValuesUtility>[
      _SetValuesUtility<double>(
        "opacity",
        (v) => _opacity = v,
        (v) {
          if (v > 1 || v < 0) {
            return RangeValidationError<double>(start: 0, end: 1, actual: v);
          }
          return null;
        },
      ),
      _SetValuesUtility<double>(
        "width",
        (v) => _width = v,
        (v) {
          if (v < 200) {
            return RangeValidationError<double>(start: 200, end: double.infinity, actual: v);
          }
          return null;
        },
      ),
      _SetValuesUtility<double>(
        "height",
        (v) => _height = v,
        (v) {
          if (v < 200) {
            return RangeValidationError<double>(start: 200, end: double.infinity, actual: v);
          }
          return null;
        },
      ),
      _SetValuesUtility<String>(
        "logging_level",
        _setLogLevel,
        _validateLogLevel,
      )
    ];
    final errors = <ReadConfigError>[];

    for (final entry in mapSetter) {
      final key = entry.key;
      final type = entry.type;

      final val = values[key];
      if (val != null) {
        if (val.value.runtimeType == type) {
          final error = entry.validator(val.value);
          if (error == null) {
            entry.setter(val.value);
          } else {
            errors.add(KeyValidationError(key, error));
          }
        } else {
          errors.add(TypeError(key, type, val.value.runtimeType));
        }
      } else {
        errors.add(MissingKeyError(key));
      }
    }

    for (final key in values.value.keys) {
      bool contains = false;
      for (final e in mapSetter) {
        if (e.key == key) {
          contains = true;
          break;
        }
      }
      if (!contains) {
        errors.add(ValueNotUsed(key));
      }
    }

    return errors;
  }

  @override
  bool operator ==(covariant Configuration other) {
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
  fatal(10000),
  warn(1000),
  none(0);

  final int _val;

  const Gravity(this._val);

  bool operator <=(Gravity other) => compareTo(other) <= 0;
  bool operator >=(Gravity other) => compareTo(other) >= 0;
  bool operator <(Gravity other) => compareTo(other) < 0;
  bool operator >(Gravity other) => compareTo(other) > 0;

  int compareTo(Gravity other) => _val.compareTo(other._val);
}

class ReadConfigErrors {
  final List<ReadConfigError> errors;

  const ReadConfigErrors(this.errors);

  Gravity get gravity {
    Gravity gravity = Gravity.none;
    for (final e in errors) {
      if (e.gravity > gravity) {
        gravity = e.gravity;
      }
    }
    return gravity;
  }

  void log(Logger logger) {
    for (final error in errors) {
      switch (error.gravity) {
        case Gravity.fatal:
          logger.e("Reading configuration error: $error");
        case Gravity.warn:
          logger.w("Reading configuration error: $error");
        case Gravity.none:
          logger.i("Reading configuration error: $error");
      }
    }
  }

  @override
  String toString() {
    return "ReadConfigErrors:\n${errors.join("\n")}";
  }
}

sealed class ReadConfigError {
  final Gravity gravity;

  const ReadConfigError(this.gravity);
}

class ConfigurationFileNotFoundError extends ReadConfigError {
  final String path;

  ConfigurationFileNotFoundError(this.path) : super(Gravity.warn);

  @override
  String toString() {
    return "Configuration file not found in $path";
  }
}

class MissingKeyError extends ReadConfigError {
  final String key;
  final bool required;

  const MissingKeyError(this.key, [this.required = false])
      : super(required ? Gravity.fatal : Gravity.warn);

  @override
  String toString() {
    return "Missing ${required ? 'required ' : ''}key $key";
  }
}

class ValueNotUsed extends ReadConfigError {
  final String key;

  const ValueNotUsed(this.key) : super(Gravity.none);

  @override
  String toString() {
    return "$key was found in the configuration but his value is not used";
  }
}

class TypeError extends ReadConfigError {
  final String key;
  final Type expectedType;
  final Type gotType;

  const TypeError(this.key, this.expectedType, this.gotType) : super(Gravity.warn);
}

sealed class ValidationError extends ReadConfigError {
  const ValidationError() : super(Gravity.warn);
}

class KeyValidationError extends ValidationError {
  final ValidationError error;
  final String key;

  const KeyValidationError(this.key, this.error);

  @override
  String toString() {
    return "Key $key validation error: $error";
  }
}

class RangeValidationError<T extends Comparable> extends ValidationError {
  final T start;
  final T end;
  final T actual;

  const RangeValidationError({required this.start, required this.end, required this.actual});

  @override
  String toString() {
    return "Range validation error. Expected to be between $start and $end but got $actual";
  }
}

class ExepectedValidationError extends ValidationError {
  final List<String> expected;
  final String got;

  const ExepectedValidationError(this.got, this.expected);

  @override
  String toString() {
    return "Expected value in ${expected.join(', ')} but got $got";
  }
}

class ConfigurationParseError extends ReadConfigError {
  final ParseError error;

  const ConfigurationParseError(this.error) : super(Gravity.fatal);

  @override
  String toString() {
    return "Configuration parsing $error";
  }
}

(Configuration, ReadConfigErrors?) parseConfig(File file) {
  final config = Configuration();

  MapValue? values;
  List<ParseError>? errors;
  try {
    (values, errors) = ConfigurationParser.parseFromFile(file);
  } on PathNotFoundException catch (e) {
    return (config, ReadConfigErrors([ConfigurationFileNotFoundError(e.path ?? file.path)]));
  }

  if (errors != null) {
    assert(errors.isNotEmpty);
    return (config, ReadConfigErrors(errors.map((e) => ConfigurationParseError(e)).toList()));
  }
  assert(values != null);
  final setErrors = config._setValues(values!);
  return (
    config,
    setErrors.isNotEmpty ? ReadConfigErrors(setErrors) : null,
  );
}

(Configuration, ReadConfigErrors?) parseConfigFromString(String content) {
  final config = Configuration();

  final (values, errors) = ConfigurationParser.parseFromString(content);
  if (errors != null) {
    assert(errors.isNotEmpty);
    return (config, ReadConfigErrors(errors.map((e) => ConfigurationParseError(e)).toList()));
  }
  assert(values != null);
  final setErrors = config._setValues(values!);
  return (
    config,
    setErrors.isNotEmpty ? ReadConfigErrors(setErrors) : null,
  );
}
