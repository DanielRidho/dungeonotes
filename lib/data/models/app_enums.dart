enum QuestStatus { active, completed, failed, onHold }

enum WorldNoteType { npc, location }

enum NpcRelationship { ally, neutral, enemy, unknown }

enum NpcStatus { alive, dead, missing, unknown }

enum ThemeChoice { system, light, dark }

extension QuestStatusLabel on QuestStatus {
  String get label {
    return switch (this) {
      QuestStatus.active => 'Active',
      QuestStatus.completed => 'Completed',
      QuestStatus.failed => 'Failed',
      QuestStatus.onHold => 'On hold',
    };
  }
}

extension WorldNoteTypeLabel on WorldNoteType {
  String get label {
    return switch (this) {
      WorldNoteType.npc => 'NPC',
      WorldNoteType.location => 'Location',
    };
  }
}

extension NpcRelationshipLabel on NpcRelationship {
  String get label {
    return switch (this) {
      NpcRelationship.ally => 'Ally',
      NpcRelationship.neutral => 'Neutral',
      NpcRelationship.enemy => 'Enemy',
      NpcRelationship.unknown => 'Unknown',
    };
  }
}

extension NpcStatusLabel on NpcStatus {
  String get label {
    return switch (this) {
      NpcStatus.alive => 'Alive',
      NpcStatus.dead => 'Dead',
      NpcStatus.missing => 'Missing',
      NpcStatus.unknown => 'Unknown',
    };
  }
}

extension ThemeChoiceLabel on ThemeChoice {
  String get label {
    return switch (this) {
      ThemeChoice.system => 'System',
      ThemeChoice.light => 'Light',
      ThemeChoice.dark => 'Dark',
    };
  }
}
