part of 'character_form_screen.dart';

extension _CharacterFormBuilder on _CharacterFormScreenState {
  Widget _buildStepContent() {
    return switch (_stepIndex) {
      0 => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CharacterFormPhotoPicker(
              characterId: _draftId,
              imagePath: _profileImagePath,
              name: _name,
              onChanged: (path) => _updateForm(() {
                _dirty = true;
                _profileImagePath = path;
              }),
            ),
            const SizedBox(height: 12),
            CharacterBasicsSection(
              pronouns: _pronouns,
              species: _species,
              className: _className,
              subclass: _subclass,
              background: _background,
              alignment: _alignment,
              size: _size,
              level: _level,
              onPickSpecies: _pickSpeciesFromDb,
              onPickClass: _pickClassFromDb,
              onPickBackground: _pickBackgroundFromDb,
              onCustomSpecies: () => _customIdentity(
                title: 'Custom Species',
                controller: _species,
                clearRef: () => _speciesRefId = '',
              ),
              onCustomClass: () => _customIdentity(
                title: 'Custom Class',
                controller: _className,
                clearRef: () => _classRefId = '',
              ),
              onCustomBackground: () => _customIdentity(
                title: 'Custom Background',
                controller: _background,
                clearRef: () => _backgroundRefId = '',
              ),
            ),
          ],
        ),
      1 => CharacterProgressionSection(
          level: _level,
          xp: _xp,
          maxHp: _maxHp,
          hitDice: _hitDice,
          onLevelChanged: _setLevel,
          onHitDiceChanged: _setHitDice,
        ),
      2 => CharacterAbilitiesSection(
          str: _str,
          dex: _dex,
          con: _con,
          intScore: _int,
          wis: _wis,
          cha: _cha,
          skillProficiencies: _skillProficiencies,
          savingThrowProficiencies: _savingThrowProficiencies,
          previewCharacter: _previewCharacter(),
          abilityPool: _abilityPool,
          onAbilityPoolChanged: (values) => _updateForm(() {
            _dirty = true;
            _abilityPool = values;
          }),
          onAbilityAssigned: (controller, score) => _updateForm(() {
            _dirty = true;
            controller.text = score == null ? '' : '$score';
          }),
          onSkillsChanged: (values) => _updateForm(() {
            _dirty = true;
            _skillProficiencies = values;
          }),
          onSavesChanged: (values) => _updateForm(() {
            _dirty = true;
            _savingThrowProficiencies = values;
          }),
        ),
      3 => _equipmentStep(),
      4 => _notesStep(),
      _ => CharacterSpellSection(
          spells: _spells,
          preparedMax: _preparedSpellMax,
          slotControllers: _spellSlotTotals,
          level: _level,
          spellcastingAbility: _spellcastingAbility,
          abilityScore: _spellcastingAbilityController.text,
          onSpellcastingChanged: (value) => _updateForm(() {
            _dirty = true;
            _spellcastingAbility = value;
          }),
          onSearch: _pickSpell,
          onAddCustom: _editSpell,
          onEdit: _editSpell,
          onRemove: (index) => _updateForm(() {
            _dirty = true;
            _spells.removeAt(index);
          }),
        ),
    };
  }

  TextEditingController get _spellcastingAbilityController {
    return switch (_spellcastingAbility) {
      'strength' => _str,
      'dexterity' => _dex,
      'constitution' => _con,
      'intelligence' => _int,
      'wisdom' => _wis,
      'charisma' => _cha,
      _ => _wis,
    };
  }

  Widget _equipmentStep() {
    return CharacterEquipmentSection(
      armors: _armors,
      shields: _shields,
      weapons: _weapons,
      gear: _gear,
      cp: _cp,
      sp: _sp,
      ep: _ep,
      gp: _gp,
      pp: _pp,
      training: _training,
      onAddArmorFromDb: _addArmorFromDb,
      onAddCustomArmor: () => _editEntry(
        _armors,
        title: 'Add Armor',
        quantity: true,
      ),
      onEditArmor: (index) => _editEntry(
        _armors,
        index: index,
        title: 'Edit Armor',
        quantity: true,
      ),
      onDeleteArmor: (index) => _removeAt(_armors, index),
      onAddShieldFromDb: _addShieldFromDb,
      onAddCustomShield: () => _editEntry(
        _shields,
        title: 'Add Shield',
        quantity: true,
      ),
      onEditShield: (index) => _editEntry(
        _shields,
        index: index,
        title: 'Edit Shield',
        quantity: true,
      ),
      onDeleteShield: (index) => _removeAt(_shields, index),
      onAddWeaponFromDb: _addWeaponFromDb,
      onAddCustomWeapon: () => _editWeapon(),
      onEditWeapon: (index) => _editWeapon(index: index),
      onDeleteWeapon: (index) => _removeAt(_weapons, index),
      onAddGearFromDb: _addGearFromDb,
      onAddCustomGear: () => _editEntry(
        _gear,
        title: 'Add Item',
        quantity: true,
      ),
      onEditGear: (index) => _editEntry(
        _gear,
        index: index,
        title: 'Edit Item',
        quantity: true,
      ),
      onDeleteGear: (index) => _removeAt(_gear, index),
      onTrainingChanged: (value) => _updateForm(() {
        _dirty = true;
        _training = value;
      }),
    );
  }

  Widget _notesStep() {
    return CharacterNotesSection(
      armorClass: _ac,
      speed: _speed,
      classFeatures: _classFeatures,
      speciesTraits: _speciesTraits,
      feats: _feats,
      toolProficiencies: _toolProficiencies,
      languages: _languages,
      backstory: _backstory,
      onAddClassFeature: () =>
          _editEntry(_classFeatures, title: 'Add Class Feature'),
      onEditClassFeature: (index) => _editEntry(
        _classFeatures,
        index: index,
        title: 'Edit Class Feature',
      ),
      onDeleteClassFeature: (index) => _removeAt(_classFeatures, index),
      onAddSpeciesTrait: () =>
          _editEntry(_speciesTraits, title: 'Add Species Trait'),
      onEditSpeciesTrait: (index) => _editEntry(
        _speciesTraits,
        index: index,
        title: 'Edit Species Trait',
      ),
      onDeleteSpeciesTrait: (index) => _removeAt(_speciesTraits, index),
      onAddFeat: () => _editEntry(_feats, title: 'Add Feat'),
      onEditFeat: (index) =>
          _editEntry(_feats, index: index, title: 'Edit Feat'),
      onDeleteFeat: (index) => _removeAt(_feats, index),
      onAddTool: () => _editEntry(
        _toolProficiencies,
        title: 'Add Tool Proficiency',
        description: false,
      ),
      onEditTool: (index) => _editEntry(
        _toolProficiencies,
        index: index,
        title: 'Edit Tool Proficiency',
        description: false,
      ),
      onDeleteTool: (index) => _removeAt(_toolProficiencies, index),
      onAddLanguage: () => _editEntry(
        _languages,
        title: 'Add Language',
        description: false,
      ),
      onEditLanguage: (index) => _editEntry(
        _languages,
        index: index,
        title: 'Edit Language',
        description: false,
      ),
      onDeleteLanguage: (index) => _removeAt(_languages, index),
    );
  }

  void _goToStep(int index) {
    if (index == _stepIndex) {
      return;
    }
    _updateForm(() {
      _stepDirection = index > _stepIndex ? 1 : -1;
      _stepIndex = index;
    });
  }

  void _previousStep() {
    if (_stepIndex > 0) {
      _updateForm(() {
        _stepDirection = -1;
        _stepIndex -= 1;
      });
    }
  }

  void _nextStep() {
    if (_stepIndex < _CharacterFormScreenState._stepLabels.length - 1) {
      _updateForm(() {
        _stepDirection = 1;
        _stepIndex += 1;
      });
    }
  }
}

