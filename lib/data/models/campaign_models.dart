part of 'app_models.dart';

class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.systemName,
    required this.description,
    required this.partyName,
    required this.createdAt,
    required this.updatedAt,
    this.colorTag = 0xFF9C7A2F,
    this.currentLocation = '',
    this.worldDay = '',
    this.worldDate = '',
    this.worldTime = '',
    this.sharedLoot = const [],
    this.players = const [],
    this.imagePath = '',
  });

  final String id;
  final String title;
  final String systemName;
  final String description;
  final String partyName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int colorTag;
  final String currentLocation;
  final String worldDay;
  final String worldDate;
  final String worldTime;
  final List<CharacterListEntry> sharedLoot;
  final List<CampaignPlayer> players;
  final String imagePath;

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      systemName:
          json['systemName']?.toString() ?? AppConstants.defaultSystemName,
      description: json['description']?.toString() ?? '',
      partyName: json['partyName']?.toString() ?? '',
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: _dateFromJson(json['updatedAt']),
      colorTag: _intFromJson(json['colorTag'], 0xFF9C7A2F),
      currentLocation: json['currentLocation']?.toString() ?? '',
      worldDay: json['worldDay']?.toString() ?? '',
      worldDate: json['worldDate']?.toString() ?? '',
      worldTime: json['worldTime']?.toString() ?? '',
      sharedLoot: characterEntryListFromJson(json['sharedLoot']),
      players: campaignPlayersFromJson(json['players']),
      imagePath: json['imagePath']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'systemName': systemName,
        'description': description,
        'partyName': partyName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'colorTag': colorTag,
        'currentLocation': currentLocation,
        'worldDay': worldDay,
        'worldDate': worldDate,
        'worldTime': worldTime,
        'sharedLoot': sharedLoot.map((entry) => entry.toJson()).toList(),
        'players': players.map((player) => player.toJson()).toList(),
        'imagePath': imagePath,
      };

  Campaign copyWith({
    String? title,
    String? systemName,
    String? description,
    String? partyName,
    DateTime? updatedAt,
    int? colorTag,
    String? currentLocation,
    String? worldDay,
    String? worldDate,
    String? worldTime,
    List<CharacterListEntry>? sharedLoot,
    List<CampaignPlayer>? players,
    String? imagePath,
  }) {
    return Campaign(
      id: id,
      title: title ?? this.title,
      systemName: systemName ?? this.systemName,
      description: description ?? this.description,
      partyName: partyName ?? this.partyName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorTag: colorTag ?? this.colorTag,
      currentLocation: currentLocation ?? this.currentLocation,
      worldDay: worldDay ?? this.worldDay,
      worldDate: worldDate ?? this.worldDate,
      worldTime: worldTime ?? this.worldTime,
      sharedLoot: sharedLoot ?? this.sharedLoot,
      players: players ?? this.players,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class CampaignPlayer {
  const CampaignPlayer({
    required this.id,
    required this.characterName,
    required this.playerName,
    required this.className,
    required this.species,
    required this.level,
    required this.description,
  });

  final String id;
  final String characterName;
  final String playerName;
  final String className;
  final String species;
  final int level;
  final String description;

  factory CampaignPlayer.fromJson(Map<String, dynamic> json) {
    final level = _intFromJson(json['level'], 1);
    return CampaignPlayer(
      id: json['id']?.toString() ?? '',
      characterName: json['characterName']?.toString() ?? '',
      playerName: json['playerName']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      species: json['species']?.toString() ?? '',
      level: level.clamp(1, 20),
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'characterName': characterName,
        'playerName': playerName,
        'className': className,
        'species': species,
        'level': level,
        'description': description,
      };

  CampaignPlayer copyWith({
    String? id,
    String? characterName,
    String? playerName,
    String? className,
    String? species,
    int? level,
    String? description,
  }) {
    return CampaignPlayer(
      id: id ?? this.id,
      characterName: characterName ?? this.characterName,
      playerName: playerName ?? this.playerName,
      className: className ?? this.className,
      species: species ?? this.species,
      level: level ?? this.level,
      description: description ?? this.description,
    );
  }
}

List<CampaignPlayer> campaignPlayersFromJson(Object? value) {
  return value is List
      ? value
          .whereType<Map>()
          .map((item) => CampaignPlayer.fromJson(Map<String, dynamic>.from(item)))
          .toList()
      : const [];
}

class SessionNote {
  const SessionNote({
    required this.id,
    required this.campaignId,
    required this.title,
    required this.date,
    required this.summary,
    required this.importantEvents,
    required this.loot,
    required this.nextSessionReminderNote,
    required this.createdAt,
    required this.updatedAt,
    this.npcsMet = const [],
    this.locationsVisited = const [],
    this.eventEntries = const [],
    this.lootEntries = const [],
  });

  final String id;
  final String campaignId;
  final String title;
  final DateTime date;
  final String summary;
  final String importantEvents;
  final String loot;
  final String nextSessionReminderNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> npcsMet;
  final List<String> locationsVisited;
  final List<SessionEventEntry> eventEntries;
  final List<SessionLootEntry> lootEntries;

  factory SessionNote.fromJson(Map<String, dynamic> json) {
    final importantEvents = json['importantEvents']?.toString() ?? '';
    final loot = json['loot']?.toString() ?? '';
    final updatedAt = _dateFromJson(json['updatedAt']);
    final eventEntries = sessionEventEntriesFromJson(json['eventEntries']);
    final lootEntries = sessionLootEntriesFromJson(json['lootEntries']);
    return SessionNote(
      id: json['id'].toString(),
      campaignId: json['campaignId'].toString(),
      title: json['title']?.toString() ?? '',
      date: _dateFromJson(json['date']),
      summary: json['summary']?.toString() ?? '',
      importantEvents: importantEvents,
      loot: loot,
      nextSessionReminderNote:
          json['nextSessionReminderNote']?.toString() ?? '',
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: updatedAt,
      npcsMet: _stringListFromJson(json['npcsMet']),
      locationsVisited: _stringListFromJson(json['locationsVisited']),
      eventEntries: eventEntries.isEmpty && importantEvents.isNotEmpty
          ? [
              SessionEventEntry(
                id: 'legacy-event',
                title: 'Important Events',
                description: importantEvents,
                updatedAt: updatedAt,
              ),
            ]
          : eventEntries,
      lootEntries: lootEntries.isEmpty && loot.isNotEmpty
          ? [
              SessionLootEntry(
                id: 'legacy-loot',
                name: 'Loot',
                description: loot,
                updatedAt: updatedAt,
              ),
            ]
          : lootEntries,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaignId': campaignId,
        'title': title,
        'date': date.toIso8601String(),
        'summary': summary,
        'importantEvents': importantEvents,
        'loot': loot,
        'nextSessionReminderNote': nextSessionReminderNote,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'npcsMet': npcsMet,
        'locationsVisited': locationsVisited,
        'eventEntries': eventEntries.map((entry) => entry.toJson()).toList(),
        'lootEntries': lootEntries.map((entry) => entry.toJson()).toList(),
      };

  SessionNote copyWith({
    String? title,
    DateTime? date,
    String? summary,
    String? importantEvents,
    String? loot,
    String? nextSessionReminderNote,
    DateTime? updatedAt,
    List<String>? npcsMet,
    List<String>? locationsVisited,
    List<SessionEventEntry>? eventEntries,
    List<SessionLootEntry>? lootEntries,
  }) {
    return SessionNote(
      id: id,
      campaignId: campaignId,
      title: title ?? this.title,
      date: date ?? this.date,
      summary: summary ?? this.summary,
      importantEvents: importantEvents ?? this.importantEvents,
      loot: loot ?? this.loot,
      nextSessionReminderNote:
          nextSessionReminderNote ?? this.nextSessionReminderNote,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      npcsMet: npcsMet ?? this.npcsMet,
      locationsVisited: locationsVisited ?? this.locationsVisited,
      eventEntries: eventEntries ?? this.eventEntries,
      lootEntries: lootEntries ?? this.lootEntries,
    );
  }
}

class SessionEventEntry {
  const SessionEventEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime updatedAt;

  factory SessionEventEntry.fromJson(Map<String, dynamic> json) {
    return SessionEventEntry(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      updatedAt: _dateFromJson(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'updatedAt': updatedAt.toIso8601String(),
      };

  SessionEventEntry copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? updatedAt,
  }) {
    return SessionEventEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SessionLootEntry {
  const SessionLootEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.updatedAt,
    this.quantity = 1,
    this.claimed = false,
  });

  final String id;
  final String name;
  final String description;
  final DateTime updatedAt;
  final int quantity;
  final bool claimed;

  factory SessionLootEntry.fromJson(Map<String, dynamic> json) {
    final quantity = _intFromJson(json['quantity'], 1);
    return SessionLootEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      updatedAt: _dateFromJson(json['updatedAt']),
      quantity: quantity < 1 ? 1 : quantity,
      claimed: _boolFromJson(json['claimed']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'updatedAt': updatedAt.toIso8601String(),
        'quantity': quantity,
        'claimed': claimed,
      };

  SessionLootEntry copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? updatedAt,
    int? quantity,
    bool? claimed,
  }) {
    return SessionLootEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
      quantity: quantity ?? this.quantity,
      claimed: claimed ?? this.claimed,
    );
  }
}

List<SessionEventEntry> sessionEventEntriesFromJson(Object? value) {
  return value is List
      ? value
          .whereType<Map>()
          .map((item) =>
              SessionEventEntry.fromJson(Map<String, dynamic>.from(item)))
          .toList()
      : const [];
}

List<SessionLootEntry> sessionLootEntriesFromJson(Object? value) {
  return value is List
      ? value
          .whereType<Map>()
          .map((item) =>
              SessionLootEntry.fromJson(Map<String, dynamic>.from(item)))
          .toList()
      : const [];
}

class Quest {
  const Quest({
    required this.id,
    required this.campaignId,
    required this.title,
    required this.description,
    required this.relatedNpc,
    required this.relatedLocation,
    required this.rewardNote,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.objectives = const [],
    this.deadline = '',
  });

  final String id;
  final String campaignId;
  final String title;
  final String description;
  final String relatedNpc;
  final String relatedLocation;
  final String rewardNote;
  final QuestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CharacterListEntry> objectives;
  final String deadline;

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'].toString(),
      campaignId: json['campaignId'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      relatedNpc: json['relatedNpc']?.toString() ?? '',
      relatedLocation: json['relatedLocation']?.toString() ?? '',
      rewardNote: json['rewardNote']?.toString() ?? '',
      status: QuestStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => QuestStatus.active,
      ),
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: _dateFromJson(json['updatedAt']),
      objectives: characterEntryListFromJson(json['objectives']),
      deadline: json['deadline']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaignId': campaignId,
        'title': title,
        'description': description,
        'relatedNpc': relatedNpc,
        'relatedLocation': relatedLocation,
        'rewardNote': rewardNote,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'objectives': objectives.map((entry) => entry.toJson()).toList(),
        'deadline': deadline,
      };

  Quest copyWith({
    String? title,
    String? description,
    String? relatedNpc,
    String? relatedLocation,
    String? rewardNote,
    QuestStatus? status,
    DateTime? updatedAt,
    List<CharacterListEntry>? objectives,
    String? deadline,
  }) {
    return Quest(
      id: id,
      campaignId: campaignId,
      title: title ?? this.title,
      description: description ?? this.description,
      relatedNpc: relatedNpc ?? this.relatedNpc,
      relatedLocation: relatedLocation ?? this.relatedLocation,
      rewardNote: rewardNote ?? this.rewardNote,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      objectives: objectives ?? this.objectives,
      deadline: deadline ?? this.deadline,
    );
  }
}

