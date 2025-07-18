import 'dart:io';

import 'package:config/config.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/web.dart';

const _levels = <String, Level>{
  "trace": Level.trace,
  "debug": Level.debug,
  "info": Level.info,
  "warning": Level.warning,
  "error": Level.error,
  "fatal": Level.fatal,
};

ExepectedValidationError? _validateLogLevel(String levelstr) {
  final level = _levels[levelstr.toLowerCase()];
  if (level == null) {
    return ExepectedValidationError(levelstr, _levels.keys.toList());
  } else {
    return null;
  }
}

RangeValidationError? _validateOpacity(double value) {
  if (value > 1 || value < 0) {
    return RangeValidationError<double>(start: 0, end: 1, actual: value);
  }
  return null;
}

RangeValidationError? _validateHeightWidth(double value) {
  if (value < 200) {
    return RangeValidationError<double>(start: 200, end: double.infinity, actual: value);
  }
  return null;
}

(Configuration, ReadConfigErrors?) parseConfigFromString(String content, [String filepath = ""]) {
  final schema = Schema()
    ..field<double>("opacity", defaultsTo: 1, validator: _validateOpacity)
    ..field<double>("width", defaultsTo: 400, validator: _validateHeightWidth)
    ..field<double>("height", defaultsTo: 400, validator: _validateHeightWidth)
    ..field<bool>("show_scroll_bar", defaultsTo: true)
    ..field<String>("logging_level", validator: _validateLogLevel, defaultsTo: kReleaseMode ? "info" : "debug");

  // try {
  final (result, errors) = ConfigurationParser.parseFromString(content, schema: schema, filepath: filepath);
  // } on PathNotFoundException catch (e) {
  //   return (Configuration(), ReadConfigErrors([ConfigurationFileNotFoundError(e.path ?? file.path)]));
  // }

  if (errors != null) {
    assert(errors.isNotEmpty);
    return (Configuration(), ReadConfigErrors(errors.map((e) => ConfigurationParseError(e)).toList()));
  }
  assert(result != null);

  final values = result!.values;
  final config = Configuration(
    opacity: values["opacity"]?.value as double?,
    width: values["width"]?.value as double?,
    height: values["height"]?.value as double?,
    showScrollBar: values["show_scroll_bar"]?.value as bool?,
    logLevel: values["logging_level"] != null ? _levels[values["logging_level"]!.value as String] : null,
  );

  if (result.errors.isNotEmpty) {
    return (config, ReadConfigErrors(result.errors.map((e) => ConfigEvaluationError(e)).toList()));
  } else {
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

  const RangeValidationError({required this.start, required this.end, required this.actual});

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

  const ExepectedValidationError(this.got, this.expected);

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
