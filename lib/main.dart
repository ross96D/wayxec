import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:wayxec/config.dart';
import 'package:wayxec/db/db.dart';
import 'package:wayxec/logger.dart';
import 'package:wayxec/search_desktop.dart';
import 'package:wayxec/utils.dart';
import 'package:wayxec/views/search.dart';
import 'package:wayland_layer_shell/types.dart';
import 'package:wayland_layer_shell/wayland_layer_shell.dart' as wl_shell;
import 'package:path/path.dart' as path;

late Future<List<Application>> apps;

bool firstBuild = true;

void loadConfig([String? filepath]) {
  final configDir =
      Platform.environment["XDG_CONFIG_HOME"] ?? expandEnvironmentVariables(r"$HOME/.config");
  filepath ??= path.joinAll([configDir, "wayxec", "config"]);
  logger.d("configuration file path: $filepath");

  final configfile = File(filepath);
  final (config, errors) = parseConfig(configfile);
  switch (errors?.gravity) {
    case Gravity.fatal:
      errors!.log(logger);
      exit(1); // TODO.. should we exit with SystemNavigator.pop or with exit(1)?
    case Gravity.warn:
      errors!.log(logger);
    case Gravity.none:
    case null:
  }
  Get.instance.register(config);
}

void main(List<String> args) async {
  initLogger(minLevel: Level.debug);

  final cliparser = ArgParser()
    ..addFlag("normal-window",
        help: "run as a normal window instead of using the layer shell protocol")
    ..addOption("config",
        help: "configuration file location. Default is XDG_CONFIG_HOME/wayxec/config");
  final results = cliparser.parse(args);
  final normalWindow = results["normal-window"] as bool?;
  final configFilePath = results["config"] as String?;

  apps = loadApplications(await database);

  loadConfig(configFilePath);

  logger.i("set log level to ${Get.instance<Configuration>().logLevel}");
  setLogLevel(Get.instance<Configuration>().logLevel);

  WidgetsFlutterBinding.ensureInitialized();
  final shell = wl_shell.WaylandLayerShell();

  final width = Get.instance<Configuration>().width.toInt();
  final height = Get.instance<Configuration>().height.toInt();
  if (normalWindow != null && normalWindow) {
    await shell.setUnresizable();
    await shell.showWindow((width, height));
  } else {
    final isSupported = await shell.initialize(width, height);
    if (isSupported) {
      await shell.setLayer(ShellLayer.layerTop);
      await switch (kDebugMode) {
        true => shell.setKeyboardMode(ShellKeyboardMode.keyboardModeOnDemand),
        false => shell.setKeyboardMode(ShellKeyboardMode.keyboardModeExclusive),
      };
      await shell.setNamesapce("wayxec");
    } else {
      await shell.showWindow((width, height));
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
    var colorSchemeDark = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    );
    colorSchemeDark = colorSchemeDark.copyWith(
      surface: colorSchemeDark.surface.withValues(alpha: Get.instance<Configuration>().opacity),
    );

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
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
