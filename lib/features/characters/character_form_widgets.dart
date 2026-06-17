import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/stat_input.dart';
import '../../data/models/app_models.dart';
import 'character_entry_dialogs.dart';
import 'character_rules.dart';

class TwoColumn extends StatelessWidget {
  const TwoColumn({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final child in children) ...[
          child,
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class SimpleDropdownField extends StatelessWidget {
  const SimpleDropdownField({
    required this.controller,
    required this.label,
    required this.options,
    super.key,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final List<String> options;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final uniqueOptions = options.toSet().toList();
        final selected =
            uniqueOptions.contains(value.text) ? value.text : null;
        return DropdownButtonFormField<String>(
          value: selected,
          decoration: InputDecoration(labelText: label),
          hint: Text('Choose $label'),
          items: [
            for (final option in uniqueOptions)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (value) {
            if (value != null) {
              controller.text = value;
              onChanged?.call(value);
            }
          },
        );
      },
    );
  }
}

enum _ReferenceCardAction { search, custom }

class ReferenceSelectCard extends StatelessWidget {
  const ReferenceSelectCard({
    required this.label,
    required this.controller,
    required this.placeholder,
    required this.onSearch,
    required this.onCustom,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final VoidCallback onSearch;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return _SelectCard(
          label: label,
          value: value.text,
          placeholder: placeholder,
          onTap: onSearch,
          trailing: PopupMenuButton<_ReferenceCardAction>(
            tooltip: '$label options',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              switch (action) {
                case _ReferenceCardAction.search:
                  onSearch();
                case _ReferenceCardAction.custom:
                  onCustom();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ReferenceCardAction.search,
                child: Text('Search'),
              ),
              PopupMenuItem(
                value: _ReferenceCardAction.custom,
                child: Text('Custom'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class OptionSelectCard extends StatelessWidget {
  const OptionSelectCard({
    required this.label,
    required this.controller,
    required this.placeholder,
    required this.options,
    super.key,
    this.allowCustom = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final List<String> options;
  final bool allowCustom;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return _SelectCard(
          label: label,
          value: value.text,
          placeholder: placeholder,
          onTap: () => _pick(context),
          trailing: const Icon(Icons.keyboard_arrow_down),
        );
      },
    );
  }

  Future<void> _pick(BuildContext context) async {
    const customMarker = '__custom__';
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(label, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final option in options)
              ListTile(
                title: Text(option),
                trailing:
                    controller.text == option ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
            if (allowCustom)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Custom'),
                onTap: () => Navigator.of(sheetContext).pop(customMarker),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || selected == null) {
      return;
    }
    if (selected == customMarker) {
      final custom = await showTextValueDialog(
        context,
        title: 'Custom $label',
        label: label,
        initialValue: controller.text,
      );
      if (custom != null && custom.trim().isNotEmpty) {
        controller.text = custom.trim();
      }
      return;
    }
    controller.text = selected;
    onChanged?.call(selected);
  }
}

class LevelProficiencyCard extends StatelessWidget {
  const LevelProficiencyCard({
    required this.level,
    required this.proficiencyBonus,
    required this.onLevelChanged,
    super.key,
  });

  final int level;
  final int proficiencyBonus;
  final ValueChanged<int> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _pickLevel(context),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level $level',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proficiency',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+$proficiencyBonus',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLevel(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'Level',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (var value = 1; value <= 20; value++)
              ListTile(
                title: Text('Level $value'),
                trailing: level == value ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      onLevelChanged(selected);
    }
  }
}

class SubclassSelectCard extends StatelessWidget {
  const SubclassSelectCard({
    required this.controller,
    required this.level,
    super.key,
  });

  final TextEditingController controller;
  final int level;

  @override
  Widget build(BuildContext context) {
    final locked = level < 3;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return _SelectCard(
          label: 'Subclass',
          value: locked ? '' : value.text,
          placeholder: locked ? 'Unlocked at level 3' : 'Select subclass',
          enabled: !locked,
          onTap: locked ? null : () => _edit(context),
          trailing: locked
              ? const Icon(Icons.lock_outline)
              : const Icon(Icons.edit_outlined),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context) async {
    final value = await showTextValueDialog(
      context,
      title: 'Subclass',
      label: 'Subclass',
      initialValue: controller.text,
    );
    if (value != null) {
      controller.text = value.trim();
    }
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final String value;
  final String placeholder;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasValue = value.trim().isNotEmpty;
    return Material(
      color: enabled
          ? colors.surfaceContainerHighest.withValues(alpha: 0.48)
          : colors.surfaceContainerHighest.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasValue ? value : placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasValue
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconTheme(
                data: IconThemeData(
                  color: enabled ? colors.onSurfaceVariant : colors.outline,
                ),
                child: trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AbilityScoreField extends StatelessWidget {
  const AbilityScoreField({
    required this.controller,
    required this.label,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final score = int.tryParse(value.text.trim()) ?? 10;
        final modifier = CharacterRules.modifier(score);
        final colors = Theme.of(context).colorScheme;
        return Material(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                SizedBox(
                  width: 78,
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    validator: _scoreValidator,
                    decoration: const InputDecoration(
                      labelText: 'Score',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _ModifierBadge(value: modifier),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _scoreValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Required';
    }
    final number = int.tryParse(text);
    if (number == null) {
      return 'Number';
    }
    if (number < 0) {
      return 'No negative';
    }
    return null;
  }
}

class AbilityAssignmentPanel extends StatelessWidget {
  const AbilityAssignmentPanel({
    required this.controllers,
    required this.pool,
    required this.onPoolChanged,
    required this.onAssign,
    super.key,
  });

  final List<TextEditingController> controllers;
  final List<int> pool;
  final ValueChanged<List<int>> onPoolChanged;
  final void Function(TextEditingController controller, int? score) onAssign;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => onPoolChanged(const [8, 10, 12, 13, 14, 15]),
              icon: const Icon(Icons.view_list_outlined),
              label: const Text('Standard array'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                final random = Random();
                int rollOne() {
                  final rolls = [
                    for (var i = 0; i < 4; i++) random.nextInt(6) + 1,
                  ]..sort();
                  return rolls.skip(1).fold<int>(0, (sum, value) => sum + value);
                }

                onPoolChanged([for (var i = 0; i < 6; i++) rollOne()]);
              },
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Roll 4d6'),
            ),
            if (pool.isNotEmpty)
              OutlinedButton(
                onPressed: () => onPoolChanged(const []),
                child: const Text('Clear'),
              ),
          ],
        ),
        if (pool.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Assign each result once.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < controllers.length; i++)
            _AbilityAssignmentRow(
              label: abilityLabels.values.elementAt(i),
              controller: controllers[i],
              controllers: controllers,
              pool: pool,
              onAssign: onAssign,
            ),
        ],
      ],
    );
  }
}

class _AbilityAssignmentRow extends StatelessWidget {
  const _AbilityAssignmentRow({
    required this.label,
    required this.controller,
    required this.controllers,
    required this.pool,
    required this.onAssign,
  });

  final String label;
  final TextEditingController controller;
  final List<TextEditingController> controllers;
  final List<int> pool;
  final void Function(TextEditingController controller, int? score) onAssign;

  @override
  Widget build(BuildContext context) {
    final score = int.tryParse(controller.text.trim()) ?? 10;
    final modifier = CharacterRules.modifier(score);
    final selectedIndex = _selectedPoolIndex(controller);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Text(
                    'Score $score',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  _ModifierBadge(value: modifier),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var index = 0; index < pool.length; index++)
                    _PickNumberChip(
                      value: pool[index],
                      selected: selectedIndex == index,
                      enabled: selectedIndex == index || _isPoolIndexAvailable(index),
                      onTap: selectedIndex == index
                          ? () => onAssign(controller, null)
                          : _isPoolIndexAvailable(index)
                              ? () => onAssign(controller, pool[index])
                              : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _selectedPoolIndex(TextEditingController target) {
    return _selectedPoolIndexForController(controllers.indexOf(target));
  }

  int? _selectedPoolIndexForController(int controllerIndex) {
    if (controllerIndex < 0 || controllerIndex >= controllers.length) {
      return null;
    }
    final score = int.tryParse(controllers[controllerIndex].text.trim());
    if (score == null) {
      return null;
    }
    final sameScoreBefore = controllers.take(controllerIndex).where((item) {
      return int.tryParse(item.text.trim()) == score;
    }).length;
    final matchingIndexes = [
      for (var i = 0; i < pool.length; i++)
        if (pool[i] == score) i,
    ];
    return sameScoreBefore < matchingIndexes.length
        ? matchingIndexes[sameScoreBefore]
        : null;
  }

  bool _isPoolIndexAvailable(int index) {
    for (var i = 0; i < controllers.length; i++) {
      if (_selectedPoolIndexForController(i) == index) {
        return false;
      }
    }
    return true;
  }
}

class AbilityProficiencyPanel extends StatelessWidget {
  const AbilityProficiencyPanel({
    required this.character,
    required this.skillValues,
    required this.savingThrowValues,
    required this.onSkillsChanged,
    required this.onSavesChanged,
    super.key,
  });

  final CharacterNote character;
  final Map<String, String> skillValues;
  final Map<String, String> savingThrowValues;
  final ValueChanged<Map<String, String>> onSkillsChanged;
  final ValueChanged<Map<String, String>> onSavesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final ability in abilityLabels.keys)
          _AbilitySkillGroup(
            ability: ability,
            character: character,
            skillValues: skillValues,
            savingThrowValues: savingThrowValues,
            onSkillChanged: _setSkillRank,
            onSaveChanged: _setSaveRank,
          ),
      ],
    );
  }

  void _setSkillRank(String skill, ProficiencyRank rank) {
    final updated = Map<String, String>.of(skillValues);
    if (rank == ProficiencyRank.none) {
      updated.remove(skill);
    } else {
      updated[skill] = rank.name;
    }
    onSkillsChanged(updated);
  }

  void _setSaveRank(String abilityLabel, bool proficient) {
    final updated = Map<String, String>.of(savingThrowValues);
    if (proficient) {
      updated[abilityLabel] = ProficiencyRank.proficient.name;
    } else {
      updated.remove(abilityLabel);
    }
    onSavesChanged(updated);
  }
}

class _AbilitySkillGroup extends StatelessWidget {
  const _AbilitySkillGroup({
    required this.ability,
    required this.character,
    required this.skillValues,
    required this.savingThrowValues,
    required this.onSkillChanged,
    required this.onSaveChanged,
  });

  final String ability;
  final CharacterNote character;
  final Map<String, String> skillValues;
  final Map<String, String> savingThrowValues;
  final void Function(String skill, ProficiencyRank rank) onSkillChanged;
  final void Function(String abilityLabel, bool proficient) onSaveChanged;

  @override
  Widget build(BuildContext context) {
    final label = abilityLabels[ability] ?? ability;
    final score = CharacterRules.abilityScore(character, ability);
    final modifier = CharacterRules.modifier(score);
    final saveProficient =
        savingThrowValues[label] == ProficiencyRank.proficient.name;
    final saveTotal = CharacterRules.savingThrowTotal(
      character,
      ability,
      saveProficient,
    );
    final skills = skillAbilities.entries
        .where((entry) => entry.value == ability)
        .map((entry) => entry.key)
        .toList();

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Chip(label: Text('Score $score')),
                const SizedBox(width: 6),
                Chip(label: Text('Mod ${modifier >= 0 ? '+' : ''}$modifier')),
              ],
            ),
            const SizedBox(height: 8),
            const _CheckHeader(),
            _CheckRow(
              name: 'Saving Throw',
              abilityCode: CharacterRules.abilityCode(ability),
              score: modifier,
              profLabel: saveProficient
                  ? '+${CharacterRules.proficiencyBonus(character.level)}'
                  : '-',
              total: saveTotal,
              trailing: FilterChip(
                label: const Text('P'),
                selected: saveProficient,
                showCheckmark: false,
                onSelected: (value) => onSaveChanged(label, value),
              ),
            ),
            const Divider(height: 18),
            for (final skill in skills)
              _SkillCheckRow(
                character: character,
                skill: skill,
                value: skillValues[skill] ?? ProficiencyRank.none.name,
                onChanged: (rank) => onSkillChanged(skill, rank),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkillCheckRow extends StatelessWidget {
  const _SkillCheckRow({
    required this.character,
    required this.skill,
    required this.value,
    required this.onChanged,
  });

  final CharacterNote character;
  final String skill;
  final String value;
  final ValueChanged<ProficiencyRank> onChanged;

  @override
  Widget build(BuildContext context) {
    final ability = skillAbilities[skill] ?? 'strength';
    final modifier = CharacterRules.modifier(
      CharacterRules.abilityScore(character, ability),
    );
    final rank = ProficiencyRank.values.firstWhere(
      (rank) => rank.name == value,
      orElse: () => ProficiencyRank.none,
    );
    final proficiency = CharacterRules.proficiencyBonus(character.level);
    final profLabel = switch (rank) {
      ProficiencyRank.none => '-',
      ProficiencyRank.proficient => '+$proficiency',
      ProficiencyRank.expertise => '+${proficiency * 2}',
    };
    return _CheckRow(
      name: skill,
      abilityCode: CharacterRules.abilityCode(ability),
      score: modifier,
      profLabel: profLabel,
      total: CharacterRules.skillTotal(character, skill, rank),
      trailing: Wrap(
        spacing: 6,
        children: [
          FilterChip(
            label: const Text('P'),
            selected: rank == ProficiencyRank.proficient,
            showCheckmark: false,
            onSelected: (_) => onChanged(
              rank == ProficiencyRank.proficient
                  ? ProficiencyRank.none
                  : ProficiencyRank.proficient,
            ),
          ),
          FilterChip(
            label: const Text('E'),
            selected: rank == ProficiencyRank.expertise,
            showCheckmark: false,
            onSelected: (_) => onChanged(
              rank == ProficiencyRank.expertise
                  ? ProficiencyRank.none
                  : ProficiencyRank.expertise,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickNumberChip extends StatelessWidget {
  const _PickNumberChip({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colors.primaryContainer
          : colors.surfaceContainerHighest.withValues(alpha: enabled ? 0.75 : 0.28),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            '$value',
            style: TextStyle(
              color: selected
                  ? colors.onPrimaryContainer
                  : enabled
                      ? colors.onSurface
                      : colors.onSurfaceVariant.withValues(alpha: 0.45),
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.name,
    required this.abilityCode,
    required this.score,
    required this.profLabel,
    required this.total,
    required this.trailing,
  });

  final String name;
  final String abilityCode;
  final int score;
  final String profLabel;
  final int total;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name)),
                    _TotalBadge(value: total),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _AbilityBadge(label: abilityCode),
                    const SizedBox(width: 8),
                    SizedBox(width: 42, child: Text(_signed(score))),
                    SizedBox(width: 42, child: Text(profLabel)),
                    const Spacer(),
                    trailing,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: Text(name)),
              SizedBox(width: 54, child: _AbilityBadge(label: abilityCode)),
              SizedBox(width: 48, child: Text(_signed(score))),
              SizedBox(width: 48, child: Text(profLabel)),
              SizedBox(width: 52, child: _TotalBadge(value: total)),
              SizedBox(width: 104, child: trailing),
            ],
          );
        },
      ),
    );
  }

  String _signed(int value) => value >= 0 ? '+$value' : '$value';
}

class _CheckHeader extends StatelessWidget {
  const _CheckHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return const SizedBox.shrink();
        }
        return const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('Check')),
              SizedBox(width: 54, child: Text('Ability')),
              SizedBox(width: 48, child: Text('Score')),
              SizedBox(width: 48, child: Text('Prof.')),
              SizedBox(width: 52, child: Text('Total')),
              SizedBox(width: 104),
            ],
          ),
        );
      },
    );
  }
}

