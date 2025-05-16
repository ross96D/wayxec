import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:io';
import 'package:ffi/ffi.dart' as ffi;
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:rresvg/rresvg_bindings_generated.dart';

class RsvgIsolate {
  late Future<SendPort> sender;

  static final RsvgIsolate _instance = RsvgIsolate._();
  RsvgIsolate._() {
    final receiver = ReceivePort();
    final completer = Completer<SendPort>();
    sender = completer.future;

    receiver.listen((message) {
      assert(message is SendPort);
      completer.complete(message);
    });

    completer.future.then((_) => receiver.close());

    Isolate.spawn(_createIsolate, receiver.sendPort);
  }

  factory RsvgIsolate() => _instance;

  static void _createIsolate(SendPort callerSender) {
    final receiver = ReceivePort();
    final sender = receiver.sendPort;
    callerSender.send(receiver.sendPort);

    int instanceID = minInteger;
    int createID() {
      if (instanceID == maxInteger) {
        instanceID = minInteger;
      } else {
        instanceID += 1;
      }
      return instanceID;
    }

    final instances = <int, ReSvgSync>{};

    receiver.listen((message) {
      final request = message as IsolateRequest;
      switch (request) {
        case Create():
          final id = createID();
          instances[id] = ReSvgSync.from(request.filepath);
          request.sender.send(RsvgMessenger(id, sender, request.filepath, request));

        case Destroy():
          final instance = instances[request.resvgID];
          if (instance == null) {
            request.sender.send(NullResponse(request));
            return;
          }
          instance.close();
          instances.remove(request.resvgID);
          request.sender.send(OkResponse(request));

        case Render():
          final instance = instances[request.resvgID];
          if (instance == null) {
            request.sender.send(NullResponse(request));
            return;
          }
          final result = instance.render(request.width, request.height);
          if (result == null) {
            request.sender.send(NullResponse(request));
            return;
          }
          final (pixels, length) = result;
          request.sender.send(
            RenderResponse(request, pixels.address, length, request.width, request.height),
          );

        case SizeRequest():
          final instance = instances[request.resvgID];
          if (instance == null) {
            request.sender.send(NullResponse(request));
            return;
          }
          request.sender.send(
              SizeResponse(request, width: instance.size.width, height: instance.size.height));
      }
    });
  }
}

sealed class IsolateResponse {
  final int id;
  IsolateResponse(IsolateRequest request) : id = request.id;
}

class NullResponse extends IsolateResponse {
  NullResponse(super.request);
}

class OkResponse extends IsolateResponse {
  OkResponse(super.request);
}

class SizeResponse extends IsolateResponse {
  final double width;
  final double height;

  SizeResponse(super.request, {required this.width, required this.height});
}

class RenderResponse extends IsolateResponse {
  final int pixelsAddress;
  final int length;
  final int width;
  final int height;

  RenderResponse(super.request, this.pixelsAddress, this.length, this.width, this.height);
}

class _SizeKey {
  final int width;
  final int height;
  final String filepath;
  _SizeKey(this.width, this.height, this.filepath);

  @override
  bool operator ==(Object other) {
    if (other is! _SizeKey) {
      return false;
    }
    return width == other.width && height == other.height && filepath == other.filepath;
  }

  @override
  int get hashCode => Object.hash(width, height, filepath);
}

class RsvgMessenger extends IsolateResponse {
  final int resvgID;
  final SendPort sender;
  final String filepath;

  ReceivePort? _receiver;
  ReceivePort get receiver {
    if (_receiver == null) {
      _receiver = ReceivePort();
      _receiver!.listen((m) {
        final message = m as IsolateResponse;
        _requests[message.id]?.complete(message);
      });
    }
    return _receiver!;
  }

  final Map<int, Completer<IsolateResponse>> _requests = {};

  RsvgMessenger(this.resvgID, this.sender, this.filepath, super.request);

  Future<R> _send<R extends IsolateResponse, T extends IsolateRequest>(T request) async {
    final completer = Completer<R>();
    _requests[request.id] = completer;
    sender.send(request);
    final result = await completer.future;
    _requests.remove(request.id);
    return result;
  }

