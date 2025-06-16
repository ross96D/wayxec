import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wayxec/db/db.dart';
import 'package:wayxec/search_desktop.dart';
import 'package:path/path.dart' as path;
import 'package:rresvg/rresvg.dart';
import 'package:wayxec/views/searchopts.dart';

class ApplicationOption extends Option<Application> {
  final Application app;
  const ApplicationOption(this.app);

  @override
  Application get object => app;

  @override
  String get value => app.name;

  factory ApplicationOption.from(Application app) {
    return ApplicationOption(app);
  }
}

class SearchApplication extends StatelessWidget {
  final List<Application> apps;
  const SearchApplication({super.key, required this.apps});

  @override
  Widget build(BuildContext context) {
    return SearchOptions(
      options: Option.from(apps, ApplicationOption.from),
      renderOption: _renderOption,
      onSelected: _runApp,
    );
  }
}

Widget _renderOption(BuildContext context, Application app, SearchOptionsRenderConfig config) {
  final theme = Theme.of(context);
  return ListTile(
    leading: app.icon != null ? _FutureIcon(app.icon!) : null,
    title: Text(
      app.name,
      style: theme.textTheme.bodyLarge,
      softWrap: false,
      overflow: TextOverflow.fade,
    ),
    subtitle: app.comment != null
        ? Text(
            app.comment!,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: theme.textTheme.bodySmall,
          )
        : null,
    enabled: true,
    tileColor: config.isHighlighted
        ? Color.alphaBlend(theme.hoverColor, theme.colorScheme.surface)
        : theme.colorScheme.surface,
  );
}

Future<void> _runApp(Application app) async {
  (await database).increaseExecCounter(app);
  final result = await app.run();
  if (result.isError()) {
    print(result.unsafeGetError().error());
  }
}

class _FutureIcon extends StatelessWidget {
  final String? filepath;

  // TODO the icon path should not be loaded here. Should be loaded at application start.
  _FutureIcon(String icon) : filepath = searchIcon(icon);

  @override
  Widget build(BuildContext context) {
    if (filepath == null) {
      return const SizedBox.shrink();
    }
    if (path.extension(filepath!) == ".svg") {
      return SvgView(
        filepath: filepath!,
        constraints: const BoxConstraints.tightFor(height: 35, width: 35),
      );
    }
    return Image.file(File(filepath!), width: 35, height: 35);
  }
}
