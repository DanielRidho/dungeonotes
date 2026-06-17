import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/snackbars.dart';
import '../../data/models/app_models.dart';
import 'dice_controller.dart';

part 'dice_roller_widgets.dart';

class DiceRollerScreen extends ConsumerStatefulWidget {
  const DiceRollerScreen({super.key});

  @override
  ConsumerState<DiceRollerScreen> createState() => _DiceRollerScreenState();
}

class _DiceRollerScreenState extends ConsumerState<DiceRollerScreen> {
  static const _diceSides = [4, 6, 8, 10, 12, 20, 100];

  final _random = math.Random();
  final _customModifier = TextEditingController();
  final _dice = <_StageDie>[];
  Timer? _historyDebounce;
  var _nextId = 0;
  var _modifier = 0;
  var _showModifierPanel = false;
  var _effect = _RollEffect.none;

  @override
  void dispose() {
    _historyDebounce?.cancel();
    _customModifier.dispose();
    super.dispose();
  }

  int get _total =>
      _dice.fold<int>(_modifier, (sum, die) => sum + die.value);

  @override
  Widget build(BuildContext context) {
    final compactLayout = MediaQuery.sizeOf(context).height < 620;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Dice')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: constraints.maxHeight,
                child: _DicePanel(
                  dice: _dice,
                  total: _total,
                  modifier: _modifier,
                  showModifierPanel: _showModifierPanel,
                  effect: _effect,
                  compact: compactLayout,
                  customModifier: _customModifier,
                  onAddDie: _addDie,
                  onRoll: _rollAll,
                  onClearStage: _clearStage,
                  onToggleModifierPanel: () => setState(
                    () => _showModifierPanel = !_showModifierPanel,
                  ),
                  onModifierChanged: _setModifier,
                  onClearHistory: _clearHistory,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _addDie(int sides) {
    FocusScope.of(context).unfocus();
    if (_dice.length >= AppConstants.maxDiceCount) {
      showAppSnack(
        context,
        'You can keep up to ${AppConstants.maxDiceCount} dice on the table.',
        isError: true,
      );
      return;
    }
    setState(() {
      _dice.add(_createDie(sides));
      _refreshEffect();
    });
    _scheduleHistorySave();
  }

  void _rollAll() {
    FocusScope.of(context).unfocus();
    if (_dice.isEmpty) {
      showAppSnack(context, 'Add at least one die first', isError: true);
      return;
    }
    setState(() {
      for (var i = 0; i < _dice.length; i++) {
        final die = _dice[i];
        _dice[i] = die.copyWith(
          value: _random.nextInt(die.sides) + 1,
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          spinSeed: die.spinSeed + 1,
        );
      }
      _refreshEffect();
    });
    _scheduleHistorySave(immediate: true);
  }

  void _clearStage() {
    FocusScope.of(context).unfocus();
    setState(() {
      _dice.clear();
      _effect = _RollEffect.none;
    });
    _historyDebounce?.cancel();
  }

  void _setModifier(int value) {
    setState(() => _modifier = value);
    if (_dice.isNotEmpty) {
      _scheduleHistorySave();
    }
  }

  _StageDie _createDie(int sides) {
    return _StageDie(
      id: _nextId++,
      sides: sides,
      value: _random.nextInt(sides) + 1,
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      spinSeed: 1,
    );
  }

  void _refreshEffect() {
    final d20Values = _dice
        .where((die) => die.sides == 20)
        .map((die) => die.value)
        .toList(growable: false);
    if (d20Values.contains(20)) {
      _effect = _RollEffect.critical;
    } else if (d20Values.contains(1)) {
      _effect = _RollEffect.fumble;
    } else {
      _effect = _RollEffect.none;
    }
  }

  void _scheduleHistorySave({bool immediate = false}) {
    _historyDebounce?.cancel();
    if (immediate) {
      _saveCurrentRoll();
      return;
    }
    _historyDebounce = Timer(
      const Duration(milliseconds: 450),
      _saveCurrentRoll,
    );
  }

  Future<void> _saveCurrentRoll() async {
    if (!mounted || _dice.isEmpty) {
      return;
    }
    try {
      await ref.read(diceControllerProvider.notifier).recordRoll(
            sides: [for (final die in _dice) die.sides],
            rolls: [for (final die in _dice) die.value],
            modifier: _modifier,
            total: _total,
            rollType: 'Dice',
            label: _rollLabel(),
          );
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  String _rollLabel() {
    final dice = _dice.length == 1 ? '1 die' : '${_dice.length} dice';
    final modifier = _modifier == 0
        ? ''
        : ' ${_modifier > 0 ? '+' : '-'} ${_modifier.abs()}';
    return '$dice$modifier';
  }

  Future<void> _clearHistory() async {
    try {
      await ref.read(diceControllerProvider.notifier).clear();
      if (mounted) {
        showAppSnack(context, 'Dice history cleared');
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}
