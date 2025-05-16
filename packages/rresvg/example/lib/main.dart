import 'package:flutter/material.dart';

import 'package:rresvg/rresvg.dart' as rresvg;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Image image;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: const Column(
              children: [
                Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                rresvg.SvgView(
                  filepath: "/usr/share/icons/hicolor/scalable/apps/btop.svg",
                  constraints: BoxConstraints.tightFor(height: 10, width: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
