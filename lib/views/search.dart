import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gtk_shell_layer_test/search_desktop.dart';
import 'package:path/path.dart' as path;
import 'package:rresvg/rresvg.dart';

class SearchApplication extends StatefulWidget {
  const SearchApplication({super.key});

  @override
  State<SearchApplication> createState() => _SearchApplicationState();
}

class _SearchApplicationState extends State<SearchApplication> {
  late final Future<List<Application>> apps;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    apps = compute((_) async => loadApplications().toList(), 0);
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          focusNode: focusNode,
          autofocus: true,
          controller: textController,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.all(2.0),
          ),
        ),
        Expanded(
          child: FutureBuilder(
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
                controller: scrollController,
                addAutomaticKeepAlives: false,
                addSemanticIndexes: false,
                itemCount: data.length,
                prototypeItem: const ListTile(),
                itemBuilder: (context, index) {
                  final theme = Theme.of(context);
                  final app = data[index];
                  return ListTile(
                    leading: app.icon != null ? _FutureIcon(app.icon!) : null,
                    title: Text(app.name),
                    enabled: true,
                    onTap: () {},
                    hoverColor: theme.hoverColor,
                    focusNode: FocusNode(),
                  );
                },
              );
            },
          ),
        ),
      ],
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
