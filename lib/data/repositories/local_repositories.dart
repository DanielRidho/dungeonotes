import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/id_generator.dart';
import '../local/local_database.dart';
import '../models/app_models.dart';

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return CampaignRepository(ref.read(localDatabaseProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.read(localDatabaseProvider));
});

final questRepositoryProvider = Provider<QuestRepository>((ref) {
  return QuestRepository(ref.read(localDatabaseProvider));
});

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return CharacterRepository(ref.read(localDatabaseProvider));
});

final campaignCharacterStateRepositoryProvider =
    Provider<CampaignCharacterStateRepository>((ref) {
  return CampaignCharacterStateRepository(ref.read(localDatabaseProvider));
});

final worldNoteRepositoryProvider = Provider<WorldNoteRepository>((ref) {
  return WorldNoteRepository(ref.read(localDatabaseProvider));
});

final diceRepositoryProvider = Provider<DiceRepository>((ref) {
  return DiceRepository(ref.read(localDatabaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(localDatabaseProvider));
});

Map<String, dynamic> _asMap(Object? value) {
  return Map<String, dynamic>.from(value as Map);
}

class CampaignRepository {
  const CampaignRepository(this._database);

  final LocalDatabase _database;

  Future<List<Campaign>> watchableList() => getAll();

  Future<List<Campaign>> getAll() async {
    try {
      final items = _database.campaigns.values
          .map((value) => Campaign.fromJson(_asMap(value)))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    } catch (error) {
      throw AppException('Unable to load campaigns', error);
    }
  }

  Future<Campaign?> findById(String id) async {
    try {
      final value = _database.campaigns.get(id);
      if (value == null) {
        return null;
      }
      return Campaign.fromJson(_asMap(value));
    } catch (error) {
      throw AppException('Unable to load campaign', error);
    }
  }

  Future<void> save(Campaign campaign) async {
    try {
      await _database.campaigns.put(campaign.id, campaign.toJson());
    } catch (error) {
      throw AppException('Unable to save campaign', error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _database.campaigns.delete(id);
      await _deleteWhereCampaign(_database.sessions, id);
      await _deleteWhereCampaign(_database.quests, id);
      await _deleteWhereCampaign(_database.campaignCharacterStates, id);
      await _unlinkCharactersFromCampaign(id);
      await _deleteWhereCampaign(_database.worldNotes, id);
    } catch (error) {
      throw AppException('Unable to delete campaign', error);
    }
  }

  Future<void> _deleteWhereCampaign(dynamic box, String campaignId) async {
    final keys = <dynamic>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['campaignId'] == campaignId) {
        keys.add(key);
      }
    }
    await box.deleteAll(keys);
  }

  Future<void> _unlinkCharactersFromCampaign(String campaignId) async {
    for (final key in _database.characters.keys) {
      final value = _database.characters.get(key);
      if (value is! Map) {
        continue;
      }
      final character = CharacterNote.fromJson(_asMap(value));
      if (!character.campaignIds.contains(campaignId)) {
        continue;
      }
      if (character.campaignIds.length == 1) {
        await _database.characters.delete(key);
        continue;
      }
      final updated = character.copyWith(
        campaignIds: character.campaignIds
            .where((id) => id != campaignId)
            .toList(),
        updatedAt: DateTime.now(),
      );
      await _database.characters.put(key, updated.toJson());
    }
  }
}

class SessionRepository {
  const SessionRepository(this._database);

  final LocalDatabase _database;

