import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gtk_shell_layer_test/search_desktop.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;

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
  late Widget iconImage;
  _FutureIcon(this.icon) {
    final file = searchIcon(icon);
    if (file == null) {
      iconImage = const SizedBox.shrink();
      return;
    }
    if (path.extension(file.path) == ".svg") {
      iconImage = SizedBox(
        width: 25,
        height: 25,
        child: SvgPicture.file(
          file,
          width: 25,
          height: 25,
          fit: BoxFit.scaleDown,
        ),
      );
    } else {
      iconImage = Image.file(file, width: 25, height: 25);
    }
  }

  @override
  Widget build(BuildContext context) {
    return iconImage;
  }
}