class _AbilityBadge extends StatelessWidget {
  const _AbilityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Center(child: Text(label)),
      ),
    );
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final text = value >= 0 ? '+$value' : '$value';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class _ModifierBadge extends StatelessWidget {
  const _ModifierBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = value >= 0 ? '+$value' : '$value';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          text,
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class SpellcastingSetupPanel extends StatelessWidget {
  const SpellcastingSetupPanel({
    required this.value,
    required this.level,
    required this.abilityScore,
    required this.onChanged,
    super.key,
  });

  final String value;
  final int level;
  final String abilityScore;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = abilityLabels.containsKey(value) ? value : 'wisdom';
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spellcasting',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selected,
              decoration: const InputDecoration(
                labelText: 'Spellcasting ability',
              ),
              items: [
                for (final entry in abilityLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (picked) {
                if (picked != null) {
                  onChanged(picked);
                }
              },
            ),
            const SizedBox(height: 10),
            SpellcastingSummary(
              level: level,
              abilityScore: abilityScore,
              abilityName: abilityLabels[selected] ?? 'Wisdom',
            ),
          ],
        ),
      ),
    );
  }
}

class SpellcastingSummary extends StatelessWidget {
  const SpellcastingSummary({
    required this.level,
    required this.abilityScore,
    required this.abilityName,
    super.key,
  });

