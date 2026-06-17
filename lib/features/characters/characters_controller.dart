import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_generator.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';

final charactersControllerProvider = StateNotifierProvider.family<
    CharactersController,
    AsyncValue<List<CharacterNote>>,
    String>((ref, campaignId) {
  return CharactersController(
    ref.read(characterRepositoryProvider),
    campaignId,
  )..load();
});

final allCharactersControllerProvider =
    StateNotifierProvider<AllCharactersController, AsyncValue<List<CharacterNote>>>(
  (ref) => AllCharactersController(ref.read(characterRepositoryProvider))..load(),
);

final campaignCharacterStatesControllerProvider = StateNotifierProvider.family<
    CampaignCharacterStatesController,
    AsyncValue<List<CampaignCharacterState>>,
    String>((ref, campaignId) {
  return CampaignCharacterStatesController(
    ref.read(campaignCharacterStateRepositoryProvider),
    campaignId,
  )..load();
});

class CampaignCharacterStatesController
    extends StateNotifier<AsyncValue<List<CampaignCharacterState>>> {
  CampaignCharacterStatesController(this._repository, this._campaignId)
      : super(const AsyncValue.loading());

  final CampaignCharacterStateRepository _repository;
  final String _campaignId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getByCampaign(_campaignId));
  }

  Future<CampaignCharacterState> ensure(CharacterNote character) async {
    final result = await _repository.getOrCreate(
      campaignId: _campaignId,
      character: character,
    );
    await load();
    return result;
  }

  Future<void> save(CampaignCharacterState characterState) async {
    await _repository.save(
      characterState.copyWith(updatedAt: DateTime.now()),
    );
    await load();
  }

  Future<void> saveInPlace(CampaignCharacterState characterState) async {
    final updatedState = characterState.copyWith(updatedAt: DateTime.now());
    await _repository.save(updatedState);
    replaceLocal(updatedState);
  }

  void replaceLocal(CampaignCharacterState characterState) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final updated = <CampaignCharacterState>[];
    var replaced = false;
    for (final item in current) {
      if (item.id == characterState.id) {
        updated.add(characterState);
        replaced = true;
      } else {
        updated.add(item);
      }
    }
    if (!replaced) {
      updated.add(characterState);
    }
    state = AsyncValue.data(updated);
  }
}

class AllCharactersController
    extends StateNotifier<AsyncValue<List<CharacterNote>>> {
  AllCharactersController(this._repository) : super(const AsyncValue.loading());

  final CharacterRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final characters = await _repository.getAll();
      return characters
          .where((character) => character.campaignIds.isEmpty)
          .toList();
    });
  }

  Future<void> save(CharacterNote character) async {
    await _repository.save(character);
    await load();
  }

  Future<void> saveInPlace(CharacterNote character) async {
    await _repository.save(character);
    replaceLocal(character);
  }

  void replaceLocal(CharacterNote character) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncValue.data(_upsertCharacter(current, character));
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }
}

class CharactersController
    extends StateNotifier<AsyncValue<List<CharacterNote>>> {
  CharactersController(this._repository, this._campaignId)
      : super(const AsyncValue.loading());

  final CharacterRepository _repository;
  final String _campaignId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getByCampaign(_campaignId));
  }

  Future<void> save(CharacterNote character) async {
    await _repository.save(character);
    await load();
  }

  Future<void> saveInPlace(CharacterNote character) async {
    await _repository.save(character);
    replaceLocal(character);
  }

  void replaceLocal(CharacterNote character) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncValue.data(
      _upsertCharacter(
        current,
        character,
        campaignId: _campaignId,
      ),
    );
  }

  Future<void> link(CharacterNote character) async {
    final now = DateTime.now();
    await _repository.save(
      character.copyWith(
        id: IdGenerator.create(),
        campaignIds: [_campaignId],
        createdAt: now,
        updatedAt: now,
      ),
    );
    await load();
  }

  Future<void> unlink(CharacterNote character) async {
    await _repository.delete(character.id);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  CharacterNote createDraft() {
    final now = DateTime.now();
    return CharacterNote(
      id: IdGenerator.create(),
      campaignIds: [_campaignId],
      name: '',
      playerName: '',
      ancestryOrSpecies: '',
      className: '',
      speciesRefId: '',
      classRefId: '',
      backgroundRefId: '',
      subclassName: '',
      subclassRefId: '',
      level: 1,
      background: '',
      pronouns: '',
      alignment: '',
      experiencePoints: 0,
      proficiencyBonus: 2,
      hp: 0,
      currentHp: 0,
      temporaryHp: 0,
      hitDice: '',
      deathSaveSuccesses: 0,
      deathSaveFailures: 0,
      armorClass: 10,
      armorRefId: '',
      armorName: '',
      shieldEquipped: false,
      size: 'Medium',
      speed: 30,
      initiative: 0,
      passivePerception: 10,
      strength: 10,
      dexterity: 10,
      constitution: 10,
      intelligence: 10,
      wisdom: 10,
      charisma: 10,
      inventoryNotes: '',
      attackNotes: '',
      featureNotes: '',
      skillNotes: '',
      savingThrowNotes: '',
      personalityNotes: '',
      toolAndLanguageNotes: '',
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
  }
}

List<CharacterNote> _upsertCharacter(
  List<CharacterNote> items,
  CharacterNote character, {
  String? campaignId,
}) {
  final include =
      campaignId == null || character.campaignIds.contains(campaignId);
  final updated = <CharacterNote>[];
  var replaced = false;
  for (final item in items) {
    if (item.id == character.id) {
      replaced = true;
      if (include) {
        updated.add(character);
      }
    } else {
      updated.add(item);
    }
  }
  if (!replaced && include) {
    updated.add(character);
  }
  updated.sort((a, b) => a.name.compareTo(b.name));
  return updated;
}
