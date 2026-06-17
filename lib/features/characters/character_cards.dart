import 'package:flutter/material.dart';

import '../../data/models/app_models.dart';
import 'character_avatar.dart';
import 'character_rules.dart';

class CharacterSummarySliverGrid extends StatelessWidget {
  const CharacterSummarySliverGrid({
    required this.characters,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
    this.onExport,
    this.onExportJson,
    this.onUnlink,
  });

  final List<CharacterNote> characters;
  final ValueChanged<CharacterNote> onTap;
  final ValueChanged<CharacterNote> onEdit;
  final ValueChanged<CharacterNote> onDelete;
  final ValueChanged<CharacterNote>? onExport;
  final ValueChanged<CharacterNote>? onExportJson;
  final ValueChanged<CharacterNote>? onUnlink;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.crossAxisExtent < 300 ? 1 : 2;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final character = characters[index];
                return CharacterSummaryCard(
                  character: character,
                  onTap: () => onTap(character),
                  onEdit: () => onEdit(character),
                  onDelete: () => onDelete(character),
                  onExport: onExport == null
                      ? null
                      : () => onExport?.call(character),
                  onExportJson: onExportJson == null
                      ? null
                      : () => onExportJson?.call(character),
                  onUnlink: onUnlink == null
                      ? null
                      : () => onUnlink?.call(character),
                );
              },
              childCount: characters.length,
            ),
          ),
        );
      },
    );
  }
}

class CharacterSummaryCard extends StatelessWidget {
  const CharacterSummaryCard({
    required this.character,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
    this.onExport,
    this.onExportJson,
    this.onUnlink,
  });