class _FormStepPicker extends StatefulWidget {
  const _FormStepPicker({
    required this.labels,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  State<_FormStepPicker> createState() => _FormStepPickerState();
}

class _FormStepPickerState extends State<_FormStepPicker> {
  final _scrollController = ScrollController();
  late List<GlobalKey> _itemKeys;

  @override
  void initState() {
    super.initState();
    _itemKeys = _createKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void didUpdateWidget(covariant _FormStepPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length) {
      _itemKeys = _createKeys();
    }
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.labels.length != widget.labels.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<GlobalKey> _createKeys() {
    return List.generate(widget.labels.length, (_) => GlobalKey());
  }

  void _scrollToCurrent() {
    if (!mounted || widget.currentIndex >= _itemKeys.length) {
      return;
    }
    final context = _itemKeys[widget.currentIndex].currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < widget.labels.length; i++)
              _FormStepTab(
                key: _itemKeys[i],
                label: widget.labels[i],
                selected: widget.currentIndex == i,
                onTap: () => widget.onChanged(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _FormStepTab extends StatelessWidget {
  const _FormStepTab({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground =
        selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                height: 3,
                width: selected ? 32 : 0,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormNavigation extends StatelessWidget {
  const _FormNavigation({
    required this.isFirst,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  final bool isFirst;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!isFirst) TextButton(onPressed: onBack, child: const Text('Prev')),
        const Spacer(),
        if (!isLast) FilledButton(onPressed: onNext, child: const Text('Next')),
      ],
    );
  }
}