  final int level;
  final String abilityScore;
  final String abilityName;

  @override
  Widget build(BuildContext context) {
    final score = int.tryParse(abilityScore) ?? 10;
    final modifier = CharacterRules.modifier(score);
    final proficiency = CharacterRules.proficiencyBonus(level);
    final saveDc = 8 + proficiency + modifier;
    final attackBonus = proficiency + modifier;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(label: Text('$abilityName ${modifier >= 0 ? '+' : ''}$modifier')),
        Chip(label: Text('Save DC $saveDc')),
        Chip(
          label: Text('Attack ${attackBonus >= 0 ? '+' : ''}$attackBonus'),
        ),
      ],
    );
  }
}

class CoinsInput extends StatelessWidget {
  const CoinsInput({
    required this.cp,
    required this.sp,
    required this.ep,
    required this.gp,
    required this.pp,
    super.key,
  });

  final TextEditingController cp;
  final TextEditingController sp;
  final TextEditingController ep;
  final TextEditingController gp;
  final TextEditingController pp;

  @override
  Widget build(BuildContext context) {
    return TwoColumn(
      children: [
        StatInput(controller: cp, label: 'CP', hint: '0'),
        StatInput(controller: sp, label: 'SP', hint: '0'),
        StatInput(controller: ep, label: 'EP', hint: '0'),
        StatInput(controller: gp, label: 'GP', hint: '0'),
        StatInput(controller: pp, label: 'PP', hint: '0'),
      ],
    );
  }
}

