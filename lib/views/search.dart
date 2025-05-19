import 'dart:io';
import 'dart:math';

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

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: keyboardFocusNode,
      onKey: (value) {
        if (textFocusNode.hasFocus) {
          if (value.physicalKey == PhysicalKeyboardKey.arrowDown && filtered.isNotEmpty) {
            setState(() {
              focusNodes[0].requestFocus();
            });
          }
        } else {
          if (value.character != null) {
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
                contentPadding: EdgeInsets.all(2.0),
              ),
              onChanged: (v) {
                setState(() {
                  if (v.isEmpty) {
                    filtered = widget.apps;
                  } else {
                    filtered = widget.apps.where((element) {
                      // TODO improve the matching alghoritm (match parts)
                      final end = min(v.length, element.name.length);
                      return element.name.substring(0, end).similarityTo(v, ignoreCase: true) > 0.5;
                    }).toList();
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
              prototypeItem: const ListTile(),
              itemBuilder: (context, index) {
                final theme = Theme.of(context);
                final app = filtered[index];
                return ListTile(
                  leading: app.icon != null ? _FutureIcon(app.icon!) : null,
                  title: Text(app.name),
                  enabled: true,
                  focusNode: focusNodes[index],
                  onTap: () async {
                    (await database).increaseExecCounter(app);
                    final result = await app.run();
                    if (result.isError()) {
                      print(result.unsafeGetError().error());
                    }
                  },
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
