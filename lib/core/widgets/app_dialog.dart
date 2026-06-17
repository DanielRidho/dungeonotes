import 'dart:math' as math;

import 'package:flutter/material.dart';

class KeyboardSafeAlertDialog extends StatelessWidget {
  const KeyboardSafeAlertDialog({
    required this.title,
    required this.children,
    required this.actions,
    super.key,
    this.maxContentHeight = 460,
  });

  final Widget title;
  final List<Widget> children;
  final List<Widget> actions;
  final double maxContentHeight;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height -
        media.viewInsets.bottom -
        media.padding.top -
        media.padding.bottom -
        180;
    final maxHeight = math.max(
      160.0,
      math.min(maxContentHeight, availableHeight),
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: title,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: maxHeight,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
      actions: actions,
    );
  }
}
