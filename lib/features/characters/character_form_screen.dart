import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/snackbars.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/reference_picker.dart';
import '../../data/models/app_models.dart';
import '../../data/models/reference_models.dart';
import '../../data/repositories/local_repositories.dart';
import '../dice_roller/dice_launcher.dart';
import 'character_draft_factory.dart';
import 'character_entry_dialogs.dart';
import 'character_form_mappers.dart';
import 'character_form_photo_picker.dart';
import 'character_form_sections.dart';
import 'character_reference_extractors.dart';
import 'character_rules.dart';
import 'characters_controller.dart';
import 'spell_note_dialog.dart';

part 'character_form_builder.dart';

Future<void> showCharacterForm(
  BuildContext context,
  WidgetRef ref, {
  String? campaignId,
  CharacterNote? existing,
}) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CharacterFormScreen(
        campaignId: campaignId,
        existing: existing,
      ),
    ),
  );
  if (!context.mounted || saved != true) {
    return;
  }

  if (campaignId != null) {
    ref.invalidate(charactersControllerProvider(campaignId));
  }
  ref.invalidate(allCharactersControllerProvider);
  showAppSnack(
    context,
    existing == null ? 'Character sheet added' : 'Character sheet saved',
  );
}

class CharacterFormScreen extends ConsumerStatefulWidget {
  const CharacterFormScreen({
    super.key,
    this.campaignId,
    this.existing,
  });

  final String? campaignId;
  final CharacterNote? existing;

  @override
  ConsumerState<CharacterFormScreen> createState() =>
      _CharacterFormScreenState();
}

