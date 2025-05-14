
import 'dart:io';

import 'package:flutter/material.dart';
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

Image? getIcon(String? filepath) {
  // TODO cache 
  if (filepath == null) {
    return null;
  }
  if (!path.isAbsolute(filepath)) {
    return null;
  } else {
    final file = File(filepath);
    if (!file.existsSync()) {
      return null;
    }
    return Image.file(file, width: 25, height: 25);
  }
}