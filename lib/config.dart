import 'dart:io';

import 'package:config/config.dart';

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

  Configuration({double opacity = 1}) : _opacity = opacity;

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
            errors.add(error);
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
  fatal,
  warn,
  none;

  bool operator <=(Gravity other) => compareTo(other) <= 0;
  bool operator >=(Gravity other) => compareTo(other) >= 0;
  bool operator <(Gravity other) => compareTo(other) < 0;
  bool operator >(Gravity other) => compareTo(other) > 0;

  int compareTo(Gravity other) {
    if (other == this) {
      return 0;
    }
    if (this == fatal) {
      return 1;
    }
    if (this == none) {
      return -1;
    }
    if (other == none) {
      return -1;
    }
    return 1;
  }
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

  @override
  String toString() {
    return "ReadConfigErrors:\n${errors.join("\n")}";
  }
}

sealed class ReadConfigError {
  final Gravity gravity;

  const ReadConfigError(this.gravity);
}

class MissingKeyError extends ReadConfigError {
  final String key;

  const MissingKeyError(this.key) : super(Gravity.warn);
}

class ValueNotUsed extends ReadConfigError {
  final String key;

  const ValueNotUsed(this.key) : super(Gravity.none);
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

  final (values, errors) = ConfigurationParser.parseFromFile(file);
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
