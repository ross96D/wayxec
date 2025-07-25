import 'dart:io';

import 'package:config/config.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/web.dart';

ValidatorResult<double> _opacity(double value) {
  if (value > 1 || value < 0) {
    return ValidatorError(RangeValidationError<double>(start: 0, end: 1, actual: value));
  }
  return ValidatorSuccess();
}

ValidatorResult<int> _heightWidth(int value) {
  if (value < 200) {
    return ValidatorError(RangeValidationError<int>(start: 200, end: -1 >>> 1, actual: value));
  }
  return ValidatorSuccess();
}

(Configuration, ReadConfigErrors?) parseConfigFromString(String content, [String filepath = ""]) {
  final schema = Schema(
    fields: [
      const DoubleNumberField("opacity", defaultTo: 1, validator: _opacity),
      const IntegerNumberField("width", defaultTo: 400, validator: _heightWidth),
      const IntegerNumberField("height", defaultTo: 400, validator: _heightWidth),
      const BooleanField("show_scroll_bar", defaultTo: true),
      const EnumField(
        "logging_level",
        Level.values,
        defaultTo: kReleaseMode ? Level.info : Level.debug,
      ),
    ],
  );

  final result = ConfigurationParser().parseFromString(content, schema: schema, filepath: filepath);

  switch (result) {
    case EvaluationParseError error:
      return (Configuration(), ReadConfigErrors(error.errors.map((e) => ConfigurationParseError(e)).toList()));
    case EvaluationValidationError result:
      final values = result.values;
      final config = Configuration(
        opacity: values["opacity"] as double?,
        width: values["width"] as double?,
        height: values["height"] as double?,
        showScrollBar: values["show_scroll_bar"] as bool?,
        logLevel: values["logging_level"] as Level?,
      );
      return (config, ReadConfigErrors(result.errors.map((e) => ConfigEvaluationError(e)).toList()));
    case EvaluationSuccess data:
      final values = data.values;
      final config = Configuration(
        opacity: values["opacity"] as double,
        width: values["width"] as double,
        height: values["height"] as double,
        showScrollBar: values["show_scroll_bar"] as bool,
        logLevel: values["logging_level"] as Level,
      );
      return (config, null);
  }
}

(Configuration, ReadConfigErrors?) parseConfig(File file) {
  String content;
  try {
    content = file.readAsStringSync();
  } on PathNotFoundException catch (e) {
    return (Configuration(), ReadConfigErrors([ConfigurationFileNotFoundError(e.path ?? file.path)]));
  }
  return parseConfigFromString(content, file.path);
}

final class Configuration {
  final double opacity;
  final double width;
  final double height;
  final Level logLevel;
  final bool showScrollBar;

  Configuration({
    double? opacity,
    double? width,
    double? height,
    bool? showScrollBar,
    Level? logLevel,
  }) : opacity = opacity ?? 1,
       width = width ?? 400,
       height = height ?? 400,
       showScrollBar = showScrollBar ?? true,
       logLevel = logLevel ?? (kReleaseMode ? Level.info : Level.debug);

  @override
  bool operator ==(covariant Configuration other) {
    return opacity == other.opacity &&
        width == other.width &&
        height == other.height &&
        logLevel == other.logLevel &&
        showScrollBar == other.showScrollBar;
  }

  @override
  int get hashCode => Object.hashAll([opacity, width, height, logLevel, showScrollBar]);

  @override
  String toString() {
    return "Configuration { opacity: $opacity, width: $width, heigth: $height, logLevel: $logLevel, showScrollBar: $showScrollBar }";
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

class ConfigEvaluationError extends ReadConfigError {
  final EvaluationError error;

  ConfigEvaluationError(this.error)
    : super(switch (error) {
        KeyNotInSchemaError() => Gravity.warn,
        _ => Gravity.fatal,
      });

  @override
  String toString() {
    return error.error();
  }
}

class ConfigurationFileNotFoundError extends ReadConfigError {
  final String path;

  ConfigurationFileNotFoundError(this.path) : super(Gravity.warn);

  @override
  String toString() {
    return "Configuration file not found in $path";
  }
}

class RangeValidationError<T extends Comparable> extends ValidationError {
  final T start;
  final T end;
  final T actual;

  RangeValidationError({required this.start, required this.end, required this.actual});

  @override
  String toString() {
    return "Range validation error. Expected to be between $start and $end but got $actual";
  }

  @override
  String error() {
    return toString();
  }
}

class ExepectedValidationError extends ValidationError {
  final List<String> expected;
  final String got;

  ExepectedValidationError(this.got, this.expected);

  @override
  String toString() {
    return "Expected value in ${expected.join(', ')} but got $got";
  }

  @override
  String error() {
    return toString();
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
