part of 'app_models.dart';

class CharacterNote {
  const CharacterNote({
    required this.id,
    required this.campaignIds,
    required this.name,
    required this.playerName,
    required this.ancestryOrSpecies,
    required this.className,
    this.profileImagePath = '',
    required this.speciesRefId,
    required this.classRefId,
    required this.backgroundRefId,
    required this.subclassName,
    required this.subclassRefId,
    required this.level,
    required this.background,
    required this.pronouns,
    required this.alignment,
    required this.experiencePoints,
    required this.proficiencyBonus,
    required this.hp,
    required this.currentHp,
    required this.temporaryHp,
    required this.hitDice,
    required this.deathSaveSuccesses,
    required this.deathSaveFailures,
    required this.armorClass,
    required this.armorRefId,
    required this.armorName,
    required this.shieldEquipped,
    this.equippedWeaponId = '',
    this.equippedArmorId = '',
    this.equippedShieldId = '',
    required this.size,
    required this.speed,
    required this.initiative,
    required this.passivePerception,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
    required this.inventoryNotes,
    required this.attackNotes,
    required this.featureNotes,
    required this.skillNotes,
    required this.savingThrowNotes,
    required this.personalityNotes,
    required this.toolAndLanguageNotes,
    required this.treasureNotes,
    required this.skillProficiencies,
    required this.savingThrowProficiencies,
    required this.selectedFeatureIds,
    required this.selectedFeatIds,
    required this.selectedTraitIds,
    required this.selectedWeaponIds,
    required this.selectedArmorIds,
    this.selectedShieldIds = const [],
    required this.selectedGearIds,
    required this.selectedSpellIds,
    required this.spellcastingAbility,
    required this.coinsNotes,
    required this.weapons,
    required this.armors,
    this.shields = const [],
    required this.gear,
    required this.treasures,
    required this.classFeatures,
    required this.speciesTraits,
    required this.feats,
    required this.toolProficiencies,
    required this.languages,
    required this.coins,
    required this.training,
    required this.spellcastingSetup,
    required this.spellNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final List<String> campaignIds;
  final String name;
  final String playerName;
  final String ancestryOrSpecies;
  final String className;
  final String profileImagePath;
  final String speciesRefId;
  final String classRefId;
  final String backgroundRefId;
  final String subclassName;
  final String subclassRefId;
  final int level;
  final String background;
  final String pronouns;
  final String alignment;
  final int experiencePoints;
  final int proficiencyBonus;
  final int hp;
  final int currentHp;
  final int temporaryHp;
  final String hitDice;
  final int deathSaveSuccesses;
  final int deathSaveFailures;
  final int armorClass;
  final String armorRefId;
  final String armorName;
  final bool shieldEquipped;
  final String equippedWeaponId;
  final String equippedArmorId;
  final String equippedShieldId;
  final String size;
  final int speed;
  final int initiative;
  final int passivePerception;
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final String inventoryNotes;
  final String attackNotes;
  final String featureNotes;
  final String skillNotes;
  final String savingThrowNotes;
  final String personalityNotes;
  final String toolAndLanguageNotes;
  final String treasureNotes;
  final Map<String, String> skillProficiencies;
  final Map<String, String> savingThrowProficiencies;
  final List<String> selectedFeatureIds;
  final List<String> selectedFeatIds;
  final List<String> selectedTraitIds;
  final List<String> selectedWeaponIds;
  final List<String> selectedArmorIds;
  final List<String> selectedShieldIds;
  final List<String> selectedGearIds;
  final List<String> selectedSpellIds;
  final String spellcastingAbility;
  final String coinsNotes;
  final List<CharacterWeapon> weapons;
  final List<CharacterListEntry> armors;
  final List<CharacterListEntry> shields;
  final List<CharacterListEntry> gear;
  final List<CharacterListEntry> treasures;
  final List<CharacterListEntry> classFeatures;
  final List<CharacterListEntry> speciesTraits;
  final List<CharacterListEntry> feats;
  final List<CharacterListEntry> toolProficiencies;
  final List<CharacterListEntry> languages;
  final CharacterCoins coins;
  final CharacterTraining training;
  final CharacterSpellcastingSetup spellcastingSetup;
  final List<SpellNote> spellNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CharacterNote.fromJson(Map<String, dynamic> json) {
    final legacyCampaignId = json['campaignId']?.toString();
    final campaignIds = _stringListFromJson(json['campaignIds']);
    final armorRefId = json['armorRefId']?.toString() ?? '';
    final armorName = json['armorName']?.toString() ?? '';
    final armors = characterEntryListFromJson(json['armors']);
    final rawGear = characterEntryListFromJson(json['gear']);
    final rawShields = characterEntryListFromJson(json['shields']);
    final shields = rawShields.isNotEmpty
        ? rawShields
        : rawGear.where(_entryLooksLikeShield).toList();
    final gear = rawShields.isNotEmpty
        ? rawGear
        : rawGear.where((entry) => !_entryLooksLikeShield(entry)).toList();
    final equippedShieldId = json['equippedShieldId']?.toString() ?? '';
    return CharacterNote(
      id: json['id'].toString(),
      campaignIds: campaignIds.isNotEmpty
          ? campaignIds
          : [
              if (legacyCampaignId != null && legacyCampaignId.isNotEmpty)
                legacyCampaignId,
            ],
      name: json['name']?.toString() ?? '',
      playerName: json['playerName']?.toString() ?? '',
      ancestryOrSpecies: json['ancestryOrSpecies']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      profileImagePath: json['profileImagePath']?.toString() ?? '',
      speciesRefId: json['speciesRefId']?.toString() ?? '',
      classRefId: json['classRefId']?.toString() ?? '',
      backgroundRefId: json['backgroundRefId']?.toString() ?? '',
      subclassName: json['subclassName']?.toString() ?? '',
      subclassRefId: json['subclassRefId']?.toString() ?? '',
      level: _intFromJson(json['level'], 1),
      background: json['background']?.toString() ?? '',
      pronouns: json['pronouns']?.toString() ?? '',
      alignment: json['alignment']?.toString() ?? '',
      experiencePoints: _intFromJson(json['experiencePoints']),
      proficiencyBonus: _intFromJson(json['proficiencyBonus'], 2),
      hp: _intFromJson(json['hp']),
      currentHp: _intFromJson(json['currentHp'], _intFromJson(json['hp'])),
      temporaryHp: _intFromJson(json['temporaryHp']),
      hitDice: json['hitDice']?.toString() ?? '',
      deathSaveSuccesses: _intFromJson(json['deathSaveSuccesses']),
      deathSaveFailures: _intFromJson(json['deathSaveFailures']),
      armorClass: _intFromJson(json['armorClass'], 10),
      armorRefId: armorRefId,
      armorName: armorName,
      shieldEquipped: _boolFromJson(json['shieldEquipped']),
      equippedWeaponId: json['equippedWeaponId']?.toString() ?? '',
      equippedArmorId: json['equippedArmorId']?.toString() ?? '',
      equippedShieldId: equippedShieldId.isNotEmpty
          ? equippedShieldId
          : _boolFromJson(json['shieldEquipped']) && shields.isNotEmpty
              ? shields.first.id
              : '',
      size: json['size']?.toString() ?? '',
      speed: _intFromJson(json['speed'], 30),
      initiative: _intFromJson(json['initiative']),
      passivePerception: _intFromJson(json['passivePerception'], 10),
      strength: _intFromJson(json['strength'], 10),
      dexterity: _intFromJson(json['dexterity'], 10),
      constitution: _intFromJson(json['constitution'], 10),
      intelligence: _intFromJson(json['intelligence'], 10),
      wisdom: _intFromJson(json['wisdom'], 10),
      charisma: _intFromJson(json['charisma'], 10),
      inventoryNotes: json['inventoryNotes']?.toString() ?? '',
      attackNotes: json['attackNotes']?.toString() ?? '',
      featureNotes: json['featureNotes']?.toString() ?? '',
      skillNotes: json['skillNotes']?.toString() ?? '',
      savingThrowNotes: json['savingThrowNotes']?.toString() ?? '',
      personalityNotes: json['personalityNotes']?.toString() ?? '',
      toolAndLanguageNotes: json['toolAndLanguageNotes']?.toString() ?? '',
      treasureNotes: json['treasureNotes']?.toString() ?? '',
      skillProficiencies: _stringMapFromJson(json['skillProficiencies']),
      savingThrowProficiencies:
          _stringMapFromJson(json['savingThrowProficiencies']),
      selectedFeatureIds: _stringListFromJson(json['selectedFeatureIds']),
      selectedFeatIds: _stringListFromJson(json['selectedFeatIds']),
      selectedTraitIds: _stringListFromJson(json['selectedTraitIds']),
      selectedWeaponIds: _stringListFromJson(json['selectedWeaponIds']),
      selectedArmorIds: _stringListFromJson(json['selectedArmorIds']),
      selectedShieldIds: _stringListFromJson(json['selectedShieldIds']),
      selectedGearIds: _stringListFromJson(json['selectedGearIds']),
      selectedSpellIds: _stringListFromJson(json['selectedSpellIds']),
      spellcastingAbility: json['spellcastingAbility']?.toString() ?? 'wisdom',
      coinsNotes: json['coinsNotes']?.toString() ?? '',
      weapons: characterWeaponListFromJson(json['weapons']),
      armors: armors.isNotEmpty
          ? armors
          : [
              if (armorName.isNotEmpty)
                CharacterListEntry(
                  id: armorRefId.isEmpty ? armorName : armorRefId,
                  name: armorName,
                  refId: armorRefId,
                ),
            ],
      shields: shields,
      gear: gear,
      treasures: characterEntryListFromJson(json['treasures']),
      classFeatures: characterEntryListFromJson(json['classFeatures']),
      speciesTraits: characterEntryListFromJson(json['speciesTraits']),
      feats: characterEntryListFromJson(json['feats']),
      toolProficiencies: characterEntryListFromJson(json['toolProficiencies']),
      languages: characterEntryListFromJson(json['languages']),
      coins: json['coins'] is Map
          ? CharacterCoins.fromJson(Map<String, dynamic>.from(json['coins'] as Map))
          : const CharacterCoins(),
      training: json['training'] is Map
          ? CharacterTraining.fromJson(
              Map<String, dynamic>.from(json['training'] as Map),
            )
          : const CharacterTraining(),
      spellcastingSetup: json['spellcastingSetup'] is Map
          ? CharacterSpellcastingSetup.fromJson(
              Map<String, dynamic>.from(json['spellcastingSetup'] as Map),
            )
          : const CharacterSpellcastingSetup(),
      spellNotes: [
        for (final item in (json['spellNotes'] as List? ?? const []))
          SpellNote.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: _dateFromJson(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaignIds': campaignIds,
        'name': name,
        'playerName': playerName,
        'ancestryOrSpecies': ancestryOrSpecies,
        'className': className,
        'profileImagePath': profileImagePath,
        'speciesRefId': speciesRefId,
        'classRefId': classRefId,
        'backgroundRefId': backgroundRefId,
        'subclassName': subclassName,
        'subclassRefId': subclassRefId,
        'level': level,
        'background': background,
        'pronouns': pronouns,
        'alignment': alignment,
        'experiencePoints': experiencePoints,
        'proficiencyBonus': proficiencyBonus,
        'hp': hp,
        'currentHp': currentHp,
        'temporaryHp': temporaryHp,
        'hitDice': hitDice,
        'deathSaveSuccesses': deathSaveSuccesses,
        'deathSaveFailures': deathSaveFailures,
        'armorClass': armorClass,
        'armorRefId': armorRefId,
        'armorName': armorName,
        'shieldEquipped': shieldEquipped,
        'equippedWeaponId': equippedWeaponId,
        'equippedArmorId': equippedArmorId,
        'equippedShieldId': equippedShieldId,
        'size': size,
        'speed': speed,
        'initiative': initiative,
        'passivePerception': passivePerception,
        'strength': strength,
        'dexterity': dexterity,
        'constitution': constitution,
        'intelligence': intelligence,
        'wisdom': wisdom,
        'charisma': charisma,
        'inventoryNotes': inventoryNotes,
        'attackNotes': attackNotes,
        'featureNotes': featureNotes,
        'skillNotes': skillNotes,
        'savingThrowNotes': savingThrowNotes,
        'personalityNotes': personalityNotes,
        'toolAndLanguageNotes': toolAndLanguageNotes,
        'treasureNotes': treasureNotes,
        'skillProficiencies': skillProficiencies,
        'savingThrowProficiencies': savingThrowProficiencies,
        'selectedFeatureIds': selectedFeatureIds,
        'selectedFeatIds': selectedFeatIds,
        'selectedTraitIds': selectedTraitIds,
        'selectedWeaponIds': selectedWeaponIds,
        'selectedArmorIds': selectedArmorIds,
        'selectedShieldIds': selectedShieldIds,
        'selectedGearIds': selectedGearIds,
        'selectedSpellIds': selectedSpellIds,
        'spellcastingAbility': spellcastingAbility,
        'coinsNotes': coinsNotes,
        'weapons': weapons.map((weapon) => weapon.toJson()).toList(),
        'armors': armors.map((entry) => entry.toJson()).toList(),
        'shields': shields.map((entry) => entry.toJson()).toList(),
        'gear': gear.map((entry) => entry.toJson()).toList(),
        'treasures': treasures.map((entry) => entry.toJson()).toList(),
        'classFeatures': classFeatures.map((entry) => entry.toJson()).toList(),
        'speciesTraits': speciesTraits.map((entry) => entry.toJson()).toList(),
        'feats': feats.map((entry) => entry.toJson()).toList(),
        'toolProficiencies':
            toolProficiencies.map((entry) => entry.toJson()).toList(),
        'languages': languages.map((entry) => entry.toJson()).toList(),
        'coins': coins.toJson(),
        'training': training.toJson(),
        'spellcastingSetup': spellcastingSetup.toJson(),
        'spellNotes': spellNotes.map((spell) => spell.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  CharacterNote copyWith({
    String? id,
    List<String>? campaignIds,
    String? name,
    String? playerName,
    String? ancestryOrSpecies,
    String? className,
    String? profileImagePath,
    String? speciesRefId,
    String? classRefId,
    String? backgroundRefId,
    String? subclassName,
    String? subclassRefId,
    int? level,
    String? background,
    String? pronouns,
    String? alignment,
    int? experiencePoints,
    int? proficiencyBonus,
    int? hp,
    int? currentHp,
    int? temporaryHp,
    String? hitDice,
    int? deathSaveSuccesses,
    int? deathSaveFailures,
    int? armorClass,
    String? armorRefId,
    String? armorName,
    bool? shieldEquipped,
    String? equippedWeaponId,
    String? equippedArmorId,
    String? equippedShieldId,
    String? size,
    int? speed,
    int? initiative,
    int? passivePerception,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? charisma,
    String? inventoryNotes,
    String? attackNotes,
    String? featureNotes,
    String? skillNotes,
    String? savingThrowNotes,
    String? personalityNotes,
    String? toolAndLanguageNotes,
    String? treasureNotes,
    Map<String, String>? skillProficiencies,
    Map<String, String>? savingThrowProficiencies,
    List<String>? selectedFeatureIds,
    List<String>? selectedFeatIds,
    List<String>? selectedTraitIds,
    List<String>? selectedWeaponIds,
    List<String>? selectedArmorIds,
    List<String>? selectedShieldIds,
    List<String>? selectedGearIds,
    List<String>? selectedSpellIds,
    String? spellcastingAbility,
    String? coinsNotes,
    List<CharacterWeapon>? weapons,
    List<CharacterListEntry>? armors,
    List<CharacterListEntry>? shields,
    List<CharacterListEntry>? gear,
    List<CharacterListEntry>? treasures,
    List<CharacterListEntry>? classFeatures,
    List<CharacterListEntry>? speciesTraits,
    List<CharacterListEntry>? feats,
    List<CharacterListEntry>? toolProficiencies,
    List<CharacterListEntry>? languages,
    CharacterCoins? coins,
    CharacterTraining? training,
    CharacterSpellcastingSetup? spellcastingSetup,
    List<SpellNote>? spellNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CharacterNote(
      id: id ?? this.id,
      campaignIds: campaignIds ?? this.campaignIds,
      name: name ?? this.name,
      playerName: playerName ?? this.playerName,
      ancestryOrSpecies: ancestryOrSpecies ?? this.ancestryOrSpecies,
      className: className ?? this.className,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      speciesRefId: speciesRefId ?? this.speciesRefId,
      classRefId: classRefId ?? this.classRefId,
      backgroundRefId: backgroundRefId ?? this.backgroundRefId,
      subclassName: subclassName ?? this.subclassName,
      subclassRefId: subclassRefId ?? this.subclassRefId,
      level: level ?? this.level,
      background: background ?? this.background,
      pronouns: pronouns ?? this.pronouns,
      alignment: alignment ?? this.alignment,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      proficiencyBonus: proficiencyBonus ?? this.proficiencyBonus,
      hp: hp ?? this.hp,
      currentHp: currentHp ?? this.currentHp,
      temporaryHp: temporaryHp ?? this.temporaryHp,
      hitDice: hitDice ?? this.hitDice,
      deathSaveSuccesses: deathSaveSuccesses ?? this.deathSaveSuccesses,
      deathSaveFailures: deathSaveFailures ?? this.deathSaveFailures,
      armorClass: armorClass ?? this.armorClass,
      armorRefId: armorRefId ?? this.armorRefId,
      armorName: armorName ?? this.armorName,
      shieldEquipped: shieldEquipped ?? this.shieldEquipped,
      equippedWeaponId: equippedWeaponId ?? this.equippedWeaponId,
      equippedArmorId: equippedArmorId ?? this.equippedArmorId,
      equippedShieldId: equippedShieldId ?? this.equippedShieldId,
      size: size ?? this.size,
      speed: speed ?? this.speed,
      initiative: initiative ?? this.initiative,
      passivePerception: passivePerception ?? this.passivePerception,
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      constitution: constitution ?? this.constitution,
      intelligence: intelligence ?? this.intelligence,
      wisdom: wisdom ?? this.wisdom,
      charisma: charisma ?? this.charisma,
      inventoryNotes: inventoryNotes ?? this.inventoryNotes,
      attackNotes: attackNotes ?? this.attackNotes,
      featureNotes: featureNotes ?? this.featureNotes,
      skillNotes: skillNotes ?? this.skillNotes,
      savingThrowNotes: savingThrowNotes ?? this.savingThrowNotes,
      personalityNotes: personalityNotes ?? this.personalityNotes,
      toolAndLanguageNotes: toolAndLanguageNotes ?? this.toolAndLanguageNotes,
      treasureNotes: treasureNotes ?? this.treasureNotes,
      skillProficiencies: skillProficiencies ?? this.skillProficiencies,
      savingThrowProficiencies:
          savingThrowProficiencies ?? this.savingThrowProficiencies,
      selectedFeatureIds: selectedFeatureIds ?? this.selectedFeatureIds,
      selectedFeatIds: selectedFeatIds ?? this.selectedFeatIds,
      selectedTraitIds: selectedTraitIds ?? this.selectedTraitIds,
      selectedWeaponIds: selectedWeaponIds ?? this.selectedWeaponIds,
      selectedArmorIds: selectedArmorIds ?? this.selectedArmorIds,
      selectedShieldIds: selectedShieldIds ?? this.selectedShieldIds,
      selectedGearIds: selectedGearIds ?? this.selectedGearIds,
      selectedSpellIds: selectedSpellIds ?? this.selectedSpellIds,
      spellcastingAbility: spellcastingAbility ?? this.spellcastingAbility,
      coinsNotes: coinsNotes ?? this.coinsNotes,
      weapons: weapons ?? this.weapons,
      armors: armors ?? this.armors,
      shields: shields ?? this.shields,
      gear: gear ?? this.gear,
      treasures: treasures ?? this.treasures,
      classFeatures: classFeatures ?? this.classFeatures,
      speciesTraits: speciesTraits ?? this.speciesTraits,
      feats: feats ?? this.feats,
      toolProficiencies: toolProficiencies ?? this.toolProficiencies,
      languages: languages ?? this.languages,
      coins: coins ?? this.coins,
      training: training ?? this.training,
      spellcastingSetup: spellcastingSetup ?? this.spellcastingSetup,
      spellNotes: spellNotes ?? this.spellNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

