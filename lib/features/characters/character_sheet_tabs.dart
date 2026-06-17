import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_generator.dart';
import '../../core/utils/snackbars.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/reference_picker.dart';
import '../../data/models/app_models.dart';
import '../../data/models/reference_models.dart';
import '../../data/repositories/local_repositories.dart';
import 'character_avatar.dart';
import 'character_entry_dialogs.dart';
import 'character_reference_extractors.dart';
import 'character_rules.dart';
import 'characters_controller.dart';

part 'character_sheet_combat_tab.dart';
part 'character_sheet_shared_widgets.dart';
part 'character_sheet_inventory_widgets.dart';
part 'character_sheet_spell_tab.dart';

class CharacterSheetTabs extends ConsumerWidget {
  const CharacterSheetTabs({
    required this.character,
    required this.campaignId,
    this.controller,
    super.key,
  });

  final CharacterNote character;
  final String? campaignId;
  final TabController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtimeAsync = campaignId == null
        ? null
        : ref.watch(campaignCharacterStatesControllerProvider(campaignId!));
    final runtime = runtimeAsync?.maybeWhen(
          data: _runtimeFromStates,
          orElse: () => CampaignCharacterState.initial(
            campaignId: campaignId!,
            character: character,
          ),
        ) ??
        CampaignCharacterState.initial(
          campaignId: campaignId ?? '',
          character: character,
        );

    return TabBarView(
      controller: controller,
      children: [
        _BasicsTab(character: character),
        _CombatTab(
          character: character,
          campaignId: campaignId,
          runtime: runtime,
          loading: runtimeAsync?.isLoading ?? false,
        ),
        _SpellsTab(
          character: character,
          campaignId: campaignId,
          runtime: runtime,
        ),
        _AbilitiesTab(character: character),
        _InventoryTab(
          character: character,
          campaignId: campaignId,
          runtime: runtime,
        ),
      ],
    );
  }

  CampaignCharacterState _runtimeFromStates(List<CampaignCharacterState> states) {
    for (final state in states) {
      if (state.characterId == character.id) {
        return state;
      }
    }
    return CampaignCharacterState.initial(
      campaignId: campaignId!,
      character: character,
    );
  }
}

class _BasicsTab extends StatelessWidget {
  const _BasicsTab({required this.character});

  final CharacterNote character;

  @override
  Widget build(BuildContext context) {
    return _TabList(
      children: [
        _BasicsHero(character: character),
        _BasicsIdentityCard(character: character),
        _BasicsEntrySection(
          title: 'Class Features',
          entries: character.classFeatures,
        ),
        _BasicsEntrySection(
          title: 'Species Traits',
          entries: character.speciesTraits,
        ),
        _BasicsEntrySection(title: 'Feats', entries: character.feats),
        _TrainingSection(training: character.training),
        _EntrySection(
          title: 'Tool Proficiencies',
          entries: character.toolProficiencies,
        ),
        _EntrySection(title: 'Languages', entries: character.languages),
        if (character.personalityNotes.trim().isNotEmpty)
          _BackstoryCard(value: character.personalityNotes),
      ],
    );
  }
}

class _BasicsHero extends StatelessWidget {
  const _BasicsHero({required this.character});

