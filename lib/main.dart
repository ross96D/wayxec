import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void loadConfig() {
  final configDir =
      Platform.environment["XDG_CONFIG_HOME"] ?? expandEnvironmentVariables(r"$HOME/.config");
  final filepath = path.joinAll([configDir, "wayxec", "config"]);
  logger.d("configuration file path: $filepath");

  final configfile = File(filepath);
  final String configstr = switch (configfile.existsSync()) {
    true => configfile.readAsStringSync(),
    false => "",
  };
  logger.d("configuration: $configstr");

  final (config, errors) = parseConfig(configstr);
  switch (errors.gravity) {
    case Gravity.fatal:
      logger.f(errors.error());
      exit(1); // TODO.. should we exit with SystemNavigator.pop or with exit(1)?
    case Gravity.warn:
      logger.e(errors.error());
    case Gravity.none:
  }

  Get.instance.register(config);
}

void main(List<String> args) async {
  initLogger();

  apps = loadApplications(await database);

  loadConfig();

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
