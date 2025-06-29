import 'package:flutter/material.dart';
import 'package:wayxec/db/db.dart';
import 'package:wayxec/logger.dart';
import 'package:wayxec/search_desktop.dart';
import 'package:wayxec/views/option_widgets/list_tile_option_widget.dart';
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
  return ListTileOptionWidget(
    app: app, 
    config: config,
    onTap:  () => _runApp(app),
  );
}

Future<void> _runApp(Application app) async {
  (await database).increaseExecCounter(app);
  final result = await app.run();
  if (result.isError()) {
    logger.e(result.unsafeGetError().error());
  }
}
