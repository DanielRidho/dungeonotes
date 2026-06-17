class CharacterListEntry {
  const CharacterListEntry({
    required this.id,
    required this.name,
    this.description = '',
    this.refId = '',
    this.quantity = 1,
  });

  final String id;
  final String name;
  final String description;
  final String refId;
  final int quantity;

  factory CharacterListEntry.fromJson(Map<String, dynamic> json) {
    final quantity = _intFromJson(json['quantity'], 1);
    return CharacterListEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      refId: json['refId']?.toString() ?? '',
      quantity: quantity < 1 ? 1 : quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'refId': refId,
        'quantity': quantity,
      };

  CharacterListEntry copyWith({
    String? id,
    String? name,
    String? description,
    String? refId,
    int? quantity,
  }) {
    return CharacterListEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      refId: refId ?? this.refId,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CharacterWeapon {
  const CharacterWeapon({
    required this.id,
    required this.name,
    this.refId = '',
    this.attackOrDc = '',
    this.damageAndType = '',
    this.diceCount = 1,
    this.diceSides = 6,
    this.attackBonus = 0,
    this.damageBonus = 0,
    this.description = '',
    this.quantity = 1,
  });

  final String id;
  final String name;
  final String refId;
  final String attackOrDc;
  final String damageAndType;
  final int diceCount;
  final int diceSides;
  final int attackBonus;
  final int damageBonus;
  final String description;
  final int quantity;

  factory CharacterWeapon.fromJson(Map<String, dynamic> json) {
    final diceCount = _intFromJson(json['diceCount'], 1).clamp(1, 20);
    final diceSides = _intFromJson(json['diceSides'], 6).clamp(2, 100);
    final damageBonus = _intFromJson(json['damageBonus']);
    final attackBonus = _intFromJson(json['attackBonus']);
    final quantity = _intFromJson(json['quantity'], 1);
    return CharacterWeapon(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      refId: json['refId']?.toString() ?? '',
      attackOrDc: json['attackOrDc']?.toString() ??
          (attackBonus == 0
              ? ''
              : attackBonus > 0
                  ? '+$attackBonus'
                  : '$attackBonus'),
      damageAndType: json['damageAndType']?.toString() ??
          _damageText(diceCount, diceSides, damageBonus),
      diceCount: diceCount,
      diceSides: diceSides,
      attackBonus: attackBonus,
      damageBonus: damageBonus,
      description: json['description']?.toString() ?? '',
      quantity: quantity < 1 ? 1 : quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'refId': refId,
        'attackOrDc': attackOrDc,
        'damageAndType': damageAndType,
        'diceCount': diceCount,
        'diceSides': diceSides,
        'attackBonus': attackBonus,
        'damageBonus': damageBonus,
        'description': description,
        'quantity': quantity,
      };

  CharacterWeapon copyWith({
    String? id,
    String? name,
    String? refId,
    String? attackOrDc,
    String? damageAndType,
    int? diceCount,
    int? diceSides,
    int? attackBonus,
    int? damageBonus,
    String? description,
    int? quantity,
  }) {
    return CharacterWeapon(
      id: id ?? this.id,
      name: name ?? this.name,
      refId: refId ?? this.refId,
      attackOrDc: attackOrDc ?? this.attackOrDc,
      damageAndType: damageAndType ?? this.damageAndType,
      diceCount: diceCount ?? this.diceCount,
      diceSides: diceSides ?? this.diceSides,
      attackBonus: attackBonus ?? this.attackBonus,
      damageBonus: damageBonus ?? this.damageBonus,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }

  String get damageLabel {
    if (damageAndType.trim().isNotEmpty) {
      return damageAndType;
    }
    return _damageText(diceCount, diceSides, damageBonus);
  }

  String get attackLabel => attackOrDc.trim().isNotEmpty
      ? attackOrDc
      : attackBonus == 0
          ? ''
          : attackBonus > 0
              ? '+$attackBonus'
              : '$attackBonus';
}

String _damageText(int diceCount, int diceSides, int damageBonus) {
    final bonus = damageBonus == 0
        ? ''
        : damageBonus > 0
            ? '+$damageBonus'
            : '$damageBonus';
    return '${diceCount}d$diceSides$bonus';
}

class CharacterCoins {
  const CharacterCoins({
    this.cp = 0,
    this.sp = 0,
    this.ep = 0,
    this.gp = 0,
    this.pp = 0,
  });

  final int cp;
  final int sp;
  final int ep;
  final int gp;
  final int pp;

  factory CharacterCoins.fromJson(Map<String, dynamic> json) {
    return CharacterCoins(
      cp: _intFromJson(json['cp']),
      sp: _intFromJson(json['sp']),
      ep: _intFromJson(json['ep']),
      gp: _intFromJson(json['gp']),
      pp: _intFromJson(json['pp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'cp': cp,
        'sp': sp,
        'ep': ep,
        'gp': gp,
        'pp': pp,
      };

  String get label => 'CP $cp / SP $sp / EP $ep / GP $gp / PP $pp';
}

bool _boolFromJson(Object? value) => value == true;

List<String> _stringListFromJson(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

class SpellNote {
  const SpellNote({
    required this.spellName,
    required this.spellLevel,
    required this.prepared,
    required this.note,
    this.castingTime = '',
    this.range = '',
    this.components = const [],
  });

  final String spellName;
  final String spellLevel;
  final bool prepared;
  final String note;
  final String castingTime;
  final String range;
  final List<String> components;

  factory SpellNote.fromJson(Map<String, dynamic> json) {
    return SpellNote(
      spellName: json['spellName']?.toString() ?? '',
      spellLevel: json['spellLevel']?.toString() ?? '',
      prepared: _boolFromJson(json['prepared']),
      note: json['note']?.toString() ?? '',
      castingTime: json['castingTime']?.toString() ?? '',
      range: json['range']?.toString() ?? '',
      components: _stringListFromJson(json['components']),
    );
  }

  Map<String, dynamic> toJson() => {
        'spellName': spellName,
        'spellLevel': spellLevel,
        'prepared': prepared,
        'note': note,
        'castingTime': castingTime,
        'range': range,
        'components': components,
      };
}

class CharacterTraining {
  const CharacterTraining({
    this.lightArmor = false,
    this.mediumArmor = false,
    this.heavyArmor = false,
    this.shields = false,
    this.simpleWeapons = false,
    this.martialWeapons = false,
    this.improvisedWeapons = false,
  });

  final bool lightArmor;
  final bool mediumArmor;
  final bool heavyArmor;
  final bool shields;
  final bool simpleWeapons;
  final bool martialWeapons;
  final bool improvisedWeapons;

  factory CharacterTraining.fromJson(Map<String, dynamic> json) {
    return CharacterTraining(
      lightArmor: json['lightArmor'] == true,
      mediumArmor: json['mediumArmor'] == true,
      heavyArmor: json['heavyArmor'] == true,
      shields: json['shields'] == true,
      simpleWeapons: json['simpleWeapons'] == true,
      martialWeapons: json['martialWeapons'] == true,
      improvisedWeapons: json['improvisedWeapons'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'lightArmor': lightArmor,
        'mediumArmor': mediumArmor,
        'heavyArmor': heavyArmor,
        'shields': shields,
        'simpleWeapons': simpleWeapons,
        'martialWeapons': martialWeapons,
        'improvisedWeapons': improvisedWeapons,
      };

  CharacterTraining copyWith({
    bool? lightArmor,
    bool? mediumArmor,
    bool? heavyArmor,
    bool? shields,
    bool? simpleWeapons,
    bool? martialWeapons,
    bool? improvisedWeapons,
  }) {
    return CharacterTraining(
      lightArmor: lightArmor ?? this.lightArmor,
      mediumArmor: mediumArmor ?? this.mediumArmor,
      heavyArmor: heavyArmor ?? this.heavyArmor,
      shields: shields ?? this.shields,
      simpleWeapons: simpleWeapons ?? this.simpleWeapons,
      martialWeapons: martialWeapons ?? this.martialWeapons,
      improvisedWeapons: improvisedWeapons ?? this.improvisedWeapons,
    );
  }

  List<String> get labels => [
        if (lightArmor) 'Light armor',
        if (mediumArmor) 'Medium armor',
        if (heavyArmor) 'Heavy armor',
        if (shields) 'Shields',
        if (simpleWeapons) 'Simple weapons',
        if (martialWeapons) 'Martial weapons',
        if (improvisedWeapons) 'Improvised weapons',
      ];
}

class CharacterSpellcastingSetup {
  const CharacterSpellcastingSetup({
    this.preparedMax = 0,
    this.slotTotals = const {},
  });

  final int preparedMax;
  final Map<int, int> slotTotals;

  factory CharacterSpellcastingSetup.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slotTotals'];
    final slots = <int, int>{};
    if (rawSlots is Map) {
      for (final entry in rawSlots.entries) {
        final level = int.tryParse(entry.key.toString());
        if (level != null && level >= 1 && level <= 9) {
          slots[level] = _intFromJson(entry.value);
        }
      }
    }
    return CharacterSpellcastingSetup(
      preparedMax: _intFromJson(json['preparedMax']),
      slotTotals: slots,
    );
  }

  Map<String, dynamic> toJson() => {
        'preparedMax': preparedMax,
        'slotTotals': {
          for (final entry in slotTotals.entries) '${entry.key}': entry.value,
        },
      };

  int slotTotal(int level) => slotTotals[level] ?? 0;
}

int _intFromJson(Object? value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<CharacterListEntry> characterEntryListFromJson(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is Map)
        CharacterListEntry.fromJson(Map<String, dynamic>.from(item)),
  ];
}

List<CharacterWeapon> characterWeaponListFromJson(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is Map) CharacterWeapon.fromJson(Map<String, dynamic>.from(item)),
  ];
}

DateTime _dateFromJson(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

class DiceRoll {
  const DiceRoll({
    required this.id,
    required this.diceCount,
    required this.sides,
    required this.modifier,
    required this.rolls,
    required this.total,
    required this.createdAt,
    this.rollType = 'Custom',
    this.label = '',
    this.formula = '',
  });

  final String id;
  final int diceCount;
  final int sides;
  final int modifier;
  final List<int> rolls;
  final int total;
  final DateTime createdAt;
  final String rollType;
  final String label;
  final String formula;

  factory DiceRoll.fromJson(Map<String, dynamic> json) {
    return DiceRoll(
      id: json['id'].toString(),
      diceCount: _intFromJson(json['diceCount'], 1),
      sides: _intFromJson(json['sides'], 20),
      modifier: _intFromJson(json['modifier']),
      rolls: List<int>.from(json['rolls'] as List? ?? const []),
      total: _intFromJson(json['total']),
      createdAt: _dateFromJson(json['createdAt']),
      rollType: json['rollType']?.toString() ?? 'Custom',
      label: json['label']?.toString() ?? '',
      formula: json['formula']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'diceCount': diceCount,
        'sides': sides,
        'modifier': modifier,
        'rolls': rolls,
        'total': total,
        'createdAt': createdAt.toIso8601String(),
        'rollType': rollType,
        'label': label,
        'formula': formula,
      };
}
