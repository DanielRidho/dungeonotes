import 'package:flutter/material.dart';

import '../../core/utils/id_generator.dart';
import '../../data/models/app_models.dart';
import '../../data/models/reference_models.dart';

List<CharacterListEntry> legacyCharacterEntries(String text) {
  return text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) => CharacterListEntry(id: IdGenerator.create(), name: line))
      .toList();
}

String characterEntrySummary(List<CharacterListEntry> entries) {
  return entries.map((entry) {
    final name = entry.quantity > 1 ? '${entry.name} x${entry.quantity}' : entry.name;
    if (entry.description.trim().isEmpty) {
      return name;
    }
    return '$name: ${entry.description}';
  }).join('\n');
}

String characterWeaponSummary(List<CharacterWeapon> weapons) {
  return weapons.map((weapon) {
    final attack = weapon.attackLabel.isEmpty ? '' : ' - ${weapon.attackLabel}';
    final damage = weapon.damageLabel.isEmpty ? '' : ': ${weapon.damageLabel}';
    return '${weapon.name}$damage$attack';
  }).join('\n');
}

List<String> spellComponentsFromEntry(ReferenceEntry entry) {
  final text = entry.property('Components').toUpperCase();
  return [
    for (final component in const ['C', 'R', 'V', 'S', 'M'])
      if (text.contains(component)) component,
  ];
}

List<SpellNote> sortSpellNotes(List<SpellNote> spells) {
  return List<SpellNote>.of(spells)
    ..sort((a, b) {
      final level = _spellLevelNumber(a).compareTo(_spellLevelNumber(b));
      if (level != 0) {
        return level;
      }
      return a.spellName.compareTo(b.spellName);
    });
}

String keptWeaponId(List<CharacterWeapon> weapons, String id) {
  for (final weapon in weapons) {
    if (weapon.id == id) {
      return id;
    }
  }
  return '';
}

String keptEntryId(List<CharacterListEntry> entries, String id) {
  for (final entry in entries) {
    if (entry.id == id) {
      return id;
    }
  }
  return '';
}

String? validateRequiredCharacterFields({
  required TextEditingController name,
  required TextEditingController species,
  required TextEditingController className,
  required TextEditingController background,
  required TextEditingController alignment,
  required TextEditingController size,
  required TextEditingController hitDice,
  required TextEditingController maxHp,
  required TextEditingController armorClass,
  required TextEditingController speed,
  required TextEditingController subclass,
  required int level,
}) {
  for (final field in [
    ('character name', name),
    ('species', species),
    ('class', className),
    ('background', background),
    ('alignment', alignment),
    ('size', size),
    ('hit dice', hitDice),
    ('max HP', maxHp),
    ('armor class', armorClass),
    ('speed', speed),
  ]) {
    if (field.$2.text.trim().isEmpty) {
      return 'Please fill ${field.$1}.';
    }
  }
  if (level >= 3 && subclass.text.trim().isEmpty) {
    return 'Please fill subclass for level 3 or higher.';
  }
  return null;
}

int _spellLevelNumber(SpellNote spell) {
  final value = spell.spellLevel.trim().toLowerCase();
  if (value.isEmpty || value == 'cantrip') {
    return 0;
  }
  return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}
