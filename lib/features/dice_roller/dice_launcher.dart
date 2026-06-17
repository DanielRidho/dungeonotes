import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiceDraggableLauncher extends StatefulWidget {
  const DiceDraggableLauncher({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<DiceDraggableLauncher> createState() => _DiceDraggableLauncherState();
}

class _DiceDraggableLauncherState extends State<DiceDraggableLauncher> {
  static const _buttonSize = 56.0;

  Offset? _buttonOffset;
  var _dragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clampedOffset = _clampedOffset(
          _buttonOffset ?? _initialOffset(context, constraints),
          context,
          constraints,
        );
        return Stack(
          children: [
            widget.child,
            AnimatedPositioned(
              duration:
                  _dragging ? Duration.zero : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              left: clampedOffset.dx,
              top: clampedOffset.dy,
              child: _DiceFab(
                onDragStart: () => setState(() => _dragging = true),
                onDragUpdate: (details) {
                  setState(() {
                    _buttonOffset = _clampedOffset(
                      clampedOffset + details.delta,
                      context,
                      constraints,
                    );
                  });
                },
                onDragEnd: () {
                  setState(() {
                    _dragging = false;
                    _buttonOffset = _snappedOffset(
                      _buttonOffset ?? clampedOffset,
                      context,
                      constraints,
                    );
                  });
                },
                onPressed: () => context.push('/dice'),
              ),
            ),
          ],
        );
      },
    );
  }

  Offset _initialOffset(BuildContext context, BoxConstraints constraints) {
    final padding = MediaQuery.paddingOf(context);
    return Offset(
      constraints.maxWidth - padding.right - _buttonSize - 8,
      constraints.maxHeight * 0.64,
    );
  }

  Offset _clampedOffset(
    Offset value,
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final padding = MediaQuery.paddingOf(context);
    final minX = 8 + padding.left;
    final minY = 8 + padding.top;
    final maxX =
        math.max(minX, constraints.maxWidth - _buttonSize - padding.right - 8);
    final maxY =
        math.max(minY, constraints.maxHeight - _buttonSize - padding.bottom - 8);
    return Offset(
      value.dx.clamp(minX, maxX).toDouble(),
      value.dy.clamp(minY, maxY).toDouble(),
    );
  }

  Offset _snappedOffset(
    Offset value,
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final clamped = _clampedOffset(value, context, constraints);
    final padding = MediaQuery.paddingOf(context);
    final leftX = 8 + padding.left;
    final rightX = math.max(
      leftX,
      constraints.maxWidth - _buttonSize - padding.right - 8,
    );
    final center = clamped.dx + (_buttonSize / 2);
    final snappedX = center < constraints.maxWidth / 2 ? leftX : rightX;
    return Offset(snappedX, clamped.dy);
  }
}

class DicePageActionGroup extends StatelessWidget {
  const DicePageActionGroup({
    required this.primaryAction,
    super.key,
  });

  final Widget primaryAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DiceActionButton(),
        const SizedBox(width: 12),
        primaryAction,
      ],
    );
  }
}

class DiceActionButton extends StatelessWidget {
  const DiceActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      tooltip: 'Open dice roller',
      onPressed: () => context.push('/dice'),
      child: const Icon(Icons.casino_outlined),
    );
  }
}

class _DiceFab extends StatelessWidget {
  const _DiceFab({
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onPressed,
  });

  final VoidCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = FloatingActionButton(
      heroTag: null,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      onPressed: onPressed,
      child: const Icon(Icons.casino_outlined),
    );

    return GestureDetector(
      onPanStart: (_) => onDragStart(),
      onPanUpdate: onDragUpdate,
      onPanEnd: (_) => onDragEnd(),
      onPanCancel: onDragEnd,
      child: button,
    );
  }
}