class _CharacterFormScreenState extends ConsumerState<CharacterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final String _draftId;
  late final TextEditingController _name, _pronouns, _species, _className;
  late final TextEditingController _subclass, _background, _alignment;
  late final TextEditingController _xp, _maxHp, _hitDice, _ac, _size, _speed;
  late final TextEditingController _str, _dex, _con, _int, _wis, _cha;
  late final TextEditingController _cp, _sp, _ep, _gp, _pp;
  late final TextEditingController _preparedSpellMax, _backstory;
  late final List<TextEditingController> _spellSlotTotals;

  late List<SpellNote> _spells;
  late List<CharacterWeapon> _weapons;
  late List<CharacterListEntry> _armors, _shields, _gear;
  late List<CharacterListEntry> _classFeatures, _speciesTraits, _feats;
  late List<CharacterListEntry> _toolProficiencies, _languages;
  late CharacterTraining _training;
  late String _speciesRefId, _classRefId, _backgroundRefId;
  late String _profileImagePath, _spellcastingAbility;
  late int _level;
  late Map<String, String> _skillProficiencies, _savingThrowProficiencies;
  late List<String> _selectedWeaponIds, _selectedArmorIds, _selectedShieldIds;
  late List<String> _selectedGearIds, _selectedSpellIds;
  late List<int> _abilityPool;
  var _stepIndex = 0;
  var _stepDirection = 1;
  var _dirty = false;

  static const _stepLabels = [
    'Basics',
    'Level',
    'Abilities',
    'Inventory',
    'Features',
    'Spells',
  ];

  @override
  void initState() {
    super.initState();
    final character = widget.existing;
    _draftId = character?.id ?? IdGenerator.create();
    _name = TextEditingController(text: character?.name ?? '');
    _pronouns = TextEditingController(text: character?.pronouns ?? '');
    _species = TextEditingController(text: character?.ancestryOrSpecies ?? '');
    _className = TextEditingController(text: character?.className ?? '');
    _subclass = TextEditingController(text: character?.subclassName ?? '');
    _background = TextEditingController(text: character?.background ?? '');
    _alignment = TextEditingController(text: character?.alignment ?? '');
    _xp = TextEditingController(text: character == null ? '' : '${character.experiencePoints}');
    _maxHp = TextEditingController(
      text: character == null || character.hp <= 0 ? '' : '${character.hp}',
    );
    _hitDice = TextEditingController(text: character?.hitDice ?? '');
    _ac = TextEditingController(text: character == null ? '' : '${character.armorClass}');
    _size = TextEditingController(text: character?.size ?? '');
    _speed = TextEditingController(text: character == null ? '' : '${character.speed}');
    _str = TextEditingController(text: character == null ? '' : '${character.strength}');
    _dex = TextEditingController(text: character == null ? '' : '${character.dexterity}');
    _con = TextEditingController(text: character == null ? '' : '${character.constitution}');
    _int = TextEditingController(text: character == null ? '' : '${character.intelligence}');
    _wis = TextEditingController(text: character == null ? '' : '${character.wisdom}');
    _cha = TextEditingController(text: character == null ? '' : '${character.charisma}');
    final coins = character?.coins ?? const CharacterCoins();
    _cp = TextEditingController(text: character == null ? '' : '${coins.cp}');
    _sp = TextEditingController(text: character == null ? '' : '${coins.sp}');
    _ep = TextEditingController(text: character == null ? '' : '${coins.ep}');
    _gp = TextEditingController(text: character == null ? '' : '${coins.gp}');
    _pp = TextEditingController(text: character == null ? '' : '${coins.pp}');
    final spellcasting =
        character?.spellcastingSetup ?? const CharacterSpellcastingSetup();
    _preparedSpellMax =
        TextEditingController(text: character == null ? '' : '${spellcasting.preparedMax}');
    _spellSlotTotals = [
      for (var level = 1; level <= 9; level++)
        TextEditingController(
          text: character == null ? '' : '${spellcasting.slotTotal(level)}',
        ),
    ];
    _backstory = TextEditingController(text: character?.personalityNotes ?? '');
    _spells = List.of(character?.spellNotes ?? const []);
    _weapons = List.of(character?.weapons ?? const []);
    _armors = List.of(character?.armors ?? const []);
    _shields = List.of(character?.shields ?? const []);
    _gear = List.of(character?.gear ?? const []);
    _classFeatures = List.of(character?.classFeatures ?? const []);
    _speciesTraits = List.of(character?.speciesTraits ?? const []);
    _feats = List.of(character?.feats ?? const []);
    _toolProficiencies = List.of(character?.toolProficiencies ?? const []);
    _languages = List.of(character?.languages ?? const []);
    _training = character?.training ?? const CharacterTraining();
    _speciesRefId = character?.speciesRefId ?? '';
    _classRefId = character?.classRefId ?? '';
    _backgroundRefId = character?.backgroundRefId ?? '';
    _profileImagePath = character?.profileImagePath ?? '';
    _level = (character?.level ?? 1).clamp(1, 20);
    _spellcastingAbility = character?.spellcastingAbility ?? 'wisdom';
    _skillProficiencies = Map.of(character?.skillProficiencies ?? const {});
    _savingThrowProficiencies =
        Map.of(character?.savingThrowProficiencies ?? const {});
    _selectedWeaponIds = List.of(character?.selectedWeaponIds ?? const []);
    _selectedArmorIds = List.of(character?.selectedArmorIds ?? const []);
    _selectedShieldIds = List.of(character?.selectedShieldIds ?? const []);
    _selectedGearIds = List.of(character?.selectedGearIds ?? const []);
    _selectedSpellIds = List.of(character?.selectedSpellIds ?? const []);
    _abilityPool = const [];
    for (final controller in _controllers) {
      controller.addListener(_markDirty);
    }
    _hydrateLegacyStructuredFields(character);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers => [
        _name,
        _pronouns,
        _species,
        _className,
        _subclass,
        _background,
        _alignment,
        _xp,
        _maxHp,
        _hitDice,
        _ac,
        _size,
        _speed,
        _str,
        _dex,
        _con,
        _int,
        _wis,
        _cha,
        _cp,
        _sp,
        _ep,
        _gp,
        _pp,
        _preparedSpellMax,
        ..._spellSlotTotals,
        _backstory,
      ];

  void _markDirty() {
    _dirty = true;
  }

  void _updateForm(VoidCallback update) => setState(update);

  void _hydrateLegacyStructuredFields(CharacterNote? character) {
    if (character == null) {
      return;
    }
    if (_weapons.isEmpty && character.attackNotes.trim().isNotEmpty) {
      _weapons = legacyCharacterEntries(character.attackNotes)
          .map((entry) => CharacterWeapon(id: entry.id, name: entry.name))
          .toList();
    }
    if (_gear.isEmpty && character.inventoryNotes.trim().isNotEmpty) {
      _gear = legacyCharacterEntries(character.inventoryNotes);
    }
    if (_classFeatures.isEmpty && character.featureNotes.trim().isNotEmpty) {
      _classFeatures = legacyCharacterEntries(character.featureNotes);
    }
    final toolNotes = character.toolAndLanguageNotes.trim();
    if (_toolProficiencies.isEmpty && toolNotes.isNotEmpty) {
      _toolProficiencies = legacyCharacterEntries(toolNotes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final discard = await _confirmDiscard();
        if (discard && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: DiceDraggableLauncher(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.existing == null ? 'New Character' : 'Edit Character',
            ),
            actions: [
              TextButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _FormStepPicker(
                      labels: _stepLabels,
                      currentIndex: _stepIndex,
                      onChanged: _goToStep,
                    ),
                    Expanded(
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          reverseDuration: const Duration(milliseconds: 240),
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          transitionBuilder: (child, animation) {
                            final key = child.key;
                            final isIncoming = key is ValueKey<int> &&
                                key.value == _stepIndex;
                            final direction = _stepDirection.toDouble();
                            final begin = Offset(
                              isIncoming ? direction : -direction,
                              0,
                            );
                            final curved = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                              reverseCurve: Curves.easeInCubic,
                            );
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: begin,
                                end: Offset.zero,
                              ).animate(curved),
                              child: child,
                            );
                          },
                          child: ListView(
                            key: ValueKey(_stepIndex),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            children: [_buildStepContent()],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: _FormNavigation(
                        isFirst: _stepIndex == 0,
                        isLast: _stepIndex == _stepLabels.length - 1,
                        onBack: _previousStep,
                        onNext: _nextStep,
                      ),
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

  Future<void> _pickSpeciesFromDb() async {
    final picked = await showReferencePicker(
      context,
      ref,
      type: ReferenceType.species,
      title: 'Pick Species',
    );
    if (picked != null) {
      _pickSpecies(picked);
    }
  }

  Future<void> _pickClassFromDb() async {
    final picked = await showReferencePicker(
      context,
      ref,
      type: ReferenceType.classes,
      title: 'Pick Class',
    );
    if (picked != null) {
      _pickClass(picked);
    }
  }

  Future<void> _pickBackgroundFromDb() async {
    final picked = await showReferencePicker(
      context,
      ref,
      type: ReferenceType.backgrounds,
      title: 'Pick Background',
    );
    if (picked != null) {
      _pickIdentity(
        picked,
        controller: _background,
        refSetter: (id) => _backgroundRefId = id,
      );
    }
  }

  Future<void> _customIdentity({
    required String title,
    required TextEditingController controller,
    required VoidCallback clearRef,
  }) async {
    final value = await showTextValueDialog(
      context,
      title: title,
      label: 'Name',
      initialValue: controller.text,
    );
    if (value == null || value.isEmpty) {
      return;
    }
    setState(() {
      _dirty = true;
      controller.text = value;
      clearRef();
    });
  }

  void _pickIdentity(
    ReferenceEntry entry, {
    required TextEditingController controller,
    required ValueChanged<String> refSetter,
  }) {
    setState(() {
      _dirty = true;
      controller.text = entry.name;
      refSetter(entry.id);
    });
  }

  void _pickSpecies(ReferenceEntry entry) {
    setState(() {
      _dirty = true;
      _species.text = entry.name;
      _speciesRefId = entry.id;
      final parsedSpeed = CharacterReferenceExtractors.speed(entry.description);
      if (parsedSpeed != null) {
        _speed.text = '$parsedSpeed';
      }
      final parsedSize = CharacterReferenceExtractors.size(entry.description);
      if (parsedSize.isNotEmpty) {
        _size.text = parsedSize;
      }
    });
  }

  void _pickClass(ReferenceEntry entry) {
    setState(() {
      _dirty = true;
      _className.text = entry.name;
      _classRefId = entry.id;
      final hitDie = CharacterReferenceExtractors.hitDie(entry.description);
      if (hitDie.isNotEmpty) {
        _hitDice.text = hitDie;
      }
      final ability =
          CharacterReferenceExtractors.spellcastingAbility(entry.description);
      if (ability.isNotEmpty) {
        _spellcastingAbility = ability;
      }
    });
  }

  void _setLevel(int value) => setState(() { _dirty = true; _level = value; });

  void _setHitDice(String value) =>
      setState(() { _dirty = true; _hitDice.text = value; });

  Future<void> _addArmorFromDb() async {
    final picked = await _pickInventoryEntry(
      title: 'Pick Armor',
      filter: CharacterReferenceExtractors.isArmor,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dirty = true;
      _selectedArmorIds = {..._selectedArmorIds, picked.refId}.toList();
      _armors.add(picked.entry);
    });
  }

  Future<void> _addShieldFromDb() async {
    final picked = await _pickInventoryEntry(
      title: 'Pick Shield',
      filter: CharacterReferenceExtractors.isShield,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dirty = true;
      _selectedShieldIds = {..._selectedShieldIds, picked.refId}.toList();
      _shields.add(picked.entry);
    });
  }

  Future<void> _addWeaponFromDb() async {
    final picked = await showReferencePicker(
      context,
      ref,
      type: ReferenceType.items,
      title: 'Pick Weapon',
      filter: CharacterReferenceExtractors.isWeapon,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dirty = true;
      _selectedWeaponIds = {..._selectedWeaponIds, picked.id}.toList();
      _weapons.add(
        CharacterWeapon(
          id: IdGenerator.create(),
          refId: picked.id,
          name: picked.name,
          damageAndType: CharacterReferenceExtractors.damage(picked.description),
          description: picked.sourceLabel,
          quantity: 1,
        ),
      );
    });
  }

  Future<void> _editWeapon({int? index}) async {
    final weapon = await showCharacterWeaponDialog(
      context,
      existing: index == null ? null : _weapons[index],
    );
    if (weapon == null) {
      return;
    }
    setState(() {
      _dirty = true;
      if (index == null) {
        _weapons.add(weapon);
      } else {
        _weapons[index] = weapon;
      }
    });
  }

  Future<void> _addGearFromDb() async {
    final picked = await _pickInventoryEntry(
      title: 'Pick Item',
      filter: CharacterReferenceExtractors.isItem,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dirty = true;
      _selectedGearIds = {..._selectedGearIds, picked.refId}.toList();
      _gear.add(picked.entry);
    });
  }

  Future<({CharacterListEntry entry, String refId})?> _pickInventoryEntry({
    required String title,
    required bool Function(ReferenceEntry entry) filter,
  }) async {
    final picked = await showReferencePicker(
      context,
      ref,
      type: ReferenceType.items,
      title: title,
      filter: filter,
    );
    if (picked == null) {
      return null;
    }
    return (
      refId: picked.id,
      entry: CharacterListEntry(
        id: IdGenerator.create(),
        refId: picked.id,
        name: picked.name,
        description: picked.sourceLabel,
        quantity: 1,
      ),
    );
  }

  Future<void> _editEntry(
    List<CharacterListEntry> entries, {
    int? index,
    required String title,
    bool description = true,
    bool quantity = false,
  }) async {
    final entry = await showCharacterEntryDialog(
      context,
      title: title,
      existing: index == null ? null : entries[index],
      description: description,
      quantity: quantity,
    );
    if (entry == null) {
      return;
    }
    setState(() {
      _dirty = true;
      if (index == null) {
        entries.add(entry);
      } else {
        entries[index] = entry;
      }
    });
  }

  void _removeAt<T>(List<T> values, int index) {
    if (index < 0 || index >= values.length) {
      return;
    }
    setState(() {
      _dirty = true;
      values.removeAt(index);
    });
  }

  Future<void> _pickSpell() async {
    final picked = await showReferencePicker(
      context,
      ref,
      type: ReferenceType.spells,
      title: 'Pick Spell',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dirty = true;
      _selectedSpellIds = {..._selectedSpellIds, picked.id}.toList();
      _spells.add(
        SpellNote(
          spellName: picked.name,
          spellLevel: picked.property('Level'),
          prepared: false,
          castingTime: picked.property('Casting Time'),
          range: picked.property('Range'),
          components: spellComponentsFromEntry(picked),
          note: [
            if (picked.property('School').isNotEmpty) picked.property('School'),
          ].join(' - '),
        ),
      );
    });
  }

  Future<void> _editSpell({int? index}) async {
    final existing = index == null ? null : _spells[index];
    final spell = await showSpellNoteDialog(context, existing: existing);
    if (spell == null) {
      return;
    }
    setState(() {
      _dirty = true;
      if (index == null) {
        _spells.add(spell);
      } else {
        _spells[index] = spell;
      }
    });
  }

  CharacterNote _previewCharacter() {
    return createCharacterDraft(campaignId: widget.campaignId).copyWith(
      level: _level,
      strength: _toInt(_str, 10),
      dexterity: _toInt(_dex, 10),
      constitution: _toInt(_con, 10),
      intelligence: _toInt(_int, 10),
      wisdom: _toInt(_wis, 10),
      charisma: _toInt(_cha, 10),
      shieldEquipped: false,
      spellcastingAbility: _spellcastingAbility,
    );
  }

  Future<bool> _confirmDiscard() {
    if (!_dirty) {
      return Future.value(true);
    }
    return ConfirmDialog.show(
      context,
      title: 'Discard changes?',
      message: 'Your unsaved character sheet edits will be lost.',
      confirmLabel: 'Discard',
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? true)) {
      return;
    }
    final validationError = _validateRequiredFields();
    if (validationError != null) {
      _goToStep(validationError.step);
      showAppSnack(context, validationError.message, isError: true);
      return;
    }

    final base = widget.existing ?? createCharacterDraft(campaignId: widget.campaignId)
        .copyWith(id: _draftId);
    final campaignIds = {
      ...base.campaignIds,
      if (widget.campaignId != null) widget.campaignId!,
    }.toList();
    final maxHp = _toInt(_maxHp, 0);
    final preview = _previewCharacter();
    final perceptionRank = _rankFromName(_skillProficiencies['Perception']);
    final coins = _coinsValue();
    final spellcastingSetup = _spellcastingSetupValue();
    final primaryArmor = _armors.isEmpty ? null : _armors.first;
    final equippedWeaponId = keptWeaponId(_weapons, base.equippedWeaponId);
    final equippedArmorId = keptEntryId(_armors, base.equippedArmorId);
    final equippedShieldId = keptEntryId(_shields, base.equippedShieldId);
    final character = base.copyWith(
      campaignIds: campaignIds,
      name: _name.text.trim(),
      playerName: '',
      pronouns: _pronouns.text.trim(),
      ancestryOrSpecies: _species.text.trim(),
      className: _className.text.trim(),
      profileImagePath: _profileImagePath,
      speciesRefId: _speciesRefId,
      classRefId: _classRefId,
      backgroundRefId: _backgroundRefId,
      subclassName: _level >= 3 ? _subclass.text.trim() : '',
      subclassRefId: '',
      level: _level,
      background: _background.text.trim(),
      alignment: _alignment.text.trim(),
      experiencePoints: _toInt(_xp, 0),
      proficiencyBonus: CharacterRules.proficiencyBonus(_level),
      hp: maxHp,
      currentHp: widget.existing == null ? maxHp : base.currentHp,
      temporaryHp: widget.existing == null ? 0 : base.temporaryHp,
      hitDice: _hitDice.text.trim(),
      deathSaveSuccesses: widget.existing == null ? 0 : base.deathSaveSuccesses,
      deathSaveFailures: widget.existing == null ? 0 : base.deathSaveFailures,
      armorClass: _toInt(_ac, 10),
      armorRefId: primaryArmor?.refId ?? '',
      armorName: primaryArmor?.name ?? '',
      shieldEquipped: equippedShieldId.isNotEmpty,
      equippedWeaponId: equippedWeaponId,
      equippedArmorId: equippedArmorId,
      equippedShieldId: equippedShieldId,
      size: _size.text.trim(),
      speed: _toInt(_speed, 30),
      initiative: CharacterRules.modifier(_toInt(_dex, 10)),
      passivePerception:
          10 + CharacterRules.skillTotal(preview, 'Perception', perceptionRank),
      strength: _toInt(_str, 10),
      dexterity: _toInt(_dex, 10),
      constitution: _toInt(_con, 10),
      intelligence: _toInt(_int, 10),
      wisdom: _toInt(_wis, 10),
      charisma: _toInt(_cha, 10),
      attackNotes: characterWeaponSummary(_weapons),
      featureNotes: characterEntrySummary([
        ..._classFeatures,
        ..._speciesTraits,
        ..._feats,
      ]),
      skillNotes: '',
      savingThrowNotes: '',
      inventoryNotes: characterEntrySummary(_gear),
      treasureNotes: '',
      toolAndLanguageNotes: characterEntrySummary([
        ..._toolProficiencies,
        ..._languages,
      ]),
      personalityNotes: _backstory.text.trim(),
      skillProficiencies: _skillProficiencies,
      savingThrowProficiencies: _savingThrowProficiencies,
      selectedWeaponIds: _selectedWeaponIds,
      selectedArmorIds: _selectedArmorIds,
      selectedShieldIds: _selectedShieldIds,
      selectedGearIds: _selectedGearIds,
      selectedSpellIds: _selectedSpellIds,
      spellcastingAbility: _spellcastingAbility,
      coinsNotes: coins.label,
      weapons: _weapons,
      armors: _armors,
      shields: _shields,
      gear: _gear,
      treasures: const [],
      classFeatures: _classFeatures,
      speciesTraits: _speciesTraits,
      feats: _feats,
      toolProficiencies: _toolProficiencies,
      languages: _languages,
      coins: coins,
      training: _training,
      spellcastingSetup: spellcastingSetup,
      spellNotes: sortSpellNotes(_spells),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(characterRepositoryProvider).save(character);
      if (mounted) {
        _dirty = false;
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  ({String message, int step})? _validateRequiredFields() {
    for (final field in [
      ('Character name', _name, 0),
      ('Pronouns', _pronouns, 0),
      ('Species', _species, 0),
      ('Class', _className, 0),
      ('Background', _background, 0),
      ('Alignment', _alignment, 0),
      ('Size', _size, 0),
      ('XP', _xp, 1),
      ('Max HP', _maxHp, 1),
      ('Hit dice', _hitDice, 1),
      ('Strength', _str, 2),
      ('Dexterity', _dex, 2),
      ('Constitution', _con, 2),
      ('Intelligence', _int, 2),
      ('Wisdom', _wis, 2),
      ('Charisma', _cha, 2),
      ('Armor Class', _ac, 4),
      ('Speed', _speed, 4),
    ]) {
      final message = _requiredNumberError(field.$1, field.$2);
      if (message != null) {
        return (message: message, step: field.$3);
      }
    }
    if (_level >= 3 && _subclass.text.trim().isEmpty) {
      return (message: 'Please fill Subclass.', step: 0);
    }
    return null;
  }

  String? _requiredNumberError(
    String label,
    TextEditingController controller,
  ) {
    final text = controller.text.trim();
    if (text.isEmpty) {
      return 'Please fill $label.';
    }
    if (_numericRequiredLabels.contains(label) && int.tryParse(text) == null) {
      return '$label must be a number.';
    }
    if (_numericRequiredLabels.contains(label) &&
        (int.tryParse(text) ?? 0) < 0) {
      return '$label cannot be negative.';
    }
    if (_positiveRequiredLabels.contains(label) &&
        (int.tryParse(text) ?? 0) < 1) {
      return '$label must be at least 1.';
    }
    return null;
  }

  static const _numericRequiredLabels = {
    'XP',
    'Max HP',
    'Strength',
    'Dexterity',
    'Constitution',
    'Intelligence',
    'Wisdom',
    'Charisma',
    'Armor Class',
    'Speed',
  };

  static const _positiveRequiredLabels = {
    'Max HP',
    'Strength',
    'Dexterity',
    'Constitution',
    'Intelligence',
    'Wisdom',
    'Charisma',
    'Armor Class',
    'Speed',
  };

  CharacterCoins _coinsValue() {
    return CharacterCoins(
      cp: _toInt(_cp, 0),
      sp: _toInt(_sp, 0),
      ep: _toInt(_ep, 0),
      gp: _toInt(_gp, 0),
      pp: _toInt(_pp, 0),
    );
  }

  CharacterSpellcastingSetup _spellcastingSetupValue() {
    return CharacterSpellcastingSetup(
      preparedMax: _toInt(_preparedSpellMax, 0),
      slotTotals: {
        for (var i = 0; i < _spellSlotTotals.length; i++)
          i + 1: _toInt(_spellSlotTotals[i], 0),
      },
    );
  }

  int _toInt(TextEditingController controller, int fallback) {
    final value = int.tryParse(controller.text.trim()) ?? fallback;
    return value < 0 ? fallback : value;
  }

  ProficiencyRank _rankFromName(String? value) =>
      ProficiencyRank.values.firstWhere(
        (rank) => rank.name == value,
        orElse: () => ProficiencyRank.none,
      );
}
