import 'package:flutter/material.dart';

import '../../core/widgets/stat_input.dart';
import '../../data/models/app_models.dart';
import 'character_form_widgets.dart';
import 'character_list_editors.dart';
import 'character_rules.dart';

class CharacterBasicsSection extends StatelessWidget {
  const CharacterBasicsSection({
    super.key,
    required this.pronouns,
    required this.species,
    required this.className,
    required this.subclass,
    required this.background,
    required this.alignment,
    required this.size,
    required this.level,
    required this.onPickSpecies,
    required this.onPickClass,
    required this.onPickBackground,
    required this.onCustomSpecies,
    required this.onCustomClass,
    required this.onCustomBackground,
  });

  final TextEditingController pronouns;
  final TextEditingController species;
  final TextEditingController className;
  final TextEditingController subclass;
  final TextEditingController background;
  final TextEditingController alignment;
  final TextEditingController size;
  final int level;
  final VoidCallback onPickSpecies;
  final VoidCallback onPickClass;
  final VoidCallback onPickBackground;
  final VoidCallback onCustomSpecies;
  final VoidCallback onCustomClass;
  final VoidCallback onCustomBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionSelectCard(
          label: 'Pronouns',
          controller: pronouns,
          placeholder: 'Select pronouns',
          options: const ['he/him', 'she/her', 'they/them'],
          allowCustom: true,
        ),
        const SizedBox(height: 10),
        ReferenceSelectCard(
          label: 'Species',
          controller: species,
          placeholder: 'Select species',
          onSearch: onPickSpecies,
          onCustom: onCustomSpecies,
        ),
        const SizedBox(height: 10),
        ReferenceSelectCard(
          label: 'Class',
          controller: className,
          placeholder: 'Select class',
          onSearch: onPickClass,
          onCustom: onCustomClass,
        ),
        const SizedBox(height: 10),
        ReferenceSelectCard(
          label: 'Background',
          controller: background,
          placeholder: 'Select background',
          onSearch: onPickBackground,
          onCustom: onCustomBackground,
        ),
        const SizedBox(height: 10),
        SubclassSelectCard(controller: subclass, level: level),
        const SizedBox(height: 10),
        OptionSelectCard(
          label: 'Size',
          controller: size,
          placeholder: 'Select size',
          options: const ['Tiny', 'Small', 'Medium', 'Large', 'Huge'],
        ),
        const SizedBox(height: 10),
        OptionSelectCard(
          label: 'Alignment',
          controller: alignment,
          placeholder: 'Select alignment',
          options: const [
            'Lawful Good',
            'Neutral Good',
            'Chaotic Good',
            'Lawful Neutral',
            'True Neutral',
            'Chaotic Neutral',
            'Lawful Evil',
            'Neutral Evil',
            'Chaotic Evil',
            'Unaligned',
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class CharacterProgressionSection extends StatelessWidget {
  const CharacterProgressionSection({
    super.key,
    required this.level,
    required this.xp,
    required this.maxHp,
    required this.hitDice,
    required this.onLevelChanged,
    required this.onHitDiceChanged,
  });

  final int level;
  final TextEditingController xp;
  final TextEditingController maxHp;
  final TextEditingController hitDice;
  final ValueChanged<int> onLevelChanged;
  final ValueChanged<String> onHitDiceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LevelProficiencyCard(
          level: level,
          proficiencyBonus: CharacterRules.proficiencyBonus(level),
          onLevelChanged: onLevelChanged,
        ),
        const SizedBox(height: 10),
        StatInput(
          controller: xp,
          label: 'XP',
          hint: '0',
          requiredField: true,
        ),
        const SizedBox(height: 10),
        StatInput(
          controller: maxHp,
          label: 'Max HP',
          hint: 'Required',
          requiredField: true,
        ),
        const SizedBox(height: 10),
        OptionSelectCard(
          label: 'Hit Dice',
          controller: hitDice,
          placeholder: 'Select hit dice',
          options: hitDiceOptions,
          onChanged: onHitDiceChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class CharacterAbilitiesSection extends StatelessWidget {
  const CharacterAbilitiesSection({
    super.key,
    required this.str,
    required this.dex,
    required this.con,
    required this.intScore,
    required this.wis,
    required this.cha,
    required this.skillProficiencies,
    required this.savingThrowProficiencies,
    required this.previewCharacter,
    required this.abilityPool,
    required this.onAbilityPoolChanged,
    required this.onAbilityAssigned,
    required this.onSkillsChanged,
    required this.onSavesChanged,
  });

  final TextEditingController str;
  final TextEditingController dex;
  final TextEditingController con;
  final TextEditingController intScore;
  final TextEditingController wis;
  final TextEditingController cha;
  final Map<String, String> skillProficiencies;
  final Map<String, String> savingThrowProficiencies;
  final CharacterNote previewCharacter;
  final List<int> abilityPool;
  final ValueChanged<List<int>> onAbilityPoolChanged;
  final void Function(TextEditingController controller, int? score)
      onAbilityAssigned;
  final ValueChanged<Map<String, String>> onSkillsChanged;
  final ValueChanged<Map<String, String>> onSavesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormSubheading('Ability Scores'),
        const SizedBox(height: 8),
        AbilityAssignmentPanel(
          controllers: [str, dex, con, intScore, wis, cha],
          pool: abilityPool,
          onPoolChanged: onAbilityPoolChanged,
          onAssign: onAbilityAssigned,
        ),
        const SizedBox(height: 12),
        TwoColumn(
          children: [
            AbilityScoreField(controller: str, label: 'Strength'),
            AbilityScoreField(controller: dex, label: 'Dexterity'),
            AbilityScoreField(controller: con, label: 'Constitution'),
            AbilityScoreField(controller: intScore, label: 'Intelligence'),
            AbilityScoreField(controller: wis, label: 'Wisdom'),
            AbilityScoreField(controller: cha, label: 'Charisma'),
          ],
        ),
        const SizedBox(height: 18),
        const _FormSubheading('Skill Checks & Saving Throws'),
        const SizedBox(height: 8),
        AbilityProficiencyPanel(
          character: previewCharacter,
          skillValues: skillProficiencies,
          savingThrowValues: savingThrowProficiencies,
          onSkillsChanged: onSkillsChanged,
          onSavesChanged: onSavesChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _FormSubheading extends StatelessWidget {
  const _FormSubheading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class CharacterEquipmentSection extends StatelessWidget {
  const CharacterEquipmentSection({
    super.key,
    required this.armors,
    required this.shields,
    required this.weapons,
    required this.gear,
    required this.cp,
    required this.sp,
    required this.ep,
    required this.gp,
    required this.pp,
    required this.training,
    required this.onAddArmorFromDb,
    required this.onAddCustomArmor,
    required this.onEditArmor,
    required this.onDeleteArmor,
    required this.onAddShieldFromDb,
    required this.onAddCustomShield,
    required this.onEditShield,
    required this.onDeleteShield,
    required this.onAddWeaponFromDb,
    required this.onAddCustomWeapon,
    required this.onEditWeapon,
    required this.onDeleteWeapon,
    required this.onAddGearFromDb,
    required this.onAddCustomGear,
    required this.onEditGear,
    required this.onDeleteGear,
    required this.onTrainingChanged,
  });

  final List<CharacterListEntry> armors;
  final List<CharacterListEntry> shields;
  final List<CharacterWeapon> weapons;
  final List<CharacterListEntry> gear;
  final TextEditingController cp;
  final TextEditingController sp;
  final TextEditingController ep;
  final TextEditingController gp;
  final TextEditingController pp;
  final CharacterTraining training;
  final VoidCallback onAddArmorFromDb;
  final VoidCallback onAddCustomArmor;
  final ValueChanged<int> onEditArmor;
  final ValueChanged<int> onDeleteArmor;
  final VoidCallback onAddShieldFromDb;
  final VoidCallback onAddCustomShield;
  final ValueChanged<int> onEditShield;
  final ValueChanged<int> onDeleteShield;
  final VoidCallback onAddWeaponFromDb;
  final VoidCallback onAddCustomWeapon;
  final ValueChanged<int> onEditWeapon;
  final ValueChanged<int> onDeleteWeapon;
  final VoidCallback onAddGearFromDb;
  final VoidCallback onAddCustomGear;
  final ValueChanged<int> onEditGear;
  final ValueChanged<int> onDeleteGear;
  final ValueChanged<CharacterTraining> onTrainingChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Armor', style: Theme.of(context).textTheme.titleSmall),
            ),
            TextButton.icon(
              onPressed: onAddArmorFromDb,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
            TextButton.icon(
              onPressed: onAddCustomArmor,
              icon: const Icon(Icons.add),
              label: const Text('Custom'),
            ),
          ],
        ),
        EntryListEditor(
          title: '',
          emptyText: 'No armor yet.',
          entries: armors,
          onAdd: onAddCustomArmor,
          onEdit: onEditArmor,
          onDelete: onDeleteArmor,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child:
                  Text('Shields', style: Theme.of(context).textTheme.titleSmall),
            ),
            TextButton.icon(
              onPressed: onAddShieldFromDb,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
            TextButton.icon(
              onPressed: onAddCustomShield,
              icon: const Icon(Icons.add),
              label: const Text('Custom'),
            ),
          ],
        ),
        EntryListEditor(
          title: '',
          emptyText: 'No shields yet.',
          entries: shields,
          onAdd: onAddCustomShield,
          onEdit: onEditShield,
          onDelete: onDeleteShield,
        ),
        const SizedBox(height: 12),
        WeaponListEditor(
          weapons: weapons,
          onAddFromDb: onAddWeaponFromDb,
          onAddCustom: onAddCustomWeapon,
          onEdit: onEditWeapon,
          onDelete: onDeleteWeapon,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text('Items', style: Theme.of(context).textTheme.titleSmall),
            ),
            TextButton.icon(
              onPressed: onAddGearFromDb,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
            TextButton.icon(
              onPressed: onAddCustomGear,
              icon: const Icon(Icons.add),
              label: const Text('Custom'),
            ),
          ],
        ),
        EntryListEditor(
          title: '',
          emptyText: 'No items yet.',
          entries: gear,
          onAdd: onAddCustomGear,
          onEdit: onEditGear,
          onDelete: onDeleteGear,
        ),
        const SizedBox(height: 12),
        Text('Coins', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        CoinsInput(cp: cp, sp: sp, ep: ep, gp: gp, pp: pp),
        const SizedBox(height: 12),
        TrainingToggles(training: training, onChanged: onTrainingChanged),
        const SizedBox(height: 12),
      ],
    );
  }
}

class CharacterNotesSection extends StatelessWidget {
  const CharacterNotesSection({
    super.key,
    required this.armorClass,
    required this.speed,
    required this.classFeatures,
    required this.speciesTraits,
    required this.feats,
    required this.toolProficiencies,
    required this.languages,
    required this.backstory,
    required this.onAddClassFeature,
    required this.onEditClassFeature,
    required this.onDeleteClassFeature,
    required this.onAddSpeciesTrait,
    required this.onEditSpeciesTrait,
    required this.onDeleteSpeciesTrait,
    required this.onAddFeat,
    required this.onEditFeat,
    required this.onDeleteFeat,
    required this.onAddTool,
    required this.onEditTool,
    required this.onDeleteTool,
    required this.onAddLanguage,
    required this.onEditLanguage,
    required this.onDeleteLanguage,
  });

  final TextEditingController armorClass;
  final TextEditingController speed;
  final List<CharacterListEntry> classFeatures;
  final List<CharacterListEntry> speciesTraits;
  final List<CharacterListEntry> feats;
  final List<CharacterListEntry> toolProficiencies;
  final List<CharacterListEntry> languages;
  final TextEditingController backstory;
  final VoidCallback onAddClassFeature;
  final ValueChanged<int> onEditClassFeature;
  final ValueChanged<int> onDeleteClassFeature;
  final VoidCallback onAddSpeciesTrait;
  final ValueChanged<int> onEditSpeciesTrait;
  final ValueChanged<int> onDeleteSpeciesTrait;
  final VoidCallback onAddFeat;
  final ValueChanged<int> onEditFeat;
  final ValueChanged<int> onDeleteFeat;
  final VoidCallback onAddTool;
  final ValueChanged<int> onEditTool;
  final ValueChanged<int> onDeleteTool;
  final VoidCallback onAddLanguage;
  final ValueChanged<int> onEditLanguage;
  final ValueChanged<int> onDeleteLanguage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TwoColumn(
          children: [
            StatInput(
              controller: armorClass,
              label: 'Armor Class',
              hint: 'Required',
              requiredField: true,
            ),
            StatInput(
              controller: speed,
              label: 'Speed',
              hint: 'Required',
              requiredField: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        EntryListEditor(
          title: 'Class Features',
          addLabel: 'Add feature',
          entries: classFeatures,
          onAdd: onAddClassFeature,
          onEdit: onEditClassFeature,
          onDelete: onDeleteClassFeature,
        ),
        const SizedBox(height: 12),
        EntryListEditor(
          title: 'Species Traits',
          addLabel: 'Add trait',
          entries: speciesTraits,
          onAdd: onAddSpeciesTrait,
          onEdit: onEditSpeciesTrait,
          onDelete: onDeleteSpeciesTrait,
        ),
        const SizedBox(height: 12),
        EntryListEditor(
          title: 'Feats',
          addLabel: 'Add feat',
          entries: feats,
          onAdd: onAddFeat,
          onEdit: onEditFeat,
          onDelete: onDeleteFeat,
        ),
        const SizedBox(height: 12),
        EntryListEditor(
          title: 'Tool Proficiencies',
          addLabel: 'Add tool',
          entries: toolProficiencies,
          onAdd: onAddTool,
          onEdit: onEditTool,
          onDelete: onDeleteTool,
        ),
        const SizedBox(height: 12),
        EntryListEditor(
          title: 'Languages',
          addLabel: 'Add language',
          entries: languages,
          onAdd: onAddLanguage,
          onEdit: onEditLanguage,
          onDelete: onDeleteLanguage,
        ),
        const SizedBox(height: 12),
        BackstoryEditCard(controller: backstory),
        const SizedBox(height: 12),
      ],
    );
  }
}

class CharacterSpellSection extends StatelessWidget {
  const CharacterSpellSection({
    super.key,
    required this.spells,
    required this.preparedMax,
    required this.slotControllers,
    required this.level,
    required this.spellcastingAbility,
    required this.abilityScore,
    required this.onSpellcastingChanged,
    required this.onSearch,
    required this.onAddCustom,
    required this.onEdit,
    required this.onRemove,
  });

  final List<SpellNote> spells;
  final TextEditingController preparedMax;
  final List<TextEditingController> slotControllers;
  final int level;
  final String spellcastingAbility;
  final String abilityScore;
  final ValueChanged<String> onSpellcastingChanged;
  final VoidCallback onSearch;
  final VoidCallback onAddCustom;
  final void Function({int? index}) onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final spellRows = [
      for (var i = 0; i < spells.length; i++) (index: i, spell: spells[i]),
    ]..sort((a, b) {
        final level = _spellLevelNumber(a.spell).compareTo(
          _spellLevelNumber(b.spell),
        );
        if (level != 0) {
          return level;
        }
        return a.spell.spellName.compareTo(b.spell.spellName);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpellcastingSetupPanel(
          value: spellcastingAbility,
          level: level,
          abilityScore: abilityScore,
          onChanged: onSpellcastingChanged,
        ),
        const SizedBox(height: 12),
        SpellLimitsPanel(
          preparedMax: preparedMax,
          slotControllers: slotControllers,
        ),
        const SizedBox(height: 12),
        _SpellBookPanel(
          spellRows: spellRows,
          levelOf: _spellLevelNumber,
          onSearch: onSearch,
          onAddCustom: onAddCustom,
          onEdit: onEdit,
          onRemove: onRemove,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  int _spellLevelNumber(SpellNote spell) {
    final value = spell.spellLevel.trim().toLowerCase();
    if (value.isEmpty || value == 'cantrip') {
      return 0;
    }
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}

class _SpellBookPanel extends StatelessWidget {
  const _SpellBookPanel({
    required this.spellRows,
    required this.levelOf,
    required this.onSearch,
    required this.onAddCustom,
    required this.onEdit,
    required this.onRemove,
  });

  final List<({int index, SpellNote spell})> spellRows;
  final int Function(SpellNote spell) levelOf;
  final VoidCallback onSearch;
  final VoidCallback onAddCustom;
  final void Function({int? index}) onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.34),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Spellbook',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                TextButton(onPressed: onSearch, child: const Text('Search')),
                TextButton(onPressed: onAddCustom, child: const Text('Custom')),
              ],
            ),
            if (spellRows.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 6, 4),
                child: Text(
                  'No spell notes yet.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              )
            else
              for (var level = 0; level <= 9; level++)
                _SpellLevelGroup(
                  level: level,
                  rows: [
                    for (final row in spellRows)
                      if (levelOf(row.spell) == level) row,
                  ],
                  onEdit: onEdit,
                  onRemove: onRemove,
                ),
          ],
        ),
      ),
    );
  }
}

class _SpellLevelGroup extends StatelessWidget {
  const _SpellLevelGroup({
    required this.level,
    required this.rows,
    required this.onEdit,
    required this.onRemove,
  });

  final int level;
  final List<({int index, SpellNote spell})> rows;
  final void Function({int? index}) onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            level == 0 ? 'Cantrips' : 'Level $level',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          for (final row in rows)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_stories_outlined),
              title: Text(row.spell.spellName),
              subtitle: Text(
                [
                  if (row.spell.castingTime.isNotEmpty)
                    row.spell.castingTime,
                  if (row.spell.range.isNotEmpty) row.spell.range,
                  if (row.spell.components.isNotEmpty)
                    row.spell.components.join('/'),
                  if (row.spell.note.isNotEmpty) row.spell.note,
                ].join(' - '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Edit spell',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => onEdit(index: row.index),
                  ),
                  IconButton(
                    tooltip: 'Remove spell',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onRemove(row.index),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
