part of 'character_sheet_tabs.dart';

class _SpellsTab extends ConsumerWidget {
  const _SpellsTab({
    required this.character,
    required this.campaignId,
    required this.runtime,
  });

  final CharacterNote character;
  final String? campaignId;
  final CampaignCharacterState runtime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abilityName =
        abilityLabels[character.spellcastingAbility] ?? 'Wisdom';
    final modifier = CharacterRules.modifier(
      CharacterRules.abilityScore(character, character.spellcastingAbility),
    );
    final attack = CharacterRules.spellAttackBonus(
      character,
      character.spellcastingAbility,
    );

    return _TabList(
      children: [
        _Panel(
          title: 'Spellcasting',
          children: [
            _FactGrid(
              items: [
                _Fact('Ability', '$abilityName ${_signed(modifier)}'),
                _Fact(
                  'Save DC',
                  '${CharacterRules.spellSaveDc(character, character.spellcastingAbility)}',
                ),
                _Fact('Attack', _signed(attack)),
                _Fact(
                  'Prepared Max',
                  '${character.spellcastingSetup.preparedMax}',
                ),
                _Fact('Cantrips Known', '${_spellsAtLevel(0).length}'),
                _Fact('Spells Known', '$_leveledSpellCount'),
              ],
            ),
          ],
        ),
        _SpellListPanel(
          character: character,
          campaignId: campaignId,
          runtime: runtime,
          onSlotChanged: (next) => _saveRuntime(context, ref, next),
        ),
      ],
    );
  }

  List<SpellNote> _spellsAtLevel(int level) {
    return [
      for (final spell in character.spellNotes)
        if (_spellLevel(spell) == level) spell,
    ];
  }

  int get _leveledSpellCount {
    return character.spellNotes
        .where((spell) {
          final level = _spellLevel(spell);
          return level >= 1 && level <= 9;
        })
        .length;
  }

  Future<void> _saveRuntime(
    BuildContext context,
    WidgetRef ref,
    CampaignCharacterState next,
  ) async {
    if (campaignId == null) {
      return;
    }
    try {
      await ref
          .read(campaignCharacterStatesControllerProvider(campaignId!).notifier)
          .save(next);
      if (context.mounted) {
        showAppSnack(context, 'Spell slots updated');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}

class _SpellListPanel extends StatelessWidget {
  const _SpellListPanel({
    required this.character,
    required this.campaignId,
    required this.runtime,
    required this.onSlotChanged,
  });

  final CharacterNote character;
  final String? campaignId;
  final CampaignCharacterState runtime;
  final ValueChanged<CampaignCharacterState> onSlotChanged;

  @override
  Widget build(BuildContext context) {
    final grouped = {
      for (var level = 0; level <= 9; level++)
        level: [
          for (final spell in character.spellNotes)
            if (_spellLevel(spell) == level) spell,
        ]..sort((a, b) => a.spellName.compareTo(b.spellName)),
    };
    return _Panel(
      title: 'Spells',
      children: [
        if (character.spellNotes.isEmpty)
          const Text('No spells yet.')
        else
          for (var level = 0; level <= 9; level++)
            if (grouped[level]!.isNotEmpty ||
                character.spellcastingSetup.slotTotal(level) > 0)
              _SpellLevelSection(
                level: level,
                spells: grouped[level]!,
                totalSlots: character.spellcastingSetup.slotTotal(level),
                expendedSlots: _expended(level),
                enabled: campaignId != null,
                onSlotChanged: level == 0
                    ? null
                    : (delta) => _changeSlot(level, delta),
              ),
      ],
    );
  }

  int _expended(int level) {
    return int.tryParse(runtime.expendedSpellSlots['$level'] ?? '') ?? 0;
  }

  void _changeSlot(int level, int delta) {
    final total = character.spellcastingSetup.slotTotal(level);
    var next = _expended(level) + delta;
    if (next < 0) {
      next = 0;
    }
    if (next > total) {
      next = total;
    }
    final updated = Map<String, String>.of(runtime.expendedSpellSlots);
    if (next == 0) {
      updated.remove('$level');
    } else {
      updated['$level'] = '$next';
    }
    onSlotChanged(runtime.copyWith(expendedSpellSlots: updated));
  }
}

class _SpellLevelSection extends StatelessWidget {
  const _SpellLevelSection({
    required this.level,
    required this.spells,
    required this.totalSlots,
    required this.expendedSlots,
    required this.enabled,
    required this.onSlotChanged,
  });

  final int level;
  final List<SpellNote> spells;
  final int totalSlots;
  final int expendedSlots;
  final bool enabled;
  final ValueChanged<int>? onSlotChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final available = totalSlots - expendedSlots;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  level == 0 ? 'Cantrips' : 'Level $level',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (level > 0 && totalSlots > 0) ...[
                Text(
                  '$available / $totalSlots available',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  tooltip: 'Use slot',
                  onPressed: !enabled || available <= 0
                      ? null
                      : () => onSlotChanged?.call(1),
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: enabled && available > 0 ? colors.primary : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Restore slot',
                  onPressed: !enabled || expendedSlots <= 0
                      ? null
                      : () => onSlotChanged?.call(-1),
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: enabled && expendedSlots > 0 ? colors.primary : null,
                  ),
                ),
              ],
            ],
          ),
          if (spells.isEmpty)
            Text(
              level == 0 ? 'No cantrips noted.' : 'No spells at this level.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            _SpellList(spells: spells),
        ],
      ),
    );
  }
}

class _SpellList extends StatelessWidget {
  const _SpellList({required this.spells});

  final List<SpellNote> spells;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final spell in spells) ...[
          _SpellListRow(spell: spell),
          if (spell != spells.last) const Divider(height: 1),
        ],
      ],
    );
  }
}

class _SpellListRow extends StatelessWidget {
  const _SpellListRow({required this.spell});

  final SpellNote spell;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: colors.primaryContainer,
        child: Icon(
          Icons.local_fire_department_outlined,
          size: 18,
          color: colors.onPrimaryContainer,
        ),
      ),
      title: Text(
        spell.spellName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _componentsText(spell),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'Spell details',
        icon: const Icon(Icons.info_outline),
        onPressed: () => _showSpellDetails(context, spell),
      ),
    );
  }

  String _componentsText(SpellNote spell) {
    return spell.components.isEmpty
        ? 'No components noted'
        : spell.components.join(' / ');
  }

  void _showSpellDetails(BuildContext context, SpellNote spell) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(spell.spellName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SpellDetailLine(
                label: 'Level',
                value: spell.spellLevel.isEmpty ? 'Cantrip' : spell.spellLevel,
              ),
              _SpellDetailLine(
                label: 'Casting Time',
                value: spell.castingTime,
              ),
              _SpellDetailLine(label: 'Range', value: spell.range),
              _SpellDetailLine(
                label: 'Components',
                value: _componentsText(spell),
              ),
              _SpellDetailLine(label: 'Notes', value: spell.note),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SpellDetailLine extends StatelessWidget {
  const _SpellDetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(value.trim().isEmpty ? '-' : value),
        ],
      ),
    );
  }
}

int _spellLevel(SpellNote spell) {
  final value = spell.spellLevel.trim().toLowerCase();
  if (value.isEmpty || value == 'cantrip') {
    return 0;
  }
  final level = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  if (level < 0) {
    return 0;
  }
  if (level > 9) {
    return 9;
  }
  return level;
}
