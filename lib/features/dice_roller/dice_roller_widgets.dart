part of 'dice_roller_screen.dart';

class _DicePanel extends ConsumerWidget {
  const _DicePanel({
    required this.dice,
    required this.total,
    required this.modifier,
    required this.showModifierPanel,
    required this.effect,
    required this.compact,
    required this.customModifier,
    required this.onAddDie,
    required this.onRoll,
    required this.onClearStage,
    required this.onToggleModifierPanel,
    required this.onModifierChanged,
    required this.onClearHistory,
  });

  final List<_StageDie> dice;
  final int total;
  final int modifier;
  final bool showModifierPanel;
  final _RollEffect effect;
  final bool compact;
  final TextEditingController customModifier;
  final ValueChanged<int> onAddDie;
  final VoidCallback onRoll;
  final VoidCallback onClearStage;
  final VoidCallback onToggleModifierPanel;
  final ValueChanged<int> onModifierChanged;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(diceControllerProvider);

    final content = compact ? _compactContent(history) : _regularContent(history);

    return content;
  }

  Widget _regularContent(AsyncValue<List<DiceRoll>> history) {
    return Column(
      children: _contentChildren(
        arena: Flexible(
          flex: 7,
          child: _DiceArena(
            dice: dice,
            total: total,
            modifier: modifier,
            effect: effect,
          ),
        ),
        history: Flexible(
          flex: 5,
          child: _DiceHistory(
            history: history,
            onClearHistory: onClearHistory,
          ),
        ),
      ),
    );
  }

  Widget _compactContent(AsyncValue<List<DiceRoll>> history) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _contentChildren(
          arena: SizedBox(
            height: 180,
            child: _DiceArena(
              dice: dice,
              total: total,
              modifier: modifier,
              effect: effect,
            ),
          ),
          history: SizedBox(
            height: 160,
            child: _DiceHistory(
              history: history,
              onClearHistory: onClearHistory,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contentChildren({
    required Widget arena,
    required Widget history,
  }) {
    return [
      arena,
      const SizedBox(height: 10),
      _DiceControls(
        showModifierPanel: showModifierPanel,
        onAddDie: onAddDie,
        onToggleModifierPanel: onToggleModifierPanel,
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _ModifierPanel(
            modifier: modifier,
            customModifier: customModifier,
            onModifierChanged: onModifierChanged,
          ),
        ),
        crossFadeState: showModifierPanel
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 160),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: dice.isEmpty ? null : onRoll,
              child: const Text('Roll'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: dice.isEmpty ? null : onClearStage,
              child: const Text('Clear'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      history,
    ];
  }
}

class _DiceArena extends StatelessWidget {
  const _DiceArena({
    required this.dice,
    required this.total,
    required this.modifier,
    required this.effect,
  });

  final List<_StageDie> dice;
  final int total;
  final int modifier;
  final _RollEffect effect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = switch (effect) {
      _RollEffect.critical => Colors.amber,
      _RollEffect.fumble => colors.error,
      _ => colors.outlineVariant,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withValues(alpha: 0.7)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _DiceGridLayout.forCount(
            count: dice.length,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          );
          return Stack(
            children: [
              if (dice.isEmpty)
                Center(
                  child: Text(
                    'Tap a die below to roll',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              for (var i = 0; i < dice.length; i++)
                Positioned(
                  left: layout.leftFor(i),
                  top: layout.topFor(i),
                  child: _AnimatedDie(die: dice[i], size: layout.dieSize),
                ),
              Positioned(
                right: 14,
                bottom: 10,
                child: _TotalBadge(total: total, modifier: modifier),
              ),
              if (effect != _RollEffect.none)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _RollEffectBadge(effect: effect),
                ),
            ],
          );
        },
      ),
    );
  }

}

class _DiceGridLayout {
  const _DiceGridLayout({
    required this.count,
    required this.columns,
    required this.rows,
    required this.dieSize,
    required this.gap,
    required this.startX,
    required this.startY,
  });

  final int count;
  final int columns;
  final int rows;
  final double dieSize;
  final double gap;
  final double startX;
  final double startY;

  static _DiceGridLayout forCount({
    required int count,
    required double width,
    required double height,
  }) {
    if (count <= 0) {
      return const _DiceGridLayout(
        count: 0,
        columns: 1,
        rows: 1,
        dieSize: 56,
        gap: 10,
        startX: 0,
        startY: 0,
      );
    }
    final columns = _columnsFor(count);
    final rows = (count / columns).ceil();
    const gap = 10.0;
    final reservedBottom = math.min(56.0, height * 0.24);
    final usableHeight = math.max(48.0, height - reservedBottom - 20);
    final widthSize = (width - 24 - gap * (columns - 1)) / columns;
    final heightSize = (usableHeight - gap * (rows - 1)) / rows;
    final dieSize = math.max(
      24.0,
      math.min(72.0, math.min(widthSize, heightSize)),
    );
    final gridWidth = columns * dieSize + (columns - 1) * gap;
    final gridHeight = rows * dieSize + (rows - 1) * gap;
    return _DiceGridLayout(
      count: count,
      columns: columns,
      rows: rows,
      dieSize: dieSize,
      gap: gap,
      startX: math.max(8.0, (width - gridWidth) / 2),
      startY: math.max(8.0, (usableHeight - gridHeight) / 2),
    );
  }

  static int _columnsFor(int count) {
    if (count <= 3) {
      return count;
    }
    if (count == 4) {
      return 2;
    }
    if (count <= 6) {
      return 3;
    }
    return math.min(10, math.sqrt(count * 2).ceil());
  }

  double leftFor(int index) {
    final rowCount = _rowCount(index ~/ columns);
    final rowStart = startX + ((columns - rowCount) * (dieSize + gap) / 2);
    return rowStart + (index % columns) * (dieSize + gap);
  }

  double topFor(int index) {
    return startY + (index ~/ columns) * (dieSize + gap);
  }

  int _rowCount(int row) {
    final remaining = count - row * columns;
    return remaining.clamp(0, columns).toInt();
  }
}

class _AnimatedDie extends StatelessWidget {
  const _AnimatedDie({required this.die, required this.size});

  final _StageDie die;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${die.id}-${die.spinSeed}-${die.value}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final tumble = 1 - value;
        final scale = 0.82 + (0.18 * value);
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translate(
            (die.x - 0.5) * 96 * tumble,
            (die.y - 0.5) * 72 * tumble,
          )
          ..rotateX(tumble * math.pi * (1.1 + die.x))
          ..rotateY(tumble * math.pi * (1.2 + die.y))
          ..rotateZ(tumble * math.pi * 2.4)
          ..scale(scale);
        return Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: _DiceFace(
        sides: die.sides,
        label: '${die.value}',
        size: size,
      ),
    );
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.total, required this.modifier});

  final int total;
  final int modifier;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              modifier == 0 ? 'Total' : 'Total (${_signed(modifier)})',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 8),
            Text(
              '$total',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RollEffectBadge extends StatelessWidget {
  const _RollEffectBadge({required this.effect});

  final _RollEffect effect;

  @override
  Widget build(BuildContext context) {
    final critical = effect == _RollEffect.critical;
    final color = critical ? Colors.amber : Theme.of(context).colorScheme.error;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.82, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                critical ? Icons.auto_awesome : Icons.warning_amber_outlined,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                critical ? 'Natural 20' : 'Natural 1',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiceControls extends StatelessWidget {
  const _DiceControls({
    required this.showModifierPanel,
    required this.onAddDie,
    required this.onToggleModifierPanel,
  });

  final bool showModifierPanel;
  final ValueChanged<int> onAddDie;
  final VoidCallback onToggleModifierPanel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final sides in _DiceRollerScreenState._diceSides) ...[
            _DiceButton(sides: sides, onPressed: () => onAddDie(sides)),
            const SizedBox(width: 8),
          ],
          const SizedBox(width: 2),
          SizedBox(
            height: 42,
            width: 42,
            child: IconButton.filledTonal(
              onPressed: onToggleModifierPanel,
              icon: Icon(showModifierPanel ? Icons.remove : Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceButton extends StatelessWidget {
  const _DiceButton({required this.sides, required this.onPressed});

  final int sides;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Roll d$sides',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: _DiceFace(
            sides: sides,
            label: '$sides',
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _ModifierPanel extends StatelessWidget {
  const _ModifierPanel({
    required this.modifier,
    required this.customModifier,
    required this.onModifierChanged,
  });

  final int modifier;
  final TextEditingController customModifier;
  final ValueChanged<int> onModifierChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: customModifier,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,3}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Modifier',
                hintText: '0',
                isDense: true,
              ),
              onChanged: (_) {},
              onSubmitted: (value) {
                FocusScope.of(context).unfocus();
                onModifierChanged(int.tryParse(value.trim()) ?? 0);
              },
              onEditingComplete: () {
                FocusScope.of(context).unfocus();
                onModifierChanged(
                  int.tryParse(customModifier.text.trim()) ?? 0,
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Current modifier: ${_signed(modifier)}',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiceHistory extends StatelessWidget {
  const _DiceHistory({
    required this.history,
    required this.onClearHistory,
  });

  final AsyncValue<List<DiceRoll>> history;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        child: Column(
          children: [
            Row(
              children: [
                Text('History', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  onPressed: history.valueOrNull?.isEmpty ?? true
                      ? null
                      : onClearHistory,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              ],
            ),
            Expanded(
              child: history.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text(
                    error.toString(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No rolls yet.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final roll = items[index];
                      return _HistoryTile(roll: roll);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.roll});

  final DiceRoll roll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final formula = roll.formula.isNotEmpty
        ? roll.formula
        : '${roll.diceCount}d${roll.sides}${roll.modifier == 0 ? '' : ' ${_signed(roll.modifier)}'}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        child: Text('${roll.total}'),
      ),
      title: Text(
        [roll.rollType, formula].where((value) => value.isNotEmpty).join(' - '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          'Rolls: ${roll.rolls.join(', ')}',
          DateFormatters.dateTime.format(roll.createdAt),
        ].join(' / '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({
    required this.sides,
    required this.label,
    required this.size,
  });

  final int sides;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _dieColor(sides);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DiePainter(sides: sides, color: color),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(size * 0.18),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.34,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _dieColor(int sides) {
    return switch (sides) {
      4 => const Color(0xFF25A56A),
      6 => const Color(0xFF2AA9C9),
      8 => const Color(0xFF7C2CE0),
      10 => const Color(0xFFC62D8A),
      12 => const Color(0xFFE03838),
      20 => const Color(0xFFFF7A1A),
      100 => const Color(0xFF6F737C),
      _ => const Color(0xFF9C7A2F),
    };
  }
}

class _DiePainter extends CustomPainter {
  const _DiePainter({
    required this.sides,
    required this.color,
  });

  final int sides;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _diePath(size);
    final shadowPath = path.shift(Offset(0, size.shortestSide * 0.06));
    canvas.drawPath(shadowPath, Paint()..color = Colors.black38);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _tint(color, 0.28),
            color,
            _shade(color, 0.28),
          ],
        ).createShader(Offset.zero & size),
    );

    final center = size.center(Offset.zero);
    final points = _pathPoints(size);
    if (points.length >= 3) {
      for (var i = 0; i < points.length; i++) {
        final facet = Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(points[i].dx, points[i].dy)
          ..lineTo(points[(i + 1) % points.length].dx,
              points[(i + 1) % points.length].dy)
          ..close();
        final alpha = i.isEven ? 0.16 : 0.08;
        canvas.drawPath(
          facet,
          Paint()
            ..color = (i < points.length / 2 ? Colors.white : Colors.black)
                .withValues(alpha: alpha),
        );
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, size.shortestSide * 0.025)
        ..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  Path _diePath(Size size) {
    if (sides == 6) {
      final inset = size.shortestSide * 0.08;
      return Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              inset,
              inset,
              size.width - inset * 2,
              size.height - inset * 2,
            ),
            Radius.circular(size.shortestSide * 0.1),
          ),
        );
    }
    final points = _pathPoints(size);
    return Path()
      ..moveTo(points.first.dx, points.first.dy)
      ..addPolygon(points, true);
  }

  List<Offset> _pathPoints(Size size) {
    if (sides == 4) {
      return [
        Offset(size.width * 0.5, size.height * 0.04),
        Offset(size.width * 0.94, size.height * 0.88),
        Offset(size.width * 0.06, size.height * 0.88),
      ];
    }
    if (sides == 8) {
      return [
        Offset(size.width * 0.5, size.height * 0.02),
        Offset(size.width * 0.95, size.height * 0.5),
        Offset(size.width * 0.5, size.height * 0.98),
        Offset(size.width * 0.05, size.height * 0.5),
      ];
    }
    final vertexCount = switch (sides) {
      10 => 6,
      12 => 8,
      20 => 10,
      100 => 12,
      _ => 8,
    };
    final radius = size.shortestSide * 0.46;
    final center = size.center(Offset.zero);
    return [
      for (var i = 0; i < vertexCount; i++)
        Offset(
          center.dx + math.cos((-math.pi / 2) + (i * 2 * math.pi / vertexCount)) * radius,
          center.dy + math.sin((-math.pi / 2) + (i * 2 * math.pi / vertexCount)) * radius,
        ),
    ];
  }

  @override
  bool shouldRepaint(covariant _DiePainter oldDelegate) {
    return oldDelegate.sides != sides || oldDelegate.color != color;
  }
}

class _StageDie {
  const _StageDie({
    required this.id,
    required this.sides,
    required this.value,
    required this.x,
    required this.y,
    required this.spinSeed,
  });

  final int id;
  final int sides;
  final int value;
  final double x;
  final double y;
  final int spinSeed;

  _StageDie copyWith({
    int? value,
    double? x,
    double? y,
    int? spinSeed,
  }) {
    return _StageDie(
      id: id,
      sides: sides,
      value: value ?? this.value,
      x: x ?? this.x,
      y: y ?? this.y,
      spinSeed: spinSeed ?? this.spinSeed,
    );
  }
}

enum _RollEffect { none, critical, fumble }

String _signed(int value) {
  if (value == 0) {
    return '+0';
  }
  return value > 0 ? '+$value' : '$value';
}

Color _tint(Color color, double amount) {
  return Color.lerp(color, Colors.white, amount) ?? color;
}

Color _shade(Color color, double amount) {
  return Color.lerp(color, Colors.black, amount) ?? color;
}
