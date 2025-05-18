import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gtk_shell_layer_test/db/db.dart';
import 'package:flutter_gtk_shell_layer_test/search_desktop.dart';
import 'package:flutter_gtk_shell_layer_test/views/search.dart';
import 'package:wayland_layer_shell/types.dart';
import 'package:wayland_layer_shell/wayland_layer_shell.dart' as wl_shell;

late Future<List<Application>> apps;

bool firstBuild = true;

void main() async {
  apps = loadApplications(await database);
  WidgetsFlutterBinding.ensureInitialized();
  final shell = wl_shell.WaylandLayerShell();
  final isSupported = await shell.initialize(400, 400);
  if (!isSupported) {
    throw StateError("Unsupported layer shell protocol");
  }
  await shell.setLayer(ShellLayer.layerTop);
  await switch(kDebugMode) {
    true => shell.setKeyboardMode(ShellKeyboardMode.keyboardModeOnDemand),
    false => shell.setKeyboardMode(ShellKeyboardMode.keyboardModeExclusive),
  };
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
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
    final colorSchemeDark = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    );

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
