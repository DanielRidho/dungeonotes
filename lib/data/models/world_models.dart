part of 'app_models.dart';

class WorldNote {
  const WorldNote({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.type,
    required this.description,
    required this.relationshipStatus,
    required this.tags,
    required this.lastSeenSession,
    required this.createdAt,
    required this.updatedAt,
    this.species = '',
    this.role = '',
    this.locationName = '',
    this.relationship = NpcRelationship.unknown,
    this.status = NpcStatus.unknown,
    this.locationType = '',
    this.relatedNpcs = const [],
    this.relatedQuests = const [],
    this.imagePath = '',
  });

  final String id;
  final String campaignId;
  final String name;
  final WorldNoteType type;
  final String description;
  final String relationshipStatus;
  final List<String> tags;
  final String lastSeenSession;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String species;
  final String role;
  final String locationName;
  final NpcRelationship relationship;
  final NpcStatus status;
  final String locationType;
  final List<String> relatedNpcs;
  final List<String> relatedQuests;
  final String imagePath;

  factory WorldNote.fromJson(Map<String, dynamic> json) {
    return WorldNote(
      id: json['id'].toString(),
      campaignId: json['campaignId'].toString(),
      name: json['name']?.toString() ?? '',
      type: WorldNoteType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => WorldNoteType.npc,
      ),
      description: json['description']?.toString() ?? '',
      relationshipStatus: json['relationshipStatus']?.toString() ?? '',
      tags: List<String>.from(json['tags'] as List? ?? const []),
      lastSeenSession: json['lastSeenSession']?.toString() ?? '',
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: _dateFromJson(json['updatedAt']),
      species: json['species']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      locationName: json['locationName']?.toString() ?? '',
      relationship: NpcRelationship.values.firstWhere(
        (value) => value.name == json['relationship'],
        orElse: () => NpcRelationship.unknown,
      ),
      status: NpcStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => NpcStatus.unknown,
      ),
      locationType: json['locationType']?.toString() ?? '',
      relatedNpcs: _stringListFromJson(json['relatedNpcs']),
      relatedQuests: _stringListFromJson(json['relatedQuests']),
      imagePath: json['imagePath']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaignId': campaignId,
        'name': name,
        'type': type.name,
        'description': description,
        'relationshipStatus': relationshipStatus,
        'tags': tags,
        'lastSeenSession': lastSeenSession,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'species': species,
        'role': role,
        'locationName': locationName,
        'relationship': relationship.name,
        'status': status.name,
        'locationType': locationType,
        'relatedNpcs': relatedNpcs,
        'relatedQuests': relatedQuests,
        'imagePath': imagePath,
      };

  WorldNote copyWith({
    String? name,
    WorldNoteType? type,
    String? description,
    String? relationshipStatus,
    List<String>? tags,
    String? lastSeenSession,
    DateTime? updatedAt,
    String? species,
    String? role,
    String? locationName,
    NpcRelationship? relationship,
    NpcStatus? status,
    String? locationType,
    List<String>? relatedNpcs,
    List<String>? relatedQuests,
    String? imagePath,
  }) {
    return WorldNote(
      id: id,
      campaignId: campaignId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      tags: tags ?? this.tags,
      lastSeenSession: lastSeenSession ?? this.lastSeenSession,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      species: species ?? this.species,
      role: role ?? this.role,
      locationName: locationName ?? this.locationName,
      relationship: relationship ?? this.relationship,
      status: status ?? this.status,
      locationType: locationType ?? this.locationType,
      relatedNpcs: relatedNpcs ?? this.relatedNpcs,
      relatedQuests: relatedQuests ?? this.relatedQuests,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class CampaignCharacterState {
  const CampaignCharacterState({
    required this.id,
    required this.campaignId,
    required this.characterId,
    required this.currentHp,
    required this.temporaryHp,
    required this.temporaryHpMax,
    required this.armorClass,
    required this.deathSaveSuccesses,
    required this.deathSaveFailures,
    required this.conditions,
    required this.activeArmorName,
    required this.activeArmorId,
    required this.activeWeaponId,
    required this.activeShieldId,
    required this.shieldEquipped,
    required this.inspiration,
    required this.exhaustionLevel,
    required this.expendedSpellSlots,
    required this.notes,
    required this.updatedAt,
  });

  final String id;
  final String campaignId;
  final String characterId;
  final int currentHp;
  final int temporaryHp;
  final int temporaryHpMax;
  final int armorClass;
  final int deathSaveSuccesses;
  final int deathSaveFailures;
  final List<String> conditions;
  final String activeArmorName;
  final String activeArmorId;
  final String activeWeaponId;
  final String activeShieldId;
  final bool shieldEquipped;
  final bool inspiration;
  final int exhaustionLevel;
  final Map<String, String> expendedSpellSlots;
  final String notes;
  final DateTime updatedAt;

  factory CampaignCharacterState.initial({
    required String campaignId,
    required CharacterNote character,
  }) {
    CharacterListEntry? equippedArmor;
    for (final armor in character.armors) {
      if (armor.id == character.equippedArmorId) {
        equippedArmor = armor;
        break;
      }
    }
    final equippedShieldId = character.equippedShieldId.isNotEmpty
        ? character.equippedShieldId
        : character.shieldEquipped && character.shields.isNotEmpty
            ? character.shields.first.id
            : '';
    return CampaignCharacterState(
      id: '$campaignId:${character.id}',
      campaignId: campaignId,
      characterId: character.id,
      currentHp: character.hp,
      temporaryHp: 0,
      temporaryHpMax: 0,
      armorClass: character.armorClass,
      deathSaveSuccesses: 0,
      deathSaveFailures: 0,
      conditions: const [],
      activeArmorName: equippedArmor?.name ?? '',
      activeArmorId: character.equippedArmorId,
      activeWeaponId: character.equippedWeaponId,
      activeShieldId: equippedShieldId,
      shieldEquipped: equippedShieldId.isNotEmpty,
      inspiration: false,
      exhaustionLevel: 0,
      expendedSpellSlots: const {},
      notes: '',
      updatedAt: DateTime.now(),
    );
  }

  factory CampaignCharacterState.fromJson(Map<String, dynamic> json) {
    return CampaignCharacterState(
      id: json['id']?.toString() ??
          '${json['campaignId']}:${json['characterId']}',
      campaignId: json['campaignId']?.toString() ?? '',
      characterId: json['characterId']?.toString() ?? '',
      currentHp: _intFromJson(json['currentHp']),
      temporaryHp: _intFromJson(json['temporaryHp']),
      temporaryHpMax: _intFromJson(
        json['temporaryHpMax'],
        _intFromJson(json['temporaryHp']),
      ),
      armorClass: _intFromJson(json['armorClass'], 10),
      deathSaveSuccesses: _intFromJson(json['deathSaveSuccesses']),
      deathSaveFailures: _intFromJson(json['deathSaveFailures']),
      conditions: _stringListFromJson(json['conditions']),
      activeArmorName: json['activeArmorName']?.toString() ?? '',
      activeArmorId: json['activeArmorId']?.toString() ?? '',
      activeWeaponId: json['activeWeaponId']?.toString() ?? '',
      activeShieldId: json['activeShieldId']?.toString() ?? '',
      shieldEquipped: _boolFromJson(json['shieldEquipped']),
      inspiration: _boolFromJson(json['inspiration']),
      exhaustionLevel: _intFromJson(json['exhaustionLevel']).clamp(0, 6),
      expendedSpellSlots: _stringMapFromJson(json['expendedSpellSlots']),
      notes: json['notes']?.toString() ?? '',
      updatedAt: _dateFromJson(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaignId': campaignId,
        'characterId': characterId,
        'currentHp': currentHp,
        'temporaryHp': temporaryHp,
        'temporaryHpMax': temporaryHpMax,
        'armorClass': armorClass,
        'deathSaveSuccesses': deathSaveSuccesses,
        'deathSaveFailures': deathSaveFailures,
        'conditions': conditions,
        'activeArmorName': activeArmorName,
        'activeArmorId': activeArmorId,
        'activeWeaponId': activeWeaponId,
        'activeShieldId': activeShieldId,
        'shieldEquipped': shieldEquipped,
        'inspiration': inspiration,
        'exhaustionLevel': exhaustionLevel,
        'expendedSpellSlots': expendedSpellSlots,
        'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
      };

  CampaignCharacterState copyWith({
    int? currentHp,
    int? temporaryHp,
    int? temporaryHpMax,
    int? armorClass,
    int? deathSaveSuccesses,
    int? deathSaveFailures,
    List<String>? conditions,
    String? activeArmorName,
    String? activeArmorId,
    String? activeWeaponId,
    String? activeShieldId,
    bool? shieldEquipped,
    bool? inspiration,
    int? exhaustionLevel,
    Map<String, String>? expendedSpellSlots,
    String? notes,
    DateTime? updatedAt,
  }) {
    return CampaignCharacterState(
      id: id,
      campaignId: campaignId,
      characterId: characterId,
      currentHp: currentHp ?? this.currentHp,
      temporaryHp: temporaryHp ?? this.temporaryHp,
      temporaryHpMax: temporaryHpMax ?? this.temporaryHpMax,
      armorClass: armorClass ?? this.armorClass,
      deathSaveSuccesses: deathSaveSuccesses ?? this.deathSaveSuccesses,
      deathSaveFailures: deathSaveFailures ?? this.deathSaveFailures,
      conditions: conditions ?? this.conditions,
      activeArmorName: activeArmorName ?? this.activeArmorName,
      activeArmorId: activeArmorId ?? this.activeArmorId,
      activeWeaponId: activeWeaponId ?? this.activeWeaponId,
      activeShieldId: activeShieldId ?? this.activeShieldId,
      shieldEquipped: shieldEquipped ?? this.shieldEquipped,
      inspiration: inspiration ?? this.inspiration,
      exhaustionLevel: exhaustionLevel ?? this.exhaustionLevel,
      expendedSpellSlots: expendedSpellSlots ?? this.expendedSpellSlots,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
