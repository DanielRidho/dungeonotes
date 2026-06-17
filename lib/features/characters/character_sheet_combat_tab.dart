part of 'character_sheet_tabs.dart';

const _conditionOptions = [
  'Blinded',
  'Charmed',
  'Deafened',
  'Frightened',
  'Incapacitated',
  'Invisible',
  'Paralyzed',
  'Petrified',
  'Poisoned',
  'Prone',
  'Restrained',
  'Stunned',
  'Unconscious',
];

class _CombatTab extends ConsumerWidget {
  const _CombatTab({
    required this.character,
    required this.campaignId,
    required this.runtime,
    required this.loading,
  });

  final CharacterNote character;
  final String? campaignId;
  final CampaignCharacterState runtime;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWeapon = _activeWeapon();
    final activeArmor = _activeArmor();
    final activeShield = _activeShield();
    final armorClass = runtime.armorClass <= 0
        ? character.armorClass
        : runtime.armorClass;
    final maxHp = character.hp <= 0 ? 1 : character.hp;
    final currentHp = runtime.currentHp.clamp(0, maxHp).toInt();
    final tempHp = runtime.temporaryHp < 0 ? 0 : runtime.temporaryHp;
    final tempHpMax = tempHp <= 0
        ? 0
        : runtime.temporaryHpMax < tempHp
            ? tempHp
            : runtime.temporaryHpMax;
    final showDeathSaves = runtime.currentHp <= 0 ||
        runtime.deathSaveSuccesses > 0 ||
        runtime.deathSaveFailures > 0;

