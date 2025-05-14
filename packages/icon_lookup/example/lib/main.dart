import 'dart:io';

import 'package:flutter/material.dart';

import 'package:icon_lookup/icon_lookup.dart' as icon_lookup;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int sumResult;
  late icon_lookup.NativeString icon;

  @override
  void initState() {
    super.initState();
    sumResult = icon_lookup.sum(1, 2);
    icon = icon_lookup.iconLookup("firefox")!;
  }

  @override
  void dispose() {
    icon_lookup.freeIconLookupResult(icon);
    super.dispose();
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
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'sum(1, 2) = $sumResult',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Image.file(File(icon.value)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