class TrainingToggles extends StatelessWidget {
  const TrainingToggles({
    required this.training,
    required this.onChanged,
    super.key,
  });

  final CharacterTraining training;
  final ValueChanged<CharacterTraining> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Armor Training', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _trainingChip(
              'Light',
              training.lightArmor,
              (value) => training.copyWith(lightArmor: value),
            ),
            _trainingChip(
              'Medium',
              training.mediumArmor,
              (value) => training.copyWith(mediumArmor: value),
            ),
            _trainingChip(
              'Heavy',
              training.heavyArmor,
              (value) => training.copyWith(heavyArmor: value),
            ),
            _trainingChip(
              'Shields',
              training.shields,
              (value) => training.copyWith(shields: value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Weapon Training', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _trainingChip(
              'Simple',
              training.simpleWeapons,
              (value) => training.copyWith(simpleWeapons: value),
            ),
            _trainingChip(
              'Martial',
              training.martialWeapons,
              (value) => training.copyWith(martialWeapons: value),
            ),
            _trainingChip(
              'Improvised',
              training.improvisedWeapons,
              (value) => training.copyWith(improvisedWeapons: value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _trainingChip(
    String label,
    bool selected,
    CharacterTraining Function(bool value) update,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (value) => onChanged(update(value)),
    );
  }
}

class BackstoryEditCard extends StatelessWidget {
  const BackstoryEditCard({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final text = value.text.trim();
        return Material(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _edit(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backstory & Personality',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text.isEmpty ? 'Optional notes' : text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: text.isEmpty
                                ? colors.onSurfaceVariant
                                : colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit backstory',
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _BackstoryDialog(initialValue: controller.text),
    );
    if (value != null) {
      controller.text = value.trim();
    }
  }
}

class _BackstoryDialog extends StatefulWidget {
  const _BackstoryDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_BackstoryDialog> createState() => _BackstoryDialogState();
}

class _BackstoryDialogState extends State<_BackstoryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: const Text('Backstory & Personality'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
      children: [
        AppTextField(
          controller: _controller,
          label: 'Notes',
          maxLines: 5,
          autofocus: true,
        ),
      ],
    );
  }
}

class SpellLimitsPanel extends StatelessWidget {
  const SpellLimitsPanel({
    required this.preparedMax,
    required this.slotControllers,
    super.key,
  });

  final TextEditingController preparedMax;
  final List<TextEditingController> slotControllers;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prepared & Slots',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            StatInput(
              controller: preparedMax,
              label: 'Prepared spell max',
              hint: '0',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < slotControllers.length; i++)
                  SizedBox(
                    width: 92,
                    child: StatInput(
                      controller: slotControllers[i],
                      label: 'Lv ${i + 1}',
                      hint: '0',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
