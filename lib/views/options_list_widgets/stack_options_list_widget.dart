import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:wayxec/views/searchopts.dart';

const animationDuration = Duration(milliseconds: 250);

class StackOptionsListWidget<T extends Object> extends StatefulWidget {
  final List<Option<T>> options;
  final RenderOption<T> renderOption;
  final List<Option<T>> filtered;
  final Widget? prototypeItem;
  final ValueNotifier<int> highlighted;
  final double availableHeight;

  const StackOptionsListWidget({
    required this.options,
    required this.renderOption,
    required this.filtered,
    required this.prototypeItem,
    required this.highlighted,
    required this.availableHeight,
    super.key,
  });

  @override
  State<StackOptionsListWidget<T>> createState() => _StackOptionsListWidgetState<T>();
}

class _StackOptionsListWidgetState<T extends Object> extends State<StackOptionsListWidget<T>>
    implements OptionsListRenderer {
  double itemHeight = 64; // TODO 2 this should be passed into here somehow
  late int shownItemCount = (widget.availableHeight / itemHeight).floor();

  int startingIndex = 0;
  final items = <_Item<T>>{};

  @override
  Widget build(BuildContext context) {
    final visibleItems = getVisibleItems();
    final toRemove = <_Item<T>>[];
    for (final e in items) {
      if (e.timeRemoved != null) {
        if (DateTime.now().difference(e.timeRemoved!) > animationDuration) {
          toRemove.add(e);
        }
      } else if (!visibleItems.any((i) => e.option.value == i.value)) {
        e.timeRemoved = DateTime.now();
      } else {
        e.timeRemoved = null;
      }
    }
    items.removeAll(toRemove);
    for (int i = getRenderStart(); i < getRenderEnd(); i++) {
      final e = widget.filtered[i];
      _Item<T>? item;
      try {
        // would be prettier with dartx firstOrNullWhere
        item = items.firstWhere((item) => item.option == e);
      } catch (_) {}
      if (item != null) {
        item.index = i;
      } else {
        items.add(
          _Item(
            index: i,
            option: e,
          ),
        );
      }
    }

    final sortedItems = items.toList()
      ..sort((a, b) {
        if (a.timeRemoved == null && b.timeRemoved != null) return 1;
        if (a.timeRemoved != null && b.timeRemoved == null) return -1;
        return a.index.compareTo(b.index);
      });
    final stackChildren = <Widget>[];
    int notRemovedItemCount = 0;
    for (final e in sortedItems) {
      if (e.timeRemoved == null) {
        notRemovedItemCount++;
      }
      stackChildren.add(
        ValueListenableBuilder(
          key: e.globalKey,
          valueListenable: widget.highlighted,
          builder: (context, value, child) {
            return AnimatedPositioned(
              duration: animationDuration * 0.66,
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              top: itemHeight * (e.index - startingIndex),
              child: _ItemAnimation(
                isItemVisible: e.timeRemoved == null && isItemVisible(e.index),
                isItemRemoved: e.timeRemoved != null,
                child: widget.renderOption(
                  context,
                  e.option.object,
                  SearchOptionsRenderConfig(isHighlighted: value == e.index),
                ),
              ),
            );
          },
        ),
      );
    }
    // print('ALL rendered:');
    // print(sortedItems.map((e) => e.option.value).toList());
    // print('Active ($notRemovedItemCount):');
    // print(sortedItems.where((e) => e.timeRemoved == null).map((e) => e.option.value).toList());
    return AnimatedContainer(
      height: itemHeight * min(notRemovedItemCount, shownItemCount),
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(), // needs to be set for clipBehavior to work for some reason
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: stackChildren,
      ),
    );
  }

  int getRenderStart() => max(0, startingIndex - 2);
  int getRenderEnd() => min((startingIndex + shownItemCount + 2), widget.filtered.length);
  List<Option<T>> getVisibleItems() => widget.filtered.sublist(
    getRenderStart(),
    getRenderEnd(),
  );

  @override
  bool isItemVisible(int index) {
    final lastVisibleItem = startingIndex + shownItemCount;
    return index >= startingIndex && index < lastVisibleItem;
  }

  @override
  void scrollTo(int index, ScrollDirection direction) {
    if (isItemVisible(index)) {
      return;
    }
    index = switch (direction) {
      ScrollDirection.idle => index - ((shownItemCount - 1) / 2).ceil(),
      ScrollDirection.forward => index - (shownItemCount - 1),
      ScrollDirection.reverse => index,
    };
    if (index < 0) {
      index = 0;
    }
    final lastStartingItem = widget.filtered.length - shownItemCount;
    if (index > lastStartingItem) {
      index = lastStartingItem;
    }
    if (index != startingIndex) {
      setState(() {
        startingIndex = index;
      });
    }
  }
}

class _Item<T extends Object> {
  int index;
  Option<T> option;
  DateTime? timeRemoved;
  GlobalKey globalKey;
  _Item({
    required this.index,
    required this.option,
  }) : globalKey = GlobalKey();

  @override
  int get hashCode => option.hashCode;
  @override
  bool operator ==(Object other) {
    if (other is! _Item<T>) {
      return false;
    }
    return other.option == option;
  }
}

class _ItemAnimation<T extends Object> extends StatefulWidget {
  final bool isItemVisible;
  final bool isItemRemoved;
  final Widget child;

  const _ItemAnimation({
    required this.isItemVisible,
    required this.isItemRemoved,
    required this.child,
    super.key,
  });

  @override
  State<_ItemAnimation> createState() => _ItemAnimationState();
}

class _ItemAnimationState extends State<_ItemAnimation> with TickerProviderStateMixin {
  late AnimationController opacityAnimationController;
  late AnimationController translationAnimationController;
  late Animation<Offset> translationAnimation;

  @override
  void initState() {
    super.initState();
    opacityAnimationController = AnimationController(
      vsync: this,
      duration: animationDuration,
      value: 0,
    );
    translationAnimationController = AnimationController(
      vsync: this,
      duration: animationDuration,
      value: widget.isItemVisible ? 1 : 0.5,
    );
    translationAnimation = Tween<Offset>(
      begin: Offset(-0.25, 0),
      end: Offset(0.25, 0),
    ).animate(translationAnimationController);
    if (widget.isItemVisible) {
      opacityAnimationController.animateTo(1, curve: Curves.easeOutCubic);
      translationAnimationController.animateTo(0.5, curve: Curves.easeOutCubic);
    }
  }

  @override
  void didUpdateWidget(covariant _ItemAnimation<Object> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isItemVisible != oldWidget.isItemVisible) {
      opacityAnimationController.animateTo(
        widget.isItemVisible ? 1 : 0,
        curve: Curves.easeOutCubic,
        duration: widget.isItemVisible ? animationDuration : animationDuration * 0.66,
      );
    }
    if (widget.isItemRemoved && !oldWidget.isItemRemoved) {
      translationAnimationController.animateTo(0, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    opacityAnimationController.dispose();
    translationAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: translationAnimation,
      child: FadeTransition(
        opacity: opacityAnimationController,
        child: widget.child,
      ),
    );
  }
}
