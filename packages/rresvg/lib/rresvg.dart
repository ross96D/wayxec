import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:rresvg/rresvg_isolate.dart';
import 'dart:ui' as ui;

class SvgView extends StatefulWidget {
  final String filepath;
  final bool intrinsic;
  final BoxConstraints constraints;

  const SvgView({
    super.key,
    required this.filepath,
    required this.constraints,
    this.intrinsic = false,
  });

  @override
  State<SvgView> createState() => _SvgViewState();
}

class _SvgViewState extends State<SvgView> {
  late Future<RsvgMessenger> _reSvg;

  @override
  void initState() {
    super.initState();
    _createRsvgMessenger();
  }

  void _createRsvgMessenger() {
    final completer = Completer<RsvgMessenger>();

    _reSvg = completer.future;

    RsvgIsolate().sender.then((sender) {
      final rp = ReceivePort();
      rp.listen((message) async {
        completer.complete(message as RsvgMessenger);
      });
      sender.send(Create(rp.sendPort, widget.filepath));
    });
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.filepath != oldWidget.filepath) {
      _clean();
      _createRsvgMessenger();
    }
  }

  @override
  void dispose() {
    _clean();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return FutureBuilder(
      future: _getImage(widget.constraints, devicePixelRatio),
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
  }

  Future<ui.Image?> _getImage(BoxConstraints constraints, double devicePixelRatio) async {
    final resvg = await _reSvg;
    final size = await resvg.size();
    final (width, height) = _getPhysicalSize(size, constraints, devicePixelRatio);
    if (width == 0 || height == 0) {
      throw AssertionError("invalid image size width: $width height: $height");
    }
    return await resvg.render(width, height);
  }

  void _clean() {
    _reSvg.then((v) => v.destroy());
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
