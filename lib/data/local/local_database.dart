import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/id_generator.dart';
import '../models/app_models.dart';

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});

class LocalDatabase {
  Box<dynamic>? _campaigns;
  Box<dynamic>? _sessions;
  Box<dynamic>? _quests;
  Box<dynamic>? _characters;
  Box<dynamic>? _campaignCharacterStates;
  Box<dynamic>? _worldNotes;
  Box<dynamic>? _diceHistory;
  bool _initialized = false;

  Box<dynamic> get campaigns => _box(_campaigns, 'campaigns');
  Box<dynamic> get sessions => _box(_sessions, 'sessions');
  Box<dynamic> get quests => _box(_quests, 'quests');
  Box<dynamic> get characters => _box(_characters, 'characters');
  Box<dynamic> get campaignCharacterStates =>
      _box(_campaignCharacterStates, 'campaign_character_states');
  Box<dynamic> get worldNotes => _box(_worldNotes, 'world_notes');
  Box<dynamic> get diceHistory => _box(_diceHistory, 'dice_history');

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {
      await Hive.initFlutter();
      _campaigns = await Hive.openBox<dynamic>('campaigns');
      _sessions = await Hive.openBox<dynamic>('sessions');
      _quests = await Hive.openBox<dynamic>('quests');
      _characters = await Hive.openBox<dynamic>('characters');
      _campaignCharacterStates =
          await Hive.openBox<dynamic>('campaign_character_states');
      _worldNotes = await Hive.openBox<dynamic>('world_notes');
      _diceHistory = await Hive.openBox<dynamic>('dice_history');
      _initialized = true;

      if (AppConstants.enableDevSeed) {
        await _seedDevelopmentData();
      }
    } catch (error) {
      throw AppException('Unable to open local storage', error);
    }
  }

  Future<void> clearAllData() async {
    try {
      await campaigns.clear();
      await sessions.clear();
      await quests.clear();
      await characters.clear();
      await campaignCharacterStates.clear();
      await worldNotes.clear();
      await diceHistory.clear();
    } catch (error) {
      throw AppException('Unable to clear local data', error);
    }
  }

  Box<dynamic> _box(Box<dynamic>? box, String name) {
    if (box == null || !box.isOpen) {
      throw AppException('Local box "$name" is not open');
    }
    return box;
  }

  Future<void> _seedDevelopmentData() async {
    if (campaigns.isNotEmpty) {
      return;
    }

    final now = DateTime.now();
    final campaignId = IdGenerator.create();
    final sessionId = IdGenerator.create();
    final questId = IdGenerator.create();
    final characterId = IdGenerator.create();
    final worldId = IdGenerator.create();

    final campaign = Campaign(
      id: campaignId,
      title: 'Ashfall Expedition',
      systemName: AppConstants.defaultSystemName,
      description: 'A frontier trek toward a quiet valley under ember skies.',
      partyName: 'The Hollow Lantern',
      createdAt: now,
      updatedAt: now,
    );
    final session = SessionNote(
      id: sessionId,
      campaignId: campaignId,
      title: 'Arrival at Old Greyford',
      date: now,
      summary: 'The party reached a river town preparing for a night market.',
      importantEvents:
          'A sealed brass map case was found beneath a collapsed bridge.',
      loot: 'Brass map case, rain-stained travel ledger.',
      nextSessionReminderNote: 'Ask Mira Thorn about the missing ferryman.',
      createdAt: now,
      updatedAt: now,
    );
    final quest = Quest(
      id: questId,
      campaignId: campaignId,
      title: 'The Hollow Lantern',
      description: 'Track the origin of a lantern that burns without oil.',
      relatedNpc: 'Mira Thorn',
      relatedLocation: 'Old Greyford',
      rewardNote: 'A favor from the river wardens.',
      status: QuestStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    final character = CharacterNote(
      id: characterId,
      campaignIds: [campaignId],
      name: 'Mira Thorn',
      playerName: 'Dev Seed',
      ancestryOrSpecies: 'Human',
      className: 'Wayfinder',
      speciesRefId: '',
      classRefId: '',
      backgroundRefId: '',
      subclassName: '',
      subclassRefId: '',
      level: 3,
      background: 'Guide with a knack for old roads.',
      pronouns: '',
      alignment: '',
      experiencePoints: 900,
      proficiencyBonus: 2,
      hp: 24,
      currentHp: 24,
      temporaryHp: 0,
      hitDice: '3 notes',
      deathSaveSuccesses: 0,
      deathSaveFailures: 0,
      armorClass: 14,
      armorRefId: '',
      armorName: '',
      shieldEquipped: false,
      size: 'Medium',
      speed: 30,
      initiative: 2,
      passivePerception: 13,
      strength: 10,
      dexterity: 14,
      constitution: 12,
      intelligence: 11,
      wisdom: 13,
      charisma: 10,
      inventoryNotes: 'Weathered cloak, field journal, spare rope.',
      attackNotes: 'Shortbow, utility knife, improvised plans.',
      featureNotes: 'Knows old road signs and river customs.',
      skillNotes: 'Keen at navigation, rumors, and noticing trail marks.',
      savingThrowNotes: '',
      personalityNotes: 'Patient, dry humor, dislikes needless risks.',
      toolAndLanguageNotes: 'Cartography kit notes, local dialect notes.',
      treasureNotes: '',
      skillProficiencies: const {},
      savingThrowProficiencies: const {},
      selectedFeatureIds: const [],
      selectedFeatIds: const [],
      selectedTraitIds: const [],
      selectedWeaponIds: const [],
      selectedArmorIds: const [],
      selectedGearIds: const [],
      selectedSpellIds: const [],
      spellcastingAbility: 'wisdom',
      coinsNotes: '',
      weapons: const [],
      armors: const [],
      gear: const [],
      treasures: const [],
      classFeatures: const [],
      speciesTraits: const [],
      feats: const [],
      toolProficiencies: const [],
      languages: const [],
      coins: const CharacterCoins(),
      training: const CharacterTraining(),
      spellcastingSetup: const CharacterSpellcastingSetup(),
      spellNotes: const [],
      createdAt: now,
      updatedAt: now,
    );
    final worldNote = WorldNote(
      id: worldId,
      campaignId: campaignId,
      name: 'Old Greyford',
      type: WorldNoteType.location,
      description: 'A misty crossing town built around a stone bridge.',
      relationshipStatus: 'Friendly but wary',
      tags: const ['river', 'market', 'rumors'],
      lastSeenSession: 'Arrival at Old Greyford',
      createdAt: now,
      updatedAt: now,
    );

    await campaigns.put(campaign.id, campaign.toJson());
    await sessions.put(session.id, session.toJson());
    await quests.put(quest.id, quest.toJson());
    await characters.put(character.id, character.toJson());
    await worldNotes.put(worldNote.id, worldNote.toJson());
  }
}
