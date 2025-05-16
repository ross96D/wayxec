import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gtk_shell_layer_test/search_desktop.dart';
import 'package:path/path.dart' as path;
import 'package:rresvg/rresvg.dart';

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

  @override
  void initState() {
    super.initState();
    focusNodes.addAll(List.generate(widget.apps.length, (index) => FocusNode()));
    focusNodes[0].requestFocus();
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
          if (value.physicalKey == PhysicalKeyboardKey.arrowDown) {
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
          TextFormField(
            focusNode: textFocusNode,
            autofocus: true,
            controller: textController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(2.0),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              addAutomaticKeepAlives: false,
              addSemanticIndexes: false,
              itemCount: widget.apps.length,
              prototypeItem: const ListTile(),
              itemBuilder: (context, index) {
                final theme = Theme.of(context);
                final app = widget.apps[index];
                return ListTile(
                  leading: app.icon != null ? _FutureIcon(app.icon!) : null,
                  title: Text(app.name),
                  enabled: true,
                  focusNode: focusNodes[index],
                  onFocusChange: (v) {
                    if (v) {
                      setState(() {});
                    }
                  },
                  onTap: () {
                    setState(() {
                      focusNodes[index].requestFocus();
                    });
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
