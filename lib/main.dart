import 'dart:async';

import 'package:args/args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wayxec/db/db.dart';
import 'package:wayxec/search_desktop.dart';
import 'package:wayxec/views/search.dart';
import 'package:wayland_layer_shell/types.dart';
import 'package:wayland_layer_shell/wayland_layer_shell.dart' as wl_shell;

late Future<List<Application>> apps;

bool firstBuild = true;

void main(List<String> args) async {
  apps = loadApplications(await database);

  final cliparser = ArgParser()
    ..addFlag("normal-window",
        help: "run as a normal window instead of using the layer shell protocol");
  final results = cliparser.parse(args);
  final normalWindow = results["normal-window"] as bool?;

  WidgetsFlutterBinding.ensureInitialized();
  final shell = wl_shell.WaylandLayerShell();

  if (normalWindow != null && normalWindow) {
    await shell.setUnresizable();
    await shell.showWindow((400, 400));
  } else {
    final isSupported = await shell.initialize(400, 400);
    if (isSupported) {
      await shell.setLayer(ShellLayer.layerTop);
      await switch (kDebugMode) {
        true => shell.setKeyboardMode(ShellKeyboardMode.keyboardModeOnDemand),
        false => shell.setKeyboardMode(ShellKeyboardMode.keyboardModeExclusive),
      };
      await shell.setNamesapce("wayxec");
    } else {
      await shell.showWindow((400, 400));
      await shell.setUnresizable();
    }
  }
  runApp(const MyApp());
}

// Custom Intent for exiting the app
class ExitIntent extends Intent {
  const ExitIntent();
}

// Custom Action that handles the ExitIntent
class ExitAction extends Action<ExitIntent> {
  @override
  void invoke(covariant ExitIntent intent) {
    SystemNavigator.pop(); // Close the application
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple)
        .copyWith(surface: Colors.transparent, background: Colors.transparent);
    final colorSchemeDark = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ).copyWith(surface: Colors.transparent, background: Colors.transparent);

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: colorSchemeDark,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      shortcuts: <ShortcutActivator, Intent>{
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.escape): const ExitIntent()
      },
      actions: {
        ...WidgetsApp.defaultActions,
        ExitIntent: ExitAction(),
      },
      home: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Scaffold(
          body: Center(
            child: FutureBuilder(
              future: apps,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SearchApplication(apps: snapshot.data!);
                } else {
                  return const SizedBox(
                    height: 35,
                    width: 35,
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