  Future<List<SessionNote>> getByCampaign(String campaignId) async {
    try {
      final items = _database.sessions.values
          .map((value) => SessionNote.fromJson(_asMap(value)))
          .where((session) => session.campaignId == campaignId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return items;
    } catch (error) {
      throw AppException('Unable to load sessions', error);
    }
  }

  Future<void> save(SessionNote session) async {
    try {
      await _database.sessions.put(session.id, session.toJson());
    } catch (error) {
      throw AppException('Unable to save session', error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _database.sessions.delete(id);
    } catch (error) {
      throw AppException('Unable to delete session', error);
    }
  }
}

class QuestRepository {
  const QuestRepository(this._database);

  final LocalDatabase _database;

  Future<List<Quest>> getByCampaign(String campaignId) async {
    try {
      final items = _database.quests.values
          .map((value) => Quest.fromJson(_asMap(value)))
          .where((quest) => quest.campaignId == campaignId)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    } catch (error) {
      throw AppException('Unable to load quests', error);
    }
  }

  Future<void> save(Quest quest) async {
    try {
      await _database.quests.put(quest.id, quest.toJson());
    } catch (error) {
      throw AppException('Unable to save quest', error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _database.quests.delete(id);
    } catch (error) {
      throw AppException('Unable to delete quest', error);
    }
  }
}

class CharacterRepository {
  const CharacterRepository(this._database);

  final LocalDatabase _database;

  Future<List<CharacterNote>> getAll() async {
    try {
      final items = _database.characters.values
          .map((value) => CharacterNote.fromJson(_asMap(value)))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return items;
    } catch (error) {
      throw AppException('Unable to load character sheets', error);
    }
  }

  Future<List<CharacterNote>> getByCampaign(String campaignId) async {
    try {
      final items = _database.characters.values
          .map((value) => CharacterNote.fromJson(_asMap(value)))
          .where((character) => character.campaignIds.contains(campaignId))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return items;
    } catch (error) {
      throw AppException('Unable to load characters', error);
    }
  }

  Future<void> save(CharacterNote character) async {
    try {
      await _database.characters.put(character.id, character.toJson());
    } catch (error) {
      throw AppException('Unable to save character', error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _database.characters.delete(id);
    } catch (error) {
      throw AppException('Unable to delete character', error);
    }
  }
}

class CampaignCharacterStateRepository {
  const CampaignCharacterStateRepository(this._database);

  final LocalDatabase _database;

  Future<List<CampaignCharacterState>> getByCampaign(String campaignId) async {
    try {
      return _database.campaignCharacterStates.values
          .map((value) => CampaignCharacterState.fromJson(_asMap(value)))
          .where((state) => state.campaignId == campaignId)
          .toList();
    } catch (error) {
      throw AppException('Unable to load campaign character state', error);
    }
  }

  Future<CampaignCharacterState> getOrCreate({
    required String campaignId,
    required CharacterNote character,
  }) async {
    try {
      final id = '$campaignId:${character.id}';
      final value = _database.campaignCharacterStates.get(id);
      if (value != null) {
        return CampaignCharacterState.fromJson(_asMap(value));
      }
      final state = CampaignCharacterState.initial(
        campaignId: campaignId,
        character: character,
      );
      await save(state);
      return state;
    } catch (error) {
      throw AppException('Unable to prepare campaign character state', error);
    }
  }

  Future<void> save(CampaignCharacterState state) async {
    try {
      await _database.campaignCharacterStates.put(state.id, state.toJson());
    } catch (error) {
      throw AppException('Unable to save campaign character state', error);
    }
  }
}

class WorldNoteRepository {
  const WorldNoteRepository(this._database);

  final LocalDatabase _database;

  Future<List<WorldNote>> getByCampaign(String campaignId) async {
    try {
      final items = _database.worldNotes.values
          .map((value) => WorldNote.fromJson(_asMap(value)))
          .where((note) => note.campaignId == campaignId)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return items;
    } catch (error) {
      throw AppException('Unable to load NPC and location notes', error);
    }
  }

  Future<void> save(WorldNote note) async {
    try {
      await _database.worldNotes.put(note.id, note.toJson());
    } catch (error) {
      throw AppException('Unable to save NPC or location note', error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _database.worldNotes.delete(id);
    } catch (error) {
      throw AppException('Unable to delete NPC or location note', error);
    }
  }
}

class DiceRepository {
  const DiceRepository(this._database);

  final LocalDatabase _database;

  Future<List<DiceRoll>> getHistory() async {
    try {
      final items = _database.diceHistory.values
          .map((value) => DiceRoll.fromJson(_asMap(value)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items.take(AppConstants.maxDiceHistory).toList();
    } catch (error) {
      throw AppException('Unable to load dice history', error);
    }
  }

  Future<DiceRoll> recordRoll({
    required List<int> sides,
    required List<int> rolls,
    required int modifier,
    required int total,
    String rollType = 'Dice',
    String label = '',
  }) async {
    if (sides.isEmpty || sides.length != rolls.length) {
      throw const AppException('Dice results are incomplete');
    }
    if (sides.length > AppConstants.maxDiceCount) {
      throw const AppException('Dice count must be between 1 and 50');
    }
    if (sides.any((value) => value < 2)) {
      throw const AppException('Dice sides must be at least 2');
    }

    try {
      final uniformSides = sides.every((value) => value == sides.first);
      final roll = DiceRoll(
        id: IdGenerator.create(),
        diceCount: sides.length,
        sides: uniformSides ? sides.first : 0,
        modifier: modifier,
        rolls: rolls,
        total: total,
        createdAt: DateTime.now(),
        rollType: rollType,
        label: label,
        formula: _mixedDiceFormula(sides, modifier),
      );
      return _saveRoll(roll);
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException('Unable to roll dice', error);
    }
  }

  Future<DiceRoll> _saveRoll(DiceRoll roll) async {
    await _database.diceHistory.put(roll.id, roll.toJson());
    final history = _database.diceHistory.values
        .map((value) => DiceRoll.fromJson(_asMap(value)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (history.length > AppConstants.maxDiceHistory) {
      final stale = history.skip(AppConstants.maxDiceHistory).map((e) => e.id);
      await _database.diceHistory.deleteAll(stale);
    }
    return roll;
  }

  String _mixedDiceFormula(List<int> sides, int modifier) {
    final counts = <int, int>{};
    for (final side in sides) {
      counts[side] = (counts[side] ?? 0) + 1;
    }
    final formula = counts.entries
        .map((entry) => entry.value == 1 ? 'd${entry.key}' : '${entry.value}d${entry.key}')
        .join(' + ');
    if (modifier > 0) {
      return '$formula + $modifier';
    }
    if (modifier < 0) {
      return '$formula - ${modifier.abs()}';
    }
    return formula;
  }

  Future<void> clearHistory() async {
    try {
      await _database.diceHistory.clear();
    } catch (error) {
      throw AppException('Unable to clear dice history', error);
    }
  }
}

class SettingsRepository {
  const SettingsRepository(this._database);

  static const _onboardingKey = 'onboarding_seen';
  static const _themeKey = 'theme_choice';

  final LocalDatabase _database;

  Future<bool> getOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingSeen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, value);
  }

  Future<ThemeChoice> getThemeChoice() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_themeKey);
    return ThemeChoice.values.firstWhere(
      (choice) => choice.name == name,
      orElse: () => ThemeChoice.system,
    );
  }

  Future<void> setThemeChoice(ThemeChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, choice.name);
  }

  Future<void> clearAllLocalData() => _database.clearAllData();
}
