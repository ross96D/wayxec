import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:rresvg/rresvg.dart';
import 'package:wayxec/search_desktop.dart';

class FutureIcon extends StatelessWidget {
  final String? filepath;

  // TODO the icon path should not be loaded here. Should be loaded at application start.
  FutureIcon(String icon) : filepath = searchIcon(icon);

  @override
  Widget build(BuildContext context) {
    if (filepath == null) {
      return const SizedBox(width: 35,);
    }
    if (path.extension(filepath!) == ".svg") {
      return SvgView(
        filepath: filepath!,
        constraints: const BoxConstraints.tightFor(height: 35, width: 35),
      );
    }
    return Image.file(File(filepath!), width: 35, height: 35);
  }
}