    return _TabList(
      children: [
        if (loading) const LinearProgressIndicator(),
        _CombatVitalsCard(
          character: character,
          currentHp: currentHp,
          maxHp: maxHp,
          tempHp: tempHp,
          tempHpMax: tempHpMax,
        ),
        if (campaignId == null)
          const _CampaignOnlyHint()
        else
          _CombatActionPanel(
            hasTempHp: runtime.temporaryHp > 0,
            onDamage: () => _adjustHp(context, ref, false),
            onHeal: () => _adjustHp(context, ref, true),
            onTempHp: () => _setTempHp(context, ref),
            onClearTempHp: () => _save(
              context,
              ref,
              runtime.copyWith(temporaryHp: 0, temporaryHpMax: 0),
              'Temp HP cleared',
            ),
            onShortRest: () => _shortRest(context, ref),
            onLongRest: () => _longRest(context, ref),
          ),
        _CombatStatsCard(
          armorClass: armorClass,
          speed: character.speed,
          initiative: character.initiative,
          passivePerception: character.passivePerception,
          hitDice: character.hitDice,
          inspiration: runtime.inspiration,
          exhaustionLevel: runtime.exhaustionLevel.clamp(0, 6).toInt(),
          canEdit: campaignId != null,
          onEditArmorClass: () => _editArmorClass(context, ref),
          onToggleInspiration: () => _save(
            context,
            ref,
            runtime.copyWith(inspiration: !runtime.inspiration),
            'Inspiration updated',
          ),
          onEditExhaustion: () => _editExhaustion(context, ref),
        ),
        if (showDeathSaves)
          _DeathSavesCard(
            successes: runtime.deathSaveSuccesses,
            failures: runtime.deathSaveFailures,
            enabled: campaignId != null && runtime.currentHp <= 0,
            onSuccessChanged: (value) => _setDeathSaves(
              context,
              ref,
              successes: value,
              failures: runtime.deathSaveFailures,
            ),
            onFailureChanged: (value) => _setDeathSaves(
              context,
              ref,
              successes: runtime.deathSaveSuccesses,
              failures: value,
            ),
            onReset: campaignId == null
                ? null
                : () => _save(
                      context,
                      ref,
                      runtime.copyWith(
                        deathSaveSuccesses: 0,
                        deathSaveFailures: 0,
                      ),
                      'Death saves reset',
                    ),
          ),
        _ConditionsSection(
          conditions: runtime.conditions,
          canEdit: campaignId != null,
          onEdit: () => _editConditions(context, ref),
        ),
        _EquippedPanel(
          weapon: activeWeapon,
          armor: activeArmor,
          shield: activeShield,
        ),
      ],
    );
  }

  CharacterWeapon? _activeWeapon() {
    final activeId = _activeWeaponId();
    if (activeId.isEmpty) {
      return null;
    }
    for (final weapon in character.weapons) {
      if (weapon.id == activeId) {
        return weapon;
      }
    }
    return null;
  }

  CharacterListEntry? _activeArmor() {
    final activeId = _activeArmorId();
    if (activeId.isEmpty) {
      return null;
    }
    return _armorById(activeId);
  }

  CharacterListEntry? _activeShield() {
    final activeId = runtime.activeShieldId;
    if (activeId.isEmpty) {
      return null;
    }
    for (final shield in character.shields) {
      if (shield.id == activeId) {
        return shield;
      }
    }
    return null;
  }

  CharacterListEntry? _armorById(String id) {
    for (final armor in character.armors) {
      if (armor.id == id) {
        return armor;
      }
    }
    return null;
  }

  String _activeWeaponId() {
    for (final weapon in character.weapons) {
      if (weapon.id == runtime.activeWeaponId) {
        return weapon.id;
      }
    }
    return '';
  }

  String _activeArmorId() {
    for (final armor in character.armors) {
      if (armor.id == runtime.activeArmorId) {
        return armor.id;
      }
    }
    return '';
  }

  Future<void> _adjustHp(
    BuildContext context,
    WidgetRef ref,
    bool healing,
  ) async {
    final amount = await _numberDialog(
      context,
      title: healing ? 'Heal' : 'Damage',
      label: 'Amount',
    );
    if (amount == null || !context.mounted) {
      return;
    }

    var current = runtime.currentHp;
    var temp = runtime.temporaryHp;
    if (healing) {
      current = (current + amount).clamp(0, character.hp);
      await _save(
        context,
        ref,
        runtime.copyWith(
          currentHp: current,
          deathSaveSuccesses: 0,
          deathSaveFailures: 0,
          conditions: runtime.conditions
              .where((condition) => condition != 'Unconscious')
              .toList(),
        ),
        'HP restored',
      );
      return;
    }

    final absorbed = amount > temp ? temp : amount;
    temp -= absorbed;
    current = (current - (amount - absorbed)).clamp(0, character.hp);
    final tempMax = temp <= 0 ? 0 : runtime.temporaryHpMax;
    await _save(
      context,
      ref,
      runtime.copyWith(
        currentHp: current,
        temporaryHp: temp,
        temporaryHpMax: tempMax,
      ),
      'Damage applied',
    );
  }

  Future<void> _setTempHp(BuildContext context, WidgetRef ref) async {
    final amount = await _numberDialog(
      context,
      title: 'Temp HP',
      label: 'Temporary hit points',
    );
    if (amount == null || !context.mounted) {
      return;
    }
    await _save(
      context,
      ref,
      runtime.copyWith(temporaryHp: amount, temporaryHpMax: amount),
      'Temp HP updated',
    );
  }

  Future<void> _editArmorClass(BuildContext context, WidgetRef ref) async {
    final value = await _numberDialog(
      context,
      title: 'Armor Class',
      label: 'Current AC',
      initialValue:
          '${runtime.armorClass <= 0 ? character.armorClass : runtime.armorClass}',
    );
    if (value == null || !context.mounted) {
      return;
    }
    if (value < 1) {
      showAppSnack(context, 'AC must be at least 1.', isError: true);
      return;
    }
    await _save(
      context,
      ref,
      runtime.copyWith(armorClass: value),
      'AC updated',
    );
  }

  Future<void> _editExhaustion(BuildContext context, WidgetRef ref) async {
    var selected = runtime.exhaustionLevel.clamp(0, 6).toInt();
    final value = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Exhaustion Level'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var level = 0; level <= 6; level++)
                ChoiceChip(
                  label: Text('$level'),
                  selected: selected == level,
                  onSelected: (_) => setDialogState(() => selected = level),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (value == null || !context.mounted) {
      return;
    }
    await _save(
      context,
      ref,
      runtime.copyWith(exhaustionLevel: value),
      'Exhaustion updated',
    );
  }

  Future<void> _setDeathSaves(
    BuildContext context,
    WidgetRef ref, {
    required int successes,
    required int failures,
  }) {
    final nextSuccesses = successes.clamp(0, 3);
    final nextFailures = failures.clamp(0, 3);
    if (nextSuccesses >= 3) {
      return _save(
        context,
        ref,
        runtime.copyWith(
          currentHp: 1,
          deathSaveSuccesses: 0,
          deathSaveFailures: 0,
          conditions: {...runtime.conditions, 'Unconscious'}.toList(),
        ),
        'Death saves stabilized',
      );
    }
    return _save(
      context,
      ref,
      runtime.copyWith(
        deathSaveSuccesses: nextSuccesses,
        deathSaveFailures: nextFailures,
      ),
      'Death saves updated',
    );
  }

  Future<void> _shortRest(BuildContext context, WidgetRef ref) {
    return _save(
      context,
      ref,
      runtime.copyWith(
        deathSaveSuccesses: 0,
        deathSaveFailures: 0,
        notes: [
          runtime.notes,
          'Short rest: ${DateTime.now().toLocal()}',
        ].where((value) => value.trim().isNotEmpty).join('\n'),
      ),
      'Short rest noted',
    );
  }

  Future<void> _longRest(BuildContext context, WidgetRef ref) {
    return _save(
      context,
      ref,
      runtime.copyWith(
        currentHp: character.hp,
        temporaryHp: 0,
        temporaryHpMax: 0,
        deathSaveSuccesses: 0,
        deathSaveFailures: 0,
        conditions: const [],
        expendedSpellSlots: const {},
      ),
      'Long rest applied',
    );
  }

  Future<void> _editConditions(BuildContext context, WidgetRef ref) async {
    final selected = {...runtime.conditions};
    final value = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Conditions'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final condition in _conditionOptions)
                  FilterChip(
                    label: Text(condition),
                    selected: selected.contains(condition),
                    onSelected: (value) => setDialogState(() {
                      if (value) {
                        selected.add(condition);
                      } else {
                        selected.remove(condition);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                [
                  for (final condition in _conditionOptions)
                    if (selected.contains(condition)) condition,
                ],
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (value == null || !context.mounted) {
      return;
    }
    await _save(
      context,
      ref,
      runtime.copyWith(conditions: value),
      'Conditions updated',
    );
  }

  Future<int?> _numberDialog(
    BuildContext context, {
    required String title,
    required String label,
    String initialValue = '',
  }) {
    return showDialog<int>(
      context: context,
      builder: (context) => _NumberDialog(
        title: title,
        label: label,
        initialValue: initialValue,
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    CampaignCharacterState next,
    String message,
  ) async {
    if (campaignId == null) {
      return;
    }
    try {
      await ref
          .read(campaignCharacterStatesControllerProvider(campaignId!).notifier)
          .save(next);
      if (context.mounted) {
        showAppSnack(context, message);
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}

class _CombatVitalsCard extends StatelessWidget {
  const _CombatVitalsCard({
    required this.character,
    required this.currentHp,
    required this.maxHp,
    required this.tempHp,
    required this.tempHpMax,
  });

  final CharacterNote character;
  final int currentHp;
  final int maxHp;
  final int tempHp;
  final int tempHpMax;

  @override
  Widget build(BuildContext context) {
    final photoSize = MediaQuery.sizeOf(context).width < 360 ? 96.0 : 112.0;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CharacterAvatar(
              imagePath: character.profileImagePath,
              size: photoSize,
              borderRadius: 18,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  _CombatBar(
                    label: 'HP',
                    valueLabel: '$currentHp / $maxHp',
                    value: currentHp,
                    max: maxHp,
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 12),
                  _CombatBar(
                    label: 'Temp HP',
                    valueLabel: tempHp <= 0 ? '0' : '$tempHp / $tempHpMax',
                    value: tempHp,
                    max: tempHpMax,
                    color: const Color(0xFFFFD166),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CombatBar extends StatelessWidget {
  const _CombatBar({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final String valueLabel;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fill = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: colors.surfaceContainerHighest),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fill,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: color),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CampaignOnlyHint extends StatelessWidget {
  const _CampaignOnlyHint();

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Combat controls appear when this sheet is opened inside a campaign.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _CombatActionPanel extends StatelessWidget {
  const _CombatActionPanel({
    required this.hasTempHp,
    required this.onDamage,
    required this.onHeal,
    required this.onTempHp,
    required this.onClearTempHp,
    required this.onShortRest,
    required this.onLongRest,
  });

  final bool hasTempHp;
  final VoidCallback onDamage;
  final VoidCallback onHeal;
  final VoidCallback onTempHp;
  final VoidCallback onClearTempHp;
  final VoidCallback onShortRest;
  final VoidCallback onLongRest;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final topWidth = compact
                ? (constraints.maxWidth - 8) / 2
                : (constraints.maxWidth - 16) / 3;
            final restWidth = (constraints.maxWidth - 8) / 2;
            return Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: topWidth,
                      child: FilledButton.icon(
                        onPressed: onDamage,
                        icon: const Icon(Icons.flash_on_outlined),
                        label: const _ButtonLabel('DMG'),
                      ),
                    ),
                    SizedBox(
                      width: topWidth,
                      child: FilledButton.tonalIcon(
                        onPressed: onHeal,
                        icon: const Icon(Icons.favorite_outline),
                        label: const _ButtonLabel('HEAL'),
                      ),
                    ),
                    SizedBox(
                      width: topWidth,
                      child: OutlinedButton.icon(
                        onPressed: onTempHp,
                        icon: const Icon(Icons.health_and_safety_outlined),
                        label: const _ButtonLabel('TEMP HP'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: hasTempHp ? onClearTempHp : null,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const _ButtonLabel('Clear Temp HP'),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: restWidth,
                      child: FilledButton.tonalIcon(
                        onPressed: onShortRest,
                        icon: const Icon(Icons.chair_outlined),
                        label: const _ButtonLabel('Short Rest'),
                      ),
                    ),
                    SizedBox(
                      width: restWidth,
                      child: FilledButton.tonalIcon(
                        onPressed: onLongRest,
                        icon: const Icon(Icons.hotel_outlined),
                        label: const _ButtonLabel('Long Rest'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
    );
  }
}

class _CombatStatsCard extends StatelessWidget {
  const _CombatStatsCard({
    required this.armorClass,
    required this.speed,
    required this.initiative,
    required this.passivePerception,
    required this.hitDice,
    required this.inspiration,
    required this.exhaustionLevel,
    required this.canEdit,
    required this.onEditArmorClass,
    required this.onToggleInspiration,
    required this.onEditExhaustion,
  });

  final int armorClass;
  final int speed;
  final int initiative;
  final int passivePerception;
  final String hitDice;
  final bool inspiration;
  final int exhaustionLevel;
  final bool canEdit;
  final VoidCallback onEditArmorClass;
  final VoidCallback onToggleInspiration;
  final VoidCallback onEditExhaustion;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            _CombatStatRow(
              icon: Icons.shield_outlined,
              label: 'AC',
              value: '$armorClass',
              editable: canEdit,
              onTap: canEdit ? onEditArmorClass : null,
            ),
            _CombatStatRow(
              icon: Icons.directions_run_outlined,
              label: 'Speed',
              value: '${speed}ft',
            ),
            _CombatStatRow(
              icon: Icons.bolt_outlined,
              label: 'Initiative',
              value: _signed(initiative),
            ),
            _CombatStatRow(
              icon: Icons.visibility_outlined,
              label: 'Passive Perception',
              value: '$passivePerception',
            ),
            _CombatStatRow(
              icon: Icons.casino_outlined,
              label: 'Hit Dice',
              value: hitDice.trim().isEmpty ? '-' : hitDice,
            ),
            _CombatStatRow(
              icon: Icons.auto_awesome_outlined,
              label: 'Inspiration',
              value: inspiration ? 'Active' : 'Inactive',
              editable: canEdit,
              onTap: canEdit ? onToggleInspiration : null,
            ),
            _CombatStatRow(
              icon: Icons.warning_amber_outlined,
              label: 'Exhaustion',
              value: 'Level $exhaustionLevel',
              editable: canEdit,
              onTap: canEdit ? onEditExhaustion : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CombatStatRow extends StatelessWidget {
  const _CombatStatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.editable = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool editable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (editable) ...[
            const SizedBox(width: 6),
            Icon(Icons.edit_outlined, size: 15, color: colors.primary),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return row;
    }
    return InkWell(onTap: onTap, child: row);
  }
}

class _ConditionsSection extends StatelessWidget {
  const _ConditionsSection({
    required this.conditions,
    required this.canEdit,
    required this.onEdit,
  });

  final List<String> conditions;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Conditions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (canEdit)
                IconButton(
                  tooltip: 'Edit conditions',
                  color: colors.primary,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
            ],
          ),
          if (conditions.isEmpty)
            Text(
              'None',
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final condition in conditions) Chip(label: Text(condition)),
              ],
            ),
        ],
      ),
    );
  }
}

class _EquippedPanel extends StatelessWidget {
  const _EquippedPanel({
    required this.weapon,
    required this.armor,
    required this.shield,
  });

  final CharacterWeapon? weapon;
  final CharacterListEntry? armor;
  final CharacterListEntry? shield;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
            child: Text(
              'Equipped',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          _EquippedStatus(
            label: 'Weapon',
            value: weapon?.name ?? 'Unarmed',
            active: weapon != null,
            details: [
              if (weapon != null)
                'ATK / DC: ${weapon!.attackLabel.isEmpty ? '-' : weapon!.attackLabel}',
              if (weapon != null) 'Damage & Type: ${weapon!.damageLabel}',
            ],
          ),
          const SizedBox(height: 10),
          _EquippedStatus(
            label: 'Armor',
            value: armor?.name ?? 'No armor worn',
            active: armor != null,
          ),
          const SizedBox(height: 10),
          _EquippedStatus(
            label: 'Shield',
            value: shield?.name ?? 'No shield worn',
            active: shield != null,
          ),
        ],
      ),
    );
  }
}

class _EquippedStatus extends StatelessWidget {
  const _EquippedStatus({
    required this.label,
    required this.value,
    required this.active,
    this.details = const [],
  });

  final String label;
  final String value;
  final bool active;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 3),
                      Text(value),
                    ],
                  ),
                ),
                _MiniBadge(active ? 'Equipped' : 'None'),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final detail in details) _MiniBadge(detail),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeathSavesCard extends StatelessWidget {
  const _DeathSavesCard({
    required this.successes,
    required this.failures,
    required this.enabled,
    required this.onSuccessChanged,
    required this.onFailureChanged,
    required this.onReset,
  });

  final int successes;
  final int failures;
  final bool enabled;
  final ValueChanged<int> onSuccessChanged;
  final ValueChanged<int> onFailureChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Death Saves',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(onPressed: onReset, child: const Text('Reset')),
              ],
            ),
            const SizedBox(height: 6),
            _DeathSaveLine(
              label: 'Success',
              value: successes,
              enabled: enabled,
              onChanged: onSuccessChanged,
            ),
            const SizedBox(height: 8),
            _DeathSaveLine(
              label: 'Failure',
              value: failures,
              enabled: enabled,
              onChanged: onFailureChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeathSaveLine extends StatelessWidget {
  const _DeathSaveLine({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        for (var index = 1; index <= 3; index++) ...[
          _DeathDot(
            active: value >= index,
            enabled: enabled,
            onTap: () => onChanged(value == index ? index - 1 : index),
          ),
          if (index < 3) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _DeathDot extends StatelessWidget {
  const _DeathDot({
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active ? colors.primary : colors.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? colors.primary : colors.outline,
          ),
        ),
      ),
    );
  }
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.label,
    required this.initialValue,
  });

  final String title;
  final String label;
  final String initialValue;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _controller;
  String? _error;

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
      title: Text(widget.title),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('Apply'),
        ),
      ],
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _apply(),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(labelText: widget.label, errorText: _error),
        ),
      ],
    );
  }

  void _apply() {
    final amount = int.tryParse(_controller.text.trim());
    if (amount == null || amount < 0) {
      setState(() => _error = 'Enter a non-negative number');
      return;
    }
    Navigator.of(context).pop(amount);
  }
}
