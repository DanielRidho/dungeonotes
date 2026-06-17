import '../../data/models/reference_models.dart';
import 'character_rules.dart';

class CharacterReferenceExtractors {
  const CharacterReferenceExtractors._();

  static String hitDie(String description) {
    final match = RegExp(r'Hit Dice:\s*(1d\d+)', caseSensitive: false)
        .firstMatch(description);
    return match?.group(1)?.trim() ?? '';
  }

  static String spellcastingAbility(String description) {
    final lower = description.toLowerCase();
    for (final entry in abilityLabels.entries) {
      final label = entry.value.toLowerCase();
      if (lower.contains('${entry.key} is your spellcasting ability') ||
          lower.contains('$label is your spellcasting ability')) {
        return entry.key;
      }
    }
    return '';
  }

  static int? speed(String description) {
    final patterns = [
      RegExp(r'walking speed is (\d+) feet', caseSensitive: false),
      RegExp(r'base walking speed is (\d+) feet', caseSensitive: false),
      RegExp(
        r'Speed\.\s*(?:Your )?(?:base )?walking speed is (\d+) feet',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(description);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static String size(String description) {
    final direct = RegExp(r'Your size is ([A-Za-z ]+)\.', caseSensitive: false)
        .firstMatch(description);
    if (direct != null) {
      return direct.group(1)?.trim() ?? '';
    }
    final either = RegExp(
      r'You are ((?:Medium|Small|Large)(?: or (?:Medium|Small|Large))?)',
      caseSensitive: false,
    ).firstMatch(description);
    return either?.group(1)?.trim() ?? '';
  }

  static String damage(String description) {
    final match = RegExp(r'Damage:\s*([^\.]+)', caseSensitive: false)
        .firstMatch(description);
    return match?.group(1)?.trim() ?? '';
  }

  static bool isWeapon(ReferenceEntry entry) {
    return entry.property('Item Type').toLowerCase().contains('weapon');
  }

  static bool isArmor(ReferenceEntry entry) {
    final type = entry.property('Item Type').toLowerCase();
    return !isShield(entry) &&
        (type.contains('armor') || entry.name.toLowerCase().contains('armor'));
  }

  static bool isShield(ReferenceEntry entry) {
    final type = entry.property('Item Type').toLowerCase();
    final name = entry.name.toLowerCase();
    return type.contains('shield') || name.contains('shield');
  }

  static bool isItem(ReferenceEntry entry) {
    final type = entry.property('Item Type').toLowerCase();
    return type.isNotEmpty &&
        !type.contains('weapon') &&
        !type.contains('armor') &&
        !type.contains('shield') &&
        !isShield(entry);
  }
}
