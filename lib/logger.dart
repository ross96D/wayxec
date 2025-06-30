import 'dart:convert';
import 'package:chalkdart/chalkdart.dart';
import 'package:flutter/foundation.dart';

import 'package:logger/logger.dart' hide PrettyPrinter;

Logger? _logger;
Filter? _filter;

Logger get logger {
  assert(_logger != null, "you forgot to initialize logger");
  return _logger!;
}

void initLogger({
  Level minLevel = kReleaseMode ? Level.all : Level.debug,
  LogOutput? output,
}) {
  output ??= ConsoleOutput();
  _filter = Filter(level: minLevel);
  final log = Logger(
    filter: _filter,
    output: ConsoleOutput(),
    printer: PrettyPrinter(),
  );
  _logger = log;
}

void setLogLevel(Level level) {
  _filter!.level = level;
}

class Filter extends LogFilter {
  Filter({Level? level}) {
    super.level = level;
  }
  @override
  bool shouldLog(LogEvent event) {
    return (level ?? Level.all).value <= event.level.value;
  }
}

class PrettyPrinter extends LogPrinter {
  final bool printTime;
  final DateTimeFormatter dateTimeFormat;

  PrettyPrinter({this.printTime = true, this.dateTimeFormat = DateTimeFormat.dateAndTime});

  @override
  List<String> log(LogEvent event) {
    String messageStr = _stringifyMessage(event.message);

    final errorStr = event.error?.toString();

    String? timeStr = switch (printTime) {
      true => dateTimeFormat(event.time),
      false => null,
    };

    String response = "";
    if (timeStr != null) {
      response += chalk.magenta(timeStr);
    }
    response += " ${_formatLevel(event.level)}";
    response = "$response $messageStr";
    if (errorStr != null) {
      response += " $errorStr";
    }

    return [response.replaceAll("\n", "\\n")];
  }

  String _formatLevel(Level level) {
    return switch (level) {
      Level.trace => chalk.blueBright("trace"),
      Level.debug => chalk.blue("debug"),
      Level.info => chalk.green("info"),
      Level.warning => chalk.orange("warning"),
      Level.error => chalk.red("error"),
      Level.fatal => chalk.redBright("fatal"),
      Level.off => throw StateError("log level cannot be off"),
      Level.all => throw StateError("log level cannot be all"),
      Level.verbose => throw StateError("deprecated level"),
      Level.wtf => throw StateError("deprecated level"),
      Level.nothing => throw StateError("deprecated level"),
    };
  }

  static String _stringifyMessage(dynamic message) {
    final finalMessage = message is Function ? message() : message;
    if (finalMessage is Map || finalMessage is Iterable) {
      var encoder = JsonEncoder.withIndent('  ', _toEncodableFallback);
      return encoder.convert(finalMessage);
    } else {
      return finalMessage.toString();
    }
  }

  static Object _toEncodableFallback(dynamic object) {
    return object.toString();
  }
}
