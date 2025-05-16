import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gtk_shell_layer_test/search_desktop.dart';
import 'package:flutter_gtk_shell_layer_test/views/search.dart';
import 'package:wayland_layer_shell/types.dart';
import 'package:wayland_layer_shell/wayland_layer_shell.dart' as wl_shell;

late Future<List<Application>> apps; 

void main() async {
  apps = compute((_) async => loadApplications().toList(), 0);
  WidgetsFlutterBinding.ensureInitialized();
  final shell = wl_shell.WaylandLayerShell();
  final isSupported = await shell.initialize(400, 400);
  if (!isSupported) {
    throw StateError("Unsupported layer shell protocol");
  }
  await shell.setLayer(ShellLayer.layerTop);
  await shell.setKeyboardMode(ShellKeyboardMode.keyboardModeOnDemand);
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
    // apps = compute((_) async => loadApplications().toList(), 0);
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
      shortcuts: <ShortcutActivator, Intent>{
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.escape): const ExitIntent()
      },
      actions: {
        ...WidgetsApp.defaultActions,
        ExitIntent: ExitAction(),
      },
      home: Scaffold(
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
    );
  }
}
