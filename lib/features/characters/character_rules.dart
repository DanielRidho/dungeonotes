import '../../data/models/app_models.dart';

const abilityLabels = {
  'strength': 'Strength',
  'dexterity': 'Dexterity',
  'constitution': 'Constitution',
  'intelligence': 'Intelligence',
  'wisdom': 'Wisdom',
  'charisma': 'Charisma',
};

const skillAbilities = {
  'Acrobatics': 'dexterity',
  'Animal Handling': 'wisdom',
  'Arcana': 'intelligence',
  'Athletics': 'strength',
  'Deception': 'charisma',
  'History': 'intelligence',
  'Insight': 'wisdom',
  'Intimidation': 'charisma',
  'Investigation': 'intelligence',
  'Medicine': 'wisdom',
  'Nature': 'intelligence',
  'Perception': 'wisdom',
  'Performance': 'charisma',
  'Persuasion': 'charisma',
  'Religion': 'intelligence',
  'Sleight of Hand': 'dexterity',
  'Stealth': 'dexterity',
  'Survival': 'wisdom',
};

const hitDiceOptions = ['1d4', '1d6', '1d8', '1d10', '1d12', '1d20', '1d100'];

enum ProficiencyRank { none, proficient, expertise }

extension ProficiencyRankLabel on ProficiencyRank {
  String get label {
    return switch (this) {
      ProficiencyRank.none => 'None',
      ProficiencyRank.proficient => 'Proficient',
      ProficiencyRank.expertise => 'Expertise',
    };
  }
}

class CharacterRules {
  const CharacterRules._();

  static int proficiencyBonus(int level) {
    if (level >= 17) {
      return 6;
    }
    if (level >= 13) {
      return 5;
    }
    if (level >= 9) {
      return 4;
    }
    if (level >= 5) {
      return 3;
    }
    return 2;
  }

  static int modifier(int score) => ((score - 10) / 2).floor();

  static String abilityCode(String ability) {
    return switch (ability) {
      'strength' => 'STR',
      'dexterity' => 'DEX',
      'constitution' => 'CON',
      'intelligence' => 'INT',
      'wisdom' => 'WIS',
      'charisma' => 'CHA',
      _ => ability.toUpperCase(),
    };
  }

  static int abilityScore(CharacterNote character, String ability) {
    return switch (ability) {
      'strength' => character.strength,
      'dexterity' => character.dexterity,
      'constitution' => character.constitution,
      'intelligence' => character.intelligence,
      'wisdom' => character.wisdom,
      'charisma' => character.charisma,
      _ => 10,
    };
  }

  static int skillTotal(
    CharacterNote character,
    String skillName,
    ProficiencyRank rank,
  ) {
    final ability = skillAbilities[skillName] ?? 'strength';
    final base = modifier(abilityScore(character, ability));
    final proficiency = proficiencyBonus(character.level);
    return switch (rank) {
      ProficiencyRank.none => base,
      ProficiencyRank.proficient => base + proficiency,
      ProficiencyRank.expertise => base + proficiency * 2,
    };
  }

  static int savingThrowTotal(
    CharacterNote character,
    String ability,
    bool proficient,
  ) {
    final base = modifier(abilityScore(character, ability));
    return proficient ? base + proficiencyBonus(character.level) : base;
  }

  static int spellSaveDc(CharacterNote character, String ability) {
    return 8 +
        proficiencyBonus(character.level) +
        modifier(abilityScore(character, ability));
  }

  static int spellAttackBonus(CharacterNote character, String ability) {
    return proficiencyBonus(character.level) +
        modifier(abilityScore(character, ability));
  }
}
