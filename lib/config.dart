import 'dart:io';

import 'package:config/config.dart';
import 'package:wayxec/utils.dart';

final class Configuration {
  double _opacity;
  double get opacity => _opacity;

  Configuration({double opacity = 1}) : _opacity = opacity;

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
}

class ReadConfigError {
  final Gravity gravity;
  final String message;

  const ReadConfigError(this.gravity, this.message);
}

(Configuration, ReadConfigErrors?) parseConfig(File file) {
  final config = Configuration();

  final (values, errors) = ConfigurationParser.parseFromFile(file);
  if (errors != null) {
    return (
      config,
      ReadConfigErrors(errors.map((e) => ReadConfigError(Gravity.fatal, e.toString())).toList())
    );
  }
}