  Future<Size> size() async {
    final result = await _send(SizeRequest(receiver.sendPort, resvgID));
    return switch (result) {
      SizeResponse() => Size(result.width, result.height),
      NullResponse() => throw StateError("Missing Resvg instance"),
      IsolateResponse() => throw StateError("Invalid response from isolate"),
    };
  }

  Future<void> destroy() async {
    await _send(Destroy(receiver.sendPort, resvgID));
  }

  static var _renderCache = <_SizeKey, ui.Image>{};
  Future<ui.Image?> render(int width, int height) async {
    final key = _SizeKey(width, height, filepath);
    if (_renderCache[key] != null) {
      return _renderCache[key];
    }

    final completer = Completer<ui.Image?>();
    final result = await _send(Render(receiver.sendPort, resvgID, width: width, height: height));
    switch (result) {
      case NullResponse():
        completer.complete(null);

      case RenderResponse():
        final pixels = Pointer<Uint8>.fromAddress(result.pixelsAddress);
        ui.decodeImageFromPixels(
          pixels.asTypedList(result.length),
          result.width,
          result.height,
          ui.PixelFormat.rgba8888,
          (image) {
            ffi.calloc.free(pixels);
            _renderCache[key] = image;
            return completer.complete(image);
          },
        );

      default:
        throw StateError("Invalid response from isolate");
    }
    return completer.future;
  }
}

/// especific for 64bit backed integers
const int maxInteger = 0x7FFFFFFFFFFFFFFF;
const int minInteger = -0x8000000000000000;

sealed class IsolateRequest {
  final int id;
  final SendPort sender;
  IsolateRequest(this.sender) : id = IsolateRequest.createID();

  static int _idRequest = minInteger;
  static int createID() {
    if (_idRequest == maxInteger) {
      _idRequest = minInteger;
    } else {
      _idRequest += 1;
    }
    return _idRequest;
  }
}

class Create extends IsolateRequest {
  final String filepath;
  Create(super.sender, this.filepath);
}

class Destroy extends IsolateRequest {
  final int resvgID;
  Destroy(super.sender, this.resvgID);
}

class Render extends IsolateRequest {
  final int resvgID;
  final int width;
  final int height;
  Render(super.sender, this.resvgID, {required this.width, required this.height});
}

class SizeRequest extends IsolateRequest {
  final int resvgID;
  SizeRequest(super.sender, this.resvgID);
}

class ReSvgSync {
  final Pointer<Pointer<resvg_render_tree>> _tree;
  final Size size;
  final resvg_transform _transform;
  bool _closed = false;
  ReSvgSync._(this._tree, this.size, this._transform);

  /// TODO this should return a Result type
  static ReSvgSync from(String data) {
    final str = data.toNativeUtf8();
    final options = _bindings.resvg_options_create();
    final tree = ffi.malloc<Pointer<resvg_render_tree>>();
    int res = _bindings.resvg_parse_tree_from_file(str.cast(), options, tree);
    if (res != resvg_error.RESVG_OK) {
      throw AssertionError("error in resvg_parse_tree_from_data $res");
    }
    _bindings.resvg_options_destroy(options);

    final rawSize = _bindings.resvg_get_image_size(tree.value);
    final size = Size(rawSize.width, rawSize.height);

    final transform = _bindings.resvg_transform_identity();

    return ReSvgSync._(tree, size, transform);
  }

  (Pointer<Uint8>, int)? render(int width, int height) {
    if (_closed) return null;
    _transform.a = width / size.width;
    _transform.d = height / size.height;
    final length = width * height * 4;
    final pixels = ffi.calloc<Uint8>(length);
    assert(pixels.address != 0, "malloc failed");
    _bindings.resvg_render(_tree.value, _transform, width, height, pixels.cast());

    return (pixels, length);
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _bindings.resvg_tree_destroy(_tree.value);
      ffi.malloc.free(_tree);
    }
  }
}

const String _libName = 'rresvg';

/// The dynamic library in which the symbols for [RresvgBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final RresvgBindings _bindings = RresvgBindings(_dylib);
