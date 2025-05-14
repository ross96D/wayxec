import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gtk_shell_layer_test/search_desktop.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';

class SearchApplication extends StatefulWidget {
  const SearchApplication({super.key});

  @override
  State<SearchApplication> createState() => _SearchApplicationState();
}

class _SearchApplicationState extends State<SearchApplication> {
  late final Future<List<Application>> apps;

  @override
  void initState() {
    apps = compute((_) async => loadApplications().toList(), 0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: apps,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(),
            ),
          );
        }
        final data = snapshot.data!;
        return ListView.builder(
          itemBuilder: (context, index) {
            if (index < data.length) {
              final app = data[index];
              return ListTile(
                leading: app.icon != null ? _FutureIcon(app.icon!) : null,
                title: Text(app.name),
                enabled: true,
                onTap: () => print("HELLo"),
                hoverColor: theme.hoverColor,
              );
            } else {
              return null;
            }
          },
        );
      },
    );
  }
}

class _FutureIcon extends StatelessWidget {
  final String icon;
  const _FutureIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FreedesktopIconThemes()
          .findIcon(IconQuery(name: "com.obsproject.Studio", size: 64, extensions: const [])),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.error != null) {
          print("ERROR\n${snapshot.error}\nSTACKTRACE: ${snapshot.stackTrace}");
          return const Icon(Icons.error);
        }
        if (snapshot.data == null) {
          print("ADSASDADS FUCK IS NULL");
          return const SizedBox.shrink();
        }
        print("ADSASDADS ${snapshot.data}");
        final image = Image.file(snapshot.data!, width: 25, height: 25);
        return image;
      },
    );
  }
}
