import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'rresvg_bindings_generated.dart';
import 'dart:ffi' hide Size;
import 'package:ffi/ffi.dart' as ffi;
import 'dart:io';
import 'dart:ui' as ui;

class SvgView extends StatefulWidget {
  final String data;
  final bool intrinsic;

  const SvgView({super.key, required this.data, this.intrinsic = false});
  @override
  State<SvgView> createState() => _SvgViewState();
}

class _SvgViewState extends State<SvgView> {
  late _ReSvgSync _reSvg;

  static bool loginit = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _bindings.resvg_init_log();
    }

    _reSvg = _ReSvgSync.from(widget.data);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.data != oldWidget.data) {
      _clean();
      _reSvg = _ReSvgSync.from(widget.data);
    }
  }

  @override
  void dispose() {
    _clean();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      return FutureBuilder(
        future: _getImage(constraints, devicePixelRatio),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RawImage(
              image: snapshot.data,
              scale: devicePixelRatio,
            );
          } else {
            if (snapshot.hasError) {
              throw Error.throwWithStackTrace(snapshot.error!, snapshot.stackTrace!);
            }
            return const CircularProgressIndicator();
          }
        },
      );
    });
  }

  Future<ui.Image?> _getImage(BoxConstraints constraints, double devicePixelRatio) async {
    final size = _reSvg.size;
    print("SVG SIZE $size");
    // final (width, height) = _getPhysicalSize(size, constraints, devicePixelRatio);
    final (width, height) = (50,50);
    if (width == 0 || height == 0) {
      throw AssertionError("invalid image size width: $width height: $height");
    }
    final result = _reSvg.render(width, height);
    if (result == null) {
      return null;
    }
    final (pixels, length) = result;

    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      pixels.asTypedList(length),
      width,
      height,
      ui.PixelFormat.rgba8888,
      (image) {
        ffi.malloc.free(pixels);
        completer.complete(image);
      },
    );
    return completer.future;
  }

  void _clean() {
    _reSvg.close();
  }

  (int, int) _getPhysicalSize(Size size, BoxConstraints constraints, double devicePixelRatio) {
    final ratio = size.width / size.height;
    double logicalWidth, logicalHeight;

    if (constraints.maxWidth == double.infinity) {
      if (constraints.maxHeight == double.infinity) {
        logicalWidth = size.width;
        logicalHeight = size.height;
      } else {
        if (widget.intrinsic) {
          if (size.height > constraints.maxHeight) {
            logicalHeight = constraints.maxHeight;
            logicalWidth = logicalHeight * ratio;
          } else {
            logicalHeight = size.height;
            logicalWidth = size.width;
          }
        } else {
          logicalHeight = constraints.maxHeight;
          logicalWidth = logicalHeight * ratio;
        }
      }
    } else if (constraints.maxHeight == double.infinity) {
      if (widget.intrinsic) {
        if (size.width > constraints.maxWidth) {
          logicalWidth = constraints.maxWidth;
          logicalHeight = logicalWidth / ratio;
        } else {
          logicalWidth = size.width;
          logicalHeight = size.height;
        }
      } else {
        logicalWidth = constraints.maxWidth;
        logicalHeight = logicalWidth / ratio;
      }
    } else {
      final boxRatio = constraints.maxWidth / constraints.maxHeight;
      if (ratio > boxRatio) {
        if (widget.intrinsic) {
          if (size.width > constraints.maxWidth) {
            logicalWidth = constraints.maxWidth;
            logicalHeight = logicalWidth / ratio;
          } else {
            logicalWidth = size.width;
            logicalHeight = size.height;
          }
        } else {
          logicalWidth = constraints.maxWidth;
          logicalHeight = logicalWidth / ratio;
        }
      } else {
        if (widget.intrinsic) {
          if (size.height > constraints.maxHeight) {
            logicalHeight = constraints.maxHeight;
            logicalWidth = logicalHeight * ratio;
          } else {
            logicalHeight = size.height;
            logicalWidth = size.width;
          }
        } else {
          logicalHeight = constraints.maxHeight;
          logicalWidth = logicalHeight * ratio;
        }
      }
    }

    final physicalWidth = logicalWidth * devicePixelRatio;
    final physicalHeight = logicalHeight * devicePixelRatio;
    return (physicalWidth.round(), physicalHeight.round());
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

class _ReSvgSync {
  final Pointer<Pointer<resvg_render_tree>> _tree;
  final Size size;
  final resvg_transform _transform;
  bool _closed = false;
  _ReSvgSync._(this._tree, this.size, this._transform);

  static _ReSvgSync from(String data) {
    final str = data.toNativeUtf8();
    final options = _bindings.resvg_options_create();
    final tree = ffi.malloc<Pointer<resvg_render_tree>>();
    int res =  _bindings.resvg_parse_tree_from_file(str.cast(), options, tree);
    if (res != resvg_error.RESVG_OK) {
      print("--------------------------ZAAAAAAAAAAAAAA--------------------------");
      print("ERROR VALUE $res");
      throw AssertionError("error in resvg_parse_tree_from_data $res");
    }
    _bindings.resvg_options_destroy(options);

    final rawSize = _bindings.resvg_get_image_size(tree.value);
    final size = Size(rawSize.width, rawSize.height);
    print("SIZE in FROM w: ${rawSize.width} h: ${rawSize.height}");

    final transform = _bindings.resvg_transform_identity();

    return _ReSvgSync._(tree, size, transform);
  }

  (Pointer<Uint8>, int)? render(int width, int height) {
    if (_closed) return null;
    _transform.a = width / size.width;
    _transform.d = height / size.height;
    final length = width * height * 4;
    print("LENGHT TO MALLOC: $length");
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
