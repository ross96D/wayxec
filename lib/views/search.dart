import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wayxec/db/db.dart';
import 'package:wayxec/search_desktop.dart';
import 'package:path/path.dart' as path;
import 'package:rresvg/rresvg.dart';
import 'package:fuzzy_string/fuzzy_string.dart' as fuzzy;

class SearchApplication extends StatefulWidget {
  final List<Application> apps;
  const SearchApplication({super.key, required this.apps});

  @override
  State<SearchApplication> createState() => _SearchApplicationState();
}

class _SearchApplicationState extends State<SearchApplication> {
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode keyboardFocusNode = FocusNode();
  final FocusNode textFocusNode = FocusNode();
  final focusNodes = <FocusNode>[];
  late List<Application> filtered;

  static const _matcher = fuzzy.SmithWaterman();

  @override
  void initState() {
    super.initState();
    focusNodes.addAll(List.generate(widget.apps.length, (index) => FocusNode()));
    focusNodes[0].requestFocus();
    filtered = widget.apps;
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    keyboardFocusNode.dispose();
    textFocusNode.dispose();
    for (final node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _runApp(Application app) async {
    (await database).increaseExecCounter(app);
    final result = await app.run();
    if (result.isError()) {
      print(result.unsafeGetError().error());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RawKeyboardListener(
      focusNode: keyboardFocusNode,
      onKey: (value) async {
        if (textFocusNode.hasFocus) {
          if (value.physicalKey == PhysicalKeyboardKey.arrowDown && filtered.isNotEmpty) {
            setState(() {
              focusNodes[0].requestFocus();
            });
          } else if (value.physicalKey == PhysicalKeyboardKey.enter && filtered.isNotEmpty) {
            _runApp(filtered[0]);
          }
        } else {
          if (value.character != null && value.physicalKey != PhysicalKeyboardKey.enter) {
            textFocusNode.requestFocus();
          }
        }
      },
      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: TextFormField(
              focusNode: textFocusNode,
              autofocus: true,
              controller: textController,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(5.0),
              ),
              onChanged: (v) {
                setState(() {
                  if (v.isEmpty) {
                    filtered = widget.apps;
                  } else {
                    final scores = widget.apps
                      .map((e) {
                        return (e, e.name.similarityScoreTo(v, ignoreCase: true, matcher: _matcher));
                      })
                      .where((e) => e.$2 > 0.5)
                      .toList();
                    scores.sort((a, b) => b.$2.compareTo(a.$2));
                    
                    filtered = scores.map((e) => e.$1).toList();
                  }
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              addAutomaticKeepAlives: false,
              addSemanticIndexes: false,
              itemCount: filtered.length,
              prototypeItem: ListTile(
                title: Text("test", style: theme.textTheme.bodyLarge),
                subtitle: Text("test", style: theme.textTheme.bodySmall),
              ),
              itemBuilder: (context, index) {
                final theme = Theme.of(context);
                final app = filtered[index];
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
                  focusNode: focusNodes[index],
                  onTap: () => _runApp(app),
                  hoverColor: theme.hoverColor,
                );
              },
            ),
          ),
        ],
      ),
    );
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
