import 'package:flutter/material.dart';
import 'package:flutter_gtk_shell_layer_test/views/search.dart';
import 'package:wayland_layer_shell/types.dart';
import 'package:wayland_layer_shell/wayland_layer_shell.dart' as wl_shell;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final shell = wl_shell.WaylandLayerShell();
  final isSupported = await shell.initialize(400, 400);
  if (!isSupported) {
    throw StateError("Unsupported layer shell protocol");
  }
  await shell.setLayer(ShellLayer.layerTop);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(child: SearchApplication(key: GlobalKey())),
      ),
    );
  }
}

