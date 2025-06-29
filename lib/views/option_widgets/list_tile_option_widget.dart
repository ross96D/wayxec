import 'package:flutter/material.dart';
import 'package:wayxec/search_desktop.dart';
import 'package:wayxec/views/searchopts.dart';
import 'package:wayxec/views/util_widgets/future_icon.dart';

class ListTileOptionWidget extends StatelessWidget {

  final Application app; 
  final SearchOptionsRenderConfig config;
  final VoidCallback onTap;
 
  const ListTileOptionWidget({
    required this.app,
    required this.config,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: app.icon != null ? FutureIcon(app.icon!) : SizedBox(width: 35,),
      title: Text(
        app.name,
        style: theme.textTheme.bodyLarge,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
      onTap: onTap,
      subtitle: app.comment != null
          ? Text(
              app.comment!,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: theme.textTheme.bodySmall,
            )
          : SizedBox.shrink(),
      enabled: true,
      tileColor: config.isHighlighted
          ? Color.alphaBlend(theme.hoverColor, theme.colorScheme.surface)
          : theme.colorScheme.surface,
    );
  }
}
