import 'dart:math';

import 'package:dartx/dartx.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:wayxec/config.dart';
import 'package:wayxec/utils.dart';
import 'package:wayxec/views/searchopts.dart';

const animationDuration = Duration(milliseconds: 250);

class StackOptionsListWidget<T extends Object> extends StatefulWidget {
  final List<Option<T>> options;
  final RenderOption<T> renderOption;
  final double itemHeight;
  final List<Option<T>> filtered;
  final Widget? prototypeItem;
  final ValueNotifier<int> highlighted;
  final double availableHeight;

  const StackOptionsListWidget({
    required this.options,
    required this.renderOption,
    required this.itemHeight,
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
  late int focusableItemCount = (widget.availableHeight / widget.itemHeight).floor();
  late int visibleItemCount = focusableItemCount + 1;

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
      }
    }
    items.removeAll(toRemove);
    for (int i = getRenderStart(); i < getRenderEnd(); i++) {
      final e = widget.filtered[i];
      final item = items.firstOrNullWhere((item) => item.option == e);
      if (item != null) {
        item.index = i;
        item.timeRemoved = null;
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
    int visibleAndNotRemovedItemCount = 0;
    for (final e in sortedItems) {
      final isVisible = e.timeRemoved == null && isItemAtLeastPartiallyVisible(e.index);
      if (isVisible && e.timeRemoved == null) {
        visibleAndNotRemovedItemCount++;
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
              top: widget.itemHeight * (e.index - startingIndex),
              child: _ItemAnimation(
                isItemVisible: isVisible,
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

    final highlightedChildBackground = ValueListenableBuilder(
      valueListenable: widget.highlighted,
      builder: (context, value, child) {
        return AnimatedPositioned(
          duration: animationDuration * 0.66,
          curve: Curves.easeOutCubic,
          top: widget.itemHeight * (value - startingIndex),
          height: widget.itemHeight,
          left: 0,
          right: 0,
          child: child!,
        );
      },
      child: ColoredBox(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)),
    );

    final focusableHeight = focusableItemCount * widget.itemHeight;
    double visiplePerc = focusableItemCount / widget.filtered.length;
    if (visiplePerc > 1) {
      visiplePerc = 1;
    }
    double startingPerc = startingIndex / widget.filtered.length;
    if (startingPerc.isNaN) {
      startingPerc = 0;
    }
    final areAllItemsVisible = widget.filtered.length <= focusableItemCount;
    const scrollbarWidth = 3.0;
    final scrollbar = switch (Get.instance.get<Configuration>().showScrollBar) {
      true => AnimatedPositioned(
        duration: animationDuration * 0.66,
        curve: Curves.easeOutCubic,
        top: focusableHeight * startingPerc,
        height: focusableHeight * visiplePerc,
        right: 0,
        width: scrollbarWidth,
        child: AnimatedOpacity(
          duration: animationDuration,
          curve: Curves.easeOutCubic,
          opacity: areAllItemsVisible ? 0 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(scrollbarWidth)),
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
      false => null,
    };

    final children = [
      highlightedChildBackground,
      ...stackChildren,
    ];
    if (scrollbar != null) {
      children.add(scrollbar);
    }
    return Listener(
      onPointerSignal: onPointerSignal,
      child: AnimatedContainer(
        height: min(widget.availableHeight, widget.itemHeight * visibleAndNotRemovedItemCount),
        duration: animationDuration,
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(), // needs to be set for clipBehavior to work for some reason
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: children,
        ),
      ),
    );
  }

  int getRenderStart() => max(0, startingIndex - 1);
  int getRenderEnd() => min((startingIndex + focusableItemCount + 2), widget.filtered.length);
  List<Option<T>> getVisibleItems() => widget.filtered.sublist(
    getRenderStart(),
    getRenderEnd(),
  );

  @override
  bool isItemVisible(int index) {
    final lastVisibleItem = startingIndex + focusableItemCount;
    return index >= startingIndex && index < lastVisibleItem;
  }

  bool isItemAtLeastPartiallyVisible(int index) {
    final lastVisibleItem = startingIndex + visibleItemCount;
    return index >= startingIndex && index < lastVisibleItem;
  }

  @override
  void scrollTo(int index, ScrollDirection direction) {
    if (isItemVisible(index)) {
      return;
    }
    index = switch (direction) {
      ScrollDirection.idle => index - ((focusableItemCount - 1) / 2).ceil(),
      ScrollDirection.forward => index - (focusableItemCount - 1),
      ScrollDirection.reverse => index,
    };
    if (index < 0) {
      index = 0;
    }
    final lastStartingItem = widget.filtered.length - focusableItemCount;
    if (index > lastStartingItem) {
      index = lastStartingItem;
    }
    if (index != startingIndex) {
      setState(() {
        startingIndex = index;
      });
    }
  }

  void onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      int newHighlight = widget.highlighted.value;
      ScrollDirection? direction;
      if (event.scrollDelta.dy < 0) {
        direction = ScrollDirection.reverse;
        newHighlight--;
      } else if (event.scrollDelta.dy > 0) {
        direction = ScrollDirection.forward;
        newHighlight++;
      }
      if (newHighlight < 0) {
        newHighlight = 0;
      }
      if (newHighlight >= widget.filtered.length) {
        newHighlight = widget.filtered.length - 1;
      }
      if (newHighlight != widget.highlighted.value) {
        widget.highlighted.value = newHighlight;
        scrollTo(newHighlight, direction!);
      }
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
    if (widget.isItemRemoved != oldWidget.isItemRemoved) {
      translationAnimationController.animateTo(
        widget.isItemRemoved ? 0 : 0.5,
        curve: Curves.easeOutCubic,
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