  final CharacterNote character;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pronouns = character.pronouns.trim();
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          children: [
            CharacterAvatar(
              imagePath: character.profileImagePath,
              size: 164,
              borderRadius: 22,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LevelPill(level: character.level),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    character.name.trim().isEmpty
                        ? 'Unnamed Character'
                        : character.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              pronouns.isEmpty ? 'pronouns not set' : pronouns.toLowerCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'XP ${character.experiencePoints}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          'Lv $level',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _BasicsIdentityCard extends StatelessWidget {
  const _BasicsIdentityCard({required this.character});

  final CharacterNote character;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _IdentityRow('Species', character.ancestryOrSpecies),
            _IdentityRow('Class', character.className),
            if (character.subclassName.trim().isNotEmpty)
              _IdentityRow('Subclass', character.subclassName),
            _IdentityRow('Background', character.background),
            _IdentityRow('Size', character.size),
            _IdentityRow('Alignment', character.alignment),
          ],
        ),
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicsEntrySection extends StatelessWidget {
  const _BasicsEntrySection({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<CharacterListEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (entries.isEmpty)
          Text(
            'No entries yet.',
            style: TextStyle(color: colors.onSurfaceVariant),
          )
        else
          Column(
            children: [
              for (var index = 0; index < entries.length; index++) ...[
                _EntryListTile(entry: entries[index]),
                if (index < entries.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}

class _EntryListTile extends StatelessWidget {
  const _EntryListTile({required this.entry});

  final CharacterListEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = entry.quantity > 1
        ? '${entry.name} x${entry.quantity}'
        : entry.name;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.46),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.trim().isEmpty ? 'Unnamed' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                constraints:
                    const BoxConstraints.tightFor(width: 34, height: 34),
                padding: EdgeInsets.zero,
                tooltip: 'Details',
                icon: const Icon(Icons.info_outline, size: 18),
                onPressed: () => _showDetails(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.name.trim().isEmpty ? 'Details' : entry.name),
        content: SingleChildScrollView(
          child: Text(
            entry.description.trim().isEmpty
                ? 'No description noted.'
                : entry.description,
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

class _BackstoryCard extends StatelessWidget {
  const _BackstoryCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backstory',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(value),
        ],
      ),
    );
  }
}
class _AbilitiesTab extends StatelessWidget {
  const _AbilitiesTab({required this.character});

  final CharacterNote character;

  @override
  Widget build(BuildContext context) {
    return _TabList(
      children: [
        _Panel(
          title: 'Ability Scores',
          children: [
            _FactGrid(
              items: [
                for (final ability in abilityLabels.keys)
                  _Fact(
                    CharacterRules.abilityCode(ability),
                    _scoreText(CharacterRules.abilityScore(character, ability)),
                  ),
              ],
            ),
          ],
        ),
        for (final ability in abilityLabels.keys)
          _AbilityCheckPanel(character: character, ability: ability),
      ],
    );
  }

  String _scoreText(int score) {
    final modifier = CharacterRules.modifier(score);
    return '$score (${_signed(modifier)})';
  }
}

class _InventoryTab extends ConsumerWidget {
  const _InventoryTab({
    required this.character,
    required this.campaignId,
    required this.runtime,
  });

  final CharacterNote character;
  final String? campaignId;
  final CampaignCharacterState runtime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TabList(
      children: [
        _InventoryListPanel<CharacterWeapon>(
          title: 'Weapons',
          entries: character.weapons,
          emptyText: 'No weapons yet.',
          onSearch: () => _addWeaponFromDb(context, ref),
          onCustom: () => _editWeapon(context, ref),
          onIncrement: (index) => _updateWeaponQuantity(context, ref, index, 1),
          onDecrement: (index) => _updateWeaponQuantity(context, ref, index, -1),
          onEdit: (index) => _editWeapon(context, ref, index: index),
          onDelete: (index) => _deleteWeapon(context, ref, index),
          titleOf: (weapon) => weapon.name,
          quantityOf: (weapon) => weapon.quantity,
          subtitleOf: (weapon) => [
            if (weapon.attackLabel.isNotEmpty) 'ATK/DC ${weapon.attackLabel}',
            if (weapon.damageLabel.isNotEmpty) weapon.damageLabel,
          ].join(' - '),
          detailLinesOf: _weaponDetails,
          idOf: (weapon) => weapon.id,
          equippedId: _equippedWeaponId,
          onEquipChanged: (index, equipped) =>
              _setWeaponEquipped(context, ref, index, equipped),
        ),
        _InventoryListPanel<CharacterListEntry>(
          title: 'Armor',
          entries: character.armors,
          emptyText: 'No armor yet.',
          onSearch: () => _addEntryFromDb(
            context,
            ref,
            title: 'Pick Armor',
            filter: CharacterReferenceExtractors.isArmor,
            update: (entry) => character.copyWith(
              armors: [...character.armors, entry],
              selectedArmorIds: {...character.selectedArmorIds, entry.refId}.toList(),
              armorName: character.armors.isEmpty ? entry.name : null,
              armorRefId: character.armors.isEmpty ? entry.refId : null,
            ),
          ),
          onCustom: () => _editEntry(
            context,
            ref,
            title: 'Add Armor',
            entries: character.armors,
            save: (entries) => character.copyWith(armors: entries),
          ),
          onIncrement: (index) => _updateEntryQuantity(
            context,
            ref,
            character.armors,
            index,
            1,
            (entries) => character.copyWith(armors: entries),
          ),
          onDecrement: (index) => _updateEntryQuantity(
            context,
            ref,
            character.armors,
            index,
            -1,
            (entries) => character.copyWith(armors: entries),
          ),
          onEdit: (index) => _editEntry(
            context,
            ref,
            title: 'Edit Armor',
            entries: character.armors,
            index: index,
            save: (entries) => character.copyWith(armors: entries),
          ),
          onDelete: (index) => _deleteEntry(
            context,
            ref,
            character.armors,
            index,
            (entries) => character.copyWith(armors: entries),
          ),
          titleOf: (entry) => entry.name,
          quantityOf: (entry) => entry.quantity,
          subtitleOf: (_) => '',
          detailLinesOf: _entryDetails,
          idOf: (entry) => entry.id,
          equippedId: _equippedArmorId,
          onEquipChanged: (index, equipped) =>
              _setArmorEquipped(context, ref, index, equipped),
        ),
        _InventoryListPanel<CharacterListEntry>(
          title: 'Shields',
          entries: character.shields,
          emptyText: 'No shields yet.',
          onSearch: () => _addEntryFromDb(
            context,
            ref,
            title: 'Pick Shield',
            filter: CharacterReferenceExtractors.isShield,
            update: (entry) => character.copyWith(
              shields: [...character.shields, entry],
              selectedShieldIds:
                  {...character.selectedShieldIds, entry.refId}.toList(),
            ),
          ),
          onCustom: () => _editEntry(
            context,
            ref,
            title: 'Add Shield',
            entries: character.shields,
            save: (entries) => character.copyWith(shields: entries),
          ),
          onIncrement: (index) => _updateEntryQuantity(
            context,
            ref,
            character.shields,
            index,
            1,
            (entries) => character.copyWith(shields: entries),
          ),
          onDecrement: (index) => _updateEntryQuantity(
            context,
            ref,
            character.shields,
            index,
            -1,
            (entries) => character.copyWith(shields: entries),
          ),
          onEdit: (index) => _editEntry(
            context,
            ref,
            title: 'Edit Shield',
            entries: character.shields,
            index: index,
            save: (entries) => character.copyWith(shields: entries),
          ),
          onDelete: (index) => _deleteEntry(
            context,
            ref,
            character.shields,
            index,
            (entries) => character.copyWith(shields: entries),
          ),
          titleOf: (entry) => entry.name,
          quantityOf: (entry) => entry.quantity,
          subtitleOf: (_) => '',
          detailLinesOf: _entryDetails,
          idOf: (entry) => entry.id,
          equippedId: _equippedShieldId,
          onEquipChanged: (index, equipped) =>
              _setShieldEquipped(context, ref, index, equipped),
        ),
        _InventoryListPanel<CharacterListEntry>(
          title: 'Items',
          entries: character.gear,
          emptyText: 'No items yet.',
          onSearch: () => _addEntryFromDb(
            context,
            ref,
            title: 'Pick Item',
            filter: CharacterReferenceExtractors.isItem,
            update: (entry) => character.copyWith(
              gear: [...character.gear, entry],
              selectedGearIds: {...character.selectedGearIds, entry.refId}.toList(),
            ),
          ),
          onCustom: () => _editEntry(
            context,
            ref,
            title: 'Add Item',
            entries: character.gear,
            save: (entries) => character.copyWith(gear: entries),
          ),
          onIncrement: (index) => _updateEntryQuantity(
            context,
            ref,
            character.gear,
            index,
            1,
            (entries) => character.copyWith(gear: entries),
          ),
          onDecrement: (index) => _updateEntryQuantity(
            context,
            ref,
            character.gear,
            index,
            -1,
            (entries) => character.copyWith(gear: entries),
          ),
          onEdit: (index) => _editEntry(
            context,
            ref,
            title: 'Edit Item',
            entries: character.gear,
            index: index,
            save: (entries) => character.copyWith(gear: entries),
          ),
          onDelete: (index) => _deleteEntry(
            context,
            ref,
            character.gear,
            index,
            (entries) => character.copyWith(gear: entries),
          ),
          titleOf: (entry) => entry.name,
          quantityOf: (entry) => entry.quantity,
          subtitleOf: (_) => '',
          detailLinesOf: _entryDetails,
        ),
        _Panel(
          title: 'Coins',
          trailing: IconButton(
            tooltip: 'Edit coins',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editCoins(context, ref),
          ),
          children: [
            _FactGrid(
              items: [
                _Fact('CP', '${character.coins.cp}'),
                _Fact('SP', '${character.coins.sp}'),
                _Fact('EP', '${character.coins.ep}'),
                _Fact('GP', '${character.coins.gp}'),
                _Fact('PP', '${character.coins.pp}'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String get _equippedWeaponId =>
      campaignId == null ? character.equippedWeaponId : runtime.activeWeaponId;

  String get _equippedArmorId =>
      campaignId == null ? character.equippedArmorId : runtime.activeArmorId;

  String get _equippedShieldId =>
      campaignId == null ? character.equippedShieldId : runtime.activeShieldId;

  List<_InventoryDetailLine> _weaponDetails(CharacterWeapon weapon) {
    return [
      _InventoryDetailLine('Quantity', '${weapon.quantity}'),
      _InventoryDetailLine('ATK / DC', weapon.attackLabel),
      _InventoryDetailLine('Damage & Type', weapon.damageLabel),
      _InventoryDetailLine('Notes', weapon.description),
    ];
  }

  List<_InventoryDetailLine> _entryDetails(CharacterListEntry entry) {
    return [
      _InventoryDetailLine('Quantity', '${entry.quantity}'),
      _InventoryDetailLine('Description', entry.description),
    ];
  }

  Future<void> _addWeaponFromDb(BuildContext context, WidgetRef ref) async {
    final picked = await showReferencePicker(
      context,
      ref,
      type: ReferenceType.items,
      title: 'Pick Weapon',
      filter: CharacterReferenceExtractors.isWeapon,
    );
    if (picked == null || !context.mounted) {
      return;
    }
    final weapon = CharacterWeapon(
      id: IdGenerator.create(),
      refId: picked.id,
      name: picked.name,
      damageAndType: CharacterReferenceExtractors.damage(picked.description),
      description: picked.sourceLabel,
    );
    await _saveCharacter(
      context,
      ref,
      character.copyWith(
        weapons: [...character.weapons, weapon],
        selectedWeaponIds: {...character.selectedWeaponIds, picked.id}.toList(),
      ),
      campaignId,
      'Weapon added',
    );
  }

  Future<void> _editWeapon(
    BuildContext context,
    WidgetRef ref, {
    int? index,
  }) async {
    final weapon = await showCharacterWeaponDialog(
      context,
      existing: index == null ? null : character.weapons[index],
    );
    if (weapon == null || !context.mounted) {
      return;
    }
    final updated = List<CharacterWeapon>.of(character.weapons);
    if (index == null) {
      updated.add(weapon);
    } else {
      updated[index] = weapon;
    }
    await _saveCharacter(
      context,
      ref,
      character.copyWith(weapons: updated),
      campaignId,
      index == null ? 'Weapon added' : 'Weapon updated',
    );
  }

  Future<void> _updateWeaponQuantity(
    BuildContext context,
    WidgetRef ref,
    int index,
    int delta,
  ) async {
    final updated = List<CharacterWeapon>.of(character.weapons);
    final next = updated[index].quantity + delta;
    if (next < 1) {
      return;
    }
    updated[index] = updated[index].copyWith(quantity: next);
    await _saveCharacter(
      context,
      ref,
      character.copyWith(weapons: updated),
      campaignId,
      'Quantity updated',
      showSnack: false,
    );
  }

  Future<void> _deleteWeapon(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Remove Weapon',
      message: 'Remove ${character.weapons[index].name} from inventory?',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final updated = List<CharacterWeapon>.of(character.weapons)..removeAt(index);
    await _saveCharacter(
      context,
      ref,
      character.copyWith(weapons: updated),
      campaignId,
      'Weapon removed',
    );
  }

  Future<void> _setWeaponEquipped(
    BuildContext context,
    WidgetRef ref,
    int index,
    bool equipped,
  ) async {
    final id = equipped ? character.weapons[index].id : '';
    if (campaignId == null) {
      await _saveCharacter(
        context,
        ref,
        character.copyWith(equippedWeaponId: id),
        campaignId,
        equipped ? 'Weapon equipped' : 'Weapon unequipped',
        showSnack: false,
      );
      return;
    }
    await _saveRuntime(
      context,
      ref,
      runtime.copyWith(activeWeaponId: id),
      equipped ? 'Weapon equipped' : 'Weapon unequipped',
      showSnack: false,
    );
  }

  Future<void> _setArmorEquipped(
    BuildContext context,
    WidgetRef ref,
    int index,
    bool equipped,
  ) async {
    final armor = equipped ? character.armors[index] : null;
    if (campaignId == null) {
      await _saveCharacter(
        context,
        ref,
        character.copyWith(
          equippedArmorId: armor?.id ?? '',
          armorName: armor?.name ?? '',
          armorRefId: armor?.refId ?? '',
        ),
        campaignId,
        equipped ? 'Armor equipped' : 'Armor unequipped',
        showSnack: false,
      );
      return;
    }
    await _saveRuntime(
      context,
      ref,
      runtime.copyWith(
        activeArmorId: armor?.id ?? '',
        activeArmorName: armor?.name ?? '',
      ),
      equipped ? 'Armor equipped' : 'Armor unequipped',
      showSnack: false,
    );
  }

  Future<void> _setShieldEquipped(
    BuildContext context,
    WidgetRef ref,
    int index,
    bool equipped,
  ) async {
    final id = equipped ? character.shields[index].id : '';
    if (campaignId == null) {
      await _saveCharacter(
        context,
        ref,
        character.copyWith(
          equippedShieldId: id,
          shieldEquipped: id.isNotEmpty,
        ),
        campaignId,
        equipped ? 'Shield equipped' : 'Shield unequipped',
        showSnack: false,
      );
      return;
    }
    await _saveRuntime(
      context,
      ref,
      runtime.copyWith(
        activeShieldId: id,
        shieldEquipped: id.isNotEmpty,
      ),
      equipped ? 'Shield equipped' : 'Shield unequipped',
      showSnack: false,
    );
  }

  Future<void> _addEntryFromDb(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required bool Function(ReferenceEntry entry) filter,
    required CharacterNote Function(CharacterListEntry entry) update,
  }) async {
    final picked = await showReferencePicker(
      context,
      ref,
      type: ReferenceType.items,
      title: title,
      filter: filter,
    );
    if (picked == null || !context.mounted) {
      return;
    }
    await _saveCharacter(
      context,
      ref,
      update(
        CharacterListEntry(
          id: IdGenerator.create(),
          refId: picked.id,
          name: picked.name,
          description: picked.sourceLabel,
        ),
      ),
      campaignId,
      'Inventory updated',
    );
  }

  Future<void> _editEntry(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<CharacterListEntry> entries,
    required CharacterNote Function(List<CharacterListEntry> entries) save,
    int? index,
  }) async {
    final entry = await showCharacterEntryDialog(
      context,
      title: title,
      existing: index == null ? null : entries[index],
      quantity: true,
    );
    if (entry == null || !context.mounted) {
      return;
    }
    final updated = List<CharacterListEntry>.of(entries);
    if (index == null) {
      updated.add(entry);
    } else {
      updated[index] = entry;
    }
    await _saveCharacter(context, ref, save(updated), campaignId, 'Saved');
  }

  Future<void> _updateEntryQuantity(
    BuildContext context,
    WidgetRef ref,
    List<CharacterListEntry> entries,
    int index,
    int delta,
    CharacterNote Function(List<CharacterListEntry> entries) save,
  ) async {
    final updated = List<CharacterListEntry>.of(entries);
    final next = updated[index].quantity + delta;
    if (next < 1) {
      return;
    }
    updated[index] = updated[index].copyWith(quantity: next);
    await _saveCharacter(
      context,
      ref,
      save(updated),
      campaignId,
      'Quantity updated',
      showSnack: false,
    );
  }

  Future<void> _deleteEntry(
    BuildContext context,
    WidgetRef ref,
    List<CharacterListEntry> entries,
    int index,
    CharacterNote Function(List<CharacterListEntry> entries) save,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Remove Item',
      message: 'Remove ${entries[index].name} from inventory?',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final updated = List<CharacterListEntry>.of(entries)..removeAt(index);
    await _saveCharacter(context, ref, save(updated), campaignId, 'Removed');
  }

  Future<void> _editCoins(BuildContext context, WidgetRef ref) async {
    final coins = await showDialog<CharacterCoins>(
      context: context,
      builder: (context) => _CoinsDialog(initial: character.coins),
    );
    if (coins == null || !context.mounted) {
      return;
    }
    await _saveCharacter(
      context,
      ref,
      character.copyWith(coins: coins, coinsNotes: coins.label),
      campaignId,
      'Coins updated',
    );
  }

  Future<void> _saveRuntime(
    BuildContext context,
    WidgetRef ref,
    CampaignCharacterState next,
    String message, {
    bool showSnack = true,
  }
  ) async {
    if (campaignId == null) {
      return;
    }
    try {
      await ref
          .read(campaignCharacterStatesControllerProvider(campaignId!).notifier)
          .saveInPlace(next);
      if (showSnack && context.mounted) {
        showAppSnack(context, message);
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}

class _CoinsDialog extends StatefulWidget {
  const _CoinsDialog({required this.initial});

  final CharacterCoins initial;

  @override
  State<_CoinsDialog> createState() => _CoinsDialogState();
}

class _CoinsDialogState extends State<_CoinsDialog> {
  late final TextEditingController _cp;
  late final TextEditingController _sp;
  late final TextEditingController _ep;
  late final TextEditingController _gp;
  late final TextEditingController _pp;

  @override
  void initState() {
    super.initState();
    _cp = TextEditingController(text: '${widget.initial.cp}');
    _sp = TextEditingController(text: '${widget.initial.sp}');
    _ep = TextEditingController(text: '${widget.initial.ep}');
    _gp = TextEditingController(text: '${widget.initial.gp}');
    _pp = TextEditingController(text: '${widget.initial.pp}');
  }

  @override
  void dispose() {
    _cp.dispose();
    _sp.dispose();
    _ep.dispose();
    _gp.dispose();
    _pp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: const Text('Edit Coins'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            CharacterCoins(
              cp: _coinValue(_cp),
              sp: _coinValue(_sp),
              ep: _coinValue(_ep),
              gp: _coinValue(_gp),
              pp: _coinValue(_pp),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
      children: [
        _coinField(_cp, 'CP'),
        _coinField(_sp, 'SP'),
        _coinField(_ep, 'EP'),
        _coinField(_gp, 'GP'),
        _coinField(_pp, 'PP'),
      ],
    );
  }

  Widget _coinField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  int _coinValue(TextEditingController controller) {
    final value = int.tryParse(controller.text.trim()) ?? 0;
    return value < 0 ? 0 : value;
  }
}

class _AbilityCheckPanel extends StatelessWidget {
  const _AbilityCheckPanel({
    required this.character,
    required this.ability,
  });

  final CharacterNote character;
  final String ability;

  @override
  Widget build(BuildContext context) {
    final label = abilityLabels[ability] ?? ability;
    final modifier = CharacterRules.modifier(
      CharacterRules.abilityScore(character, ability),
    );
    final saveProficient =
        character.savingThrowProficiencies[label] == ProficiencyRank.proficient.name;
    final skills = skillAbilities.entries
        .where((entry) => entry.value == ability)
        .map((entry) => entry.key)
        .toList();

    return _Panel(
      title: label,
      children: [
        _CheckRow(
          name: 'Saving Throw',
          abilityCode: CharacterRules.abilityCode(ability),
          base: modifier,
          rank: saveProficient ? ProficiencyRank.proficient : ProficiencyRank.none,
          total: CharacterRules.savingThrowTotal(
            character,
            ability,
            saveProficient,
          ),
        ),
        const Divider(height: 16),
        for (final skill in skills) _SkillRow(character: character, skill: skill),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.character, required this.skill});

  final CharacterNote character;
  final String skill;

  @override
  Widget build(BuildContext context) {
    final ability = skillAbilities[skill] ?? 'strength';
    final rank = ProficiencyRank.values.firstWhere(
      (rank) => rank.name == character.skillProficiencies[skill],
      orElse: () => ProficiencyRank.none,
    );
    return _CheckRow(
      name: skill,
      abilityCode: CharacterRules.abilityCode(ability),
      base: CharacterRules.modifier(
        CharacterRules.abilityScore(character, ability),
      ),
      rank: rank,
      total: CharacterRules.skillTotal(character, skill, rank),
    );
  }
}

Future<void> _saveCharacter(
  BuildContext context,
  WidgetRef ref,
  CharacterNote character,
  String? campaignId,
  String message, {
  bool showSnack = true,
}
) async {
  try {
    final next = character.copyWith(updatedAt: DateTime.now());
    await ref.read(characterRepositoryProvider).save(next);
    ref.read(allCharactersControllerProvider.notifier).replaceLocal(next);
    if (campaignId != null) {
      ref
          .read(charactersControllerProvider(campaignId).notifier)
          .replaceLocal(next);
    }
    if (showSnack && context.mounted) {
      showAppSnack(context, message);
    }
  } catch (error) {
    if (context.mounted) {
      showAppSnack(context, error.toString(), isError: true);
    }
  }
}