  final CharacterNote character;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onExport;
  final VoidCallback? onExportJson;
  final VoidCallback? onUnlink;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageSize = (constraints.maxWidth - 18)
                  .clamp(84.0, constraints.maxHeight * 0.5)
                  .toDouble();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _CharacterMenu(
                      onEdit: onEdit,
                      onDelete: onDelete,
                      onExport: onExport,
                      onExportJson: onExportJson,
                      onUnlink: onUnlink,
                    ),
                  ),
                  Center(
                    child: CharacterAvatar(
                      imagePath: character.profileImagePath,
                      size: imageSize,
                      borderRadius: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              character.name.isEmpty
                                  ? 'Unnamed'
                                  : character.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            _CharacterMetaLine(character: character),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _LevelBadge(level: character.level),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          'Lv $level',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _CharacterMetaLine extends StatelessWidget {
  const _CharacterMetaLine({required this.character});

  final CharacterNote character;

  @override
  Widget build(BuildContext context) {
    final values = [
      if (character.ancestryOrSpecies.trim().isNotEmpty)
        character.ancestryOrSpecies.trim(),
      if (character.className.trim().isNotEmpty) character.className.trim(),
      if (character.background.trim().isNotEmpty) character.background.trim(),
    ];
    if (values.isEmpty) {
      return Text(
        'No details',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          for (var index = 0; index < values.length; index++) ...[
            if (index > 0)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _MetaDot(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            TextSpan(text: values[index]),
          ],
        ],
      ),
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class CharacterSheetCard extends StatelessWidget {
  const CharacterSheetCard({
    required this.character,
    required this.onEdit,
    required this.onDelete,
    super.key,
    this.onExport,
    this.onExportJson,
    this.onUnlink,
  });

  final CharacterNote character;
  final VoidCallback onEdit;
  final VoidCallback? onExport;
  final VoidCallback? onExportJson;
  final VoidCallback? onUnlink;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        [
                          if (character.pronouns.isNotEmpty)
                            character.pronouns,
                          'Level ${character.level}',
                        ].join(' / '),
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _CharacterMenu(
                  onEdit: onEdit,
                  onDelete: onDelete,
                  onExport: onExport,
                  onExportJson: onExportJson,
                  onUnlink: onUnlink,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SheetPanel(
              title: 'Overview',
              children: [
                _InfoTile(label: 'Species', value: character.ancestryOrSpecies),
                _InfoTile(label: 'Class', value: character.className),
                _InfoTile(label: 'Subclass', value: character.subclassName),
                _InfoTile(label: 'Background', value: character.background),
                _InfoTile(label: 'Size', value: character.size),
                _InfoTile(label: 'Alignment', value: character.alignment),
              ],
            ),
            const SizedBox(height: 12),
            _SheetPanel(
              title: 'Combat',
              children: [
                _InfoTile(label: 'AC', value: '${character.armorClass}'),
                _InfoTile(
                  label: 'Armor',
                  value: _formatEntries(character.armors),
                ),
                _InfoTile(
                  label: 'Shield',
                  value: _equippedEntryName(
                    character.shields,
                    character.equippedShieldId,
                    fallback: character.shieldEquipped ? 'Shield equipped' : '',
                  ),
                ),
                _InfoTile(
                  label: 'Prof',
                  value: '+${CharacterRules.proficiencyBonus(character.level)}',
                ),
                _InfoTile(label: 'Initiative', value: '${character.initiative}'),
                _InfoTile(label: 'Speed', value: '${character.speed}'),
                _InfoTile(label: 'Max HP', value: '${character.hp}'),
                _InfoTile(label: 'Hit Dice', value: character.hitDice),
                _InfoTile(
                  label: 'Passive',
                  value: '${character.passivePerception}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SheetPanel(
              title: 'Abilities',
              children: [
                _InfoTile(label: 'STR', value: _scoreText(character.strength)),
                _InfoTile(label: 'DEX', value: _scoreText(character.dexterity)),
                _InfoTile(label: 'CON', value: _scoreText(character.constitution)),
                _InfoTile(label: 'INT', value: _scoreText(character.intelligence)),
                _InfoTile(label: 'WIS', value: _scoreText(character.wisdom)),
                _InfoTile(label: 'CHA', value: _scoreText(character.charisma)),
              ],
            ),
            _OptionalTextSection(
              title: 'Skill Proficiencies',
              value: _formatProficiencies(character.skillProficiencies),
            ),
            _OptionalTextSection(
              title: 'Saving Throw Proficiencies',
              value: _formatProficiencies(
                character.savingThrowProficiencies,
                allowExpertise: false,
              ),
            ),
            _OptionalTextSection(
              title: 'Attacks & Actions',
              value: character.weapons.isEmpty
                  ? character.attackNotes
                  : _formatWeapons(character.weapons),
            ),
            _OptionalTextSection(
              title: 'Armor',
              value: _formatEntries(character.armors),
            ),
            _OptionalTextSection(
              title: 'Shields',
              value: _formatEntries(character.shields),
            ),
            _OptionalTextSection(
              title: 'Features & Traits',
              value: _formatEntries([
                ...character.classFeatures,
                ...character.speciesTraits,
                ...character.feats,
              ], fallback: character.featureNotes),
            ),
            _OptionalTextSection(
              title: 'Inventory',
              value: _formatEntries(character.gear, fallback: character.inventoryNotes),
            ),
            _OptionalTextSection(title: 'Coins', value: character.coins.label),
            _OptionalTextSection(
              title: 'Training',
              value: character.training.labels.join('\n'),
            ),
            _OptionalTextSection(
              title: 'Tools',
              value: _formatEntries(character.toolProficiencies),
            ),
            _OptionalTextSection(
              title: 'Languages',
              value: _formatEntries(
                character.languages,
                fallback: character.toolAndLanguageNotes,
              ),
            ),
            _OptionalTextSection(
              title: 'Backstory & Notes',
              value: character.personalityNotes,
            ),
            const Divider(height: 24),
            Text('Spellcasting', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _SpellcastingChips(character: character),
            if (character.spellNotes.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Spell Notes', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              for (final spell in character.spellNotes)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: Text(spell.spellName),
                  subtitle: Text(
                    [
                      if (spell.spellLevel.isNotEmpty)
                        'Level ${spell.spellLevel}',
                      if (spell.castingTime.isNotEmpty) spell.castingTime,
                      if (spell.range.isNotEmpty) spell.range,
                      if (spell.components.isNotEmpty)
                        spell.components.join('/'),
                      if (spell.note.isNotEmpty) spell.note,
                    ].join(' - '),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _scoreText(int score) {
    final modifier = CharacterRules.modifier(score);
    return '$score (${modifier >= 0 ? '+' : ''}$modifier)';
  }

  static String _formatProficiencies(
    Map<String, String> values, {
    bool allowExpertise = true,
  }) {
    if (values.isEmpty) {
      return '';
    }
    return values.entries.map((entry) {
      var rank = ProficiencyRank.values.firstWhere(
        (rank) => rank.name == entry.value,
        orElse: () => ProficiencyRank.none,
      );
      if (!allowExpertise && rank == ProficiencyRank.expertise) {
        rank = ProficiencyRank.proficient;
      }
      return '${entry.key}: ${rank.label}';
    }).join('\n');
  }

  static String _formatWeapons(List<CharacterWeapon> weapons) {
    return weapons.map((weapon) {
      final attack = weapon.attackLabel.isEmpty ? '' : ' - ${weapon.attackLabel}';
      final damage = weapon.damageLabel.isEmpty ? '' : ': ${weapon.damageLabel}';
      final note = weapon.description.isEmpty ? '' : ' - ${weapon.description}';
      final quantity = weapon.quantity > 1 ? ' x${weapon.quantity}' : '';
      return '${weapon.name}$quantity$damage$attack$note';
    }).join('\n');
  }

  static String _formatEntries(
    List<CharacterListEntry> entries, {
    String fallback = '',
  }) {
    if (entries.isEmpty) {
      return fallback;
    }
    return entries.map((entry) {
      if (entry.description.isEmpty) {
        return entry.quantity > 1 ? '${entry.name} x${entry.quantity}' : entry.name;
      }
      final name = entry.quantity > 1 ? '${entry.name} x${entry.quantity}' : entry.name;
      return '$name: ${entry.description}';
    }).join('\n');
  }

  static String _equippedEntryName(
    List<CharacterListEntry> entries,
    String id, {
    String fallback = '',
  }) {
    for (final entry in entries) {
      if (entry.id == id) {
        return entry.name;
      }
    }
    return fallback;
  }
}

class _CharacterMenu extends StatelessWidget {
  const _CharacterMenu({
    required this.onEdit,
    required this.onDelete,
    this.onExport,
    this.onExportJson,
    this.onUnlink,
  });

  final VoidCallback onEdit;
  final VoidCallback? onExport;
  final VoidCallback? onExportJson;
  final VoidCallback? onUnlink;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      child: const SizedBox.square(
        dimension: 32,
        child: Icon(Icons.more_vert, size: 20),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        }
        if (value == 'export') {
          onExport?.call();
        }
        if (value == 'exportJson') {
          onExportJson?.call();
        }
        if (value == 'unlink') {
          onUnlink?.call();
        }
        if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        if (onExport != null)
          const PopupMenuItem(
            value: 'export',
            child: Text('Export to character sheets'),
          ),
        if (onExportJson != null)
          const PopupMenuItem(
            value: 'exportJson',
            child: Text('Export JSON'),
          ),
        if (onUnlink != null)
          const PopupMenuItem(
            value: 'unlink',
            child: Text('Remove from campaign'),
          ),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}

class _SheetPanel extends StatelessWidget {
  const _SheetPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: children),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionalTextSection extends StatelessWidget {
  const _OptionalTextSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}

class _SpellcastingChips extends StatelessWidget {
  const _SpellcastingChips({required this.character});

  final CharacterNote character;

  @override
  Widget build(BuildContext context) {
    final abilityName =
        abilityLabels[character.spellcastingAbility] ?? 'Wisdom';
    final abilityScore =
        CharacterRules.abilityScore(character, character.spellcastingAbility);
    final modifier = CharacterRules.modifier(abilityScore);
    final attackBonus = CharacterRules.spellAttackBonus(
      character,
      character.spellcastingAbility,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(label: Text('$abilityName ${modifier >= 0 ? '+' : ''}$modifier')),
        Chip(
          label: Text(
            'Save DC ${CharacterRules.spellSaveDc(character, character.spellcastingAbility)}',
          ),
        ),
        Chip(label: Text('Attack ${attackBonus >= 0 ? '+' : ''}$attackBonus')),
        if (character.spellcastingSetup.preparedMax > 0)
          Chip(
            label: Text(
              'Prepared max ${character.spellcastingSetup.preparedMax}',
            ),
          ),
        for (final entry in character.spellcastingSetup.slotTotals.entries)
          if (entry.value > 0) Chip(label: Text('L${entry.key} slots ${entry.value}')),
      ],
    );
  }
}
