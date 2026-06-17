import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_generator.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';

final questsControllerProvider =
    StateNotifierProvider.family<QuestsController, AsyncValue<List<Quest>>, String>(
  (ref, campaignId) {
    return QuestsController(ref.read(questRepositoryProvider), campaignId)
      ..load();
  },
);

class QuestsController extends StateNotifier<AsyncValue<List<Quest>>> {
  QuestsController(this._repository, this._campaignId)
      : super(const AsyncValue.loading());

  final QuestRepository _repository;
  final String _campaignId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getByCampaign(_campaignId));
  }

  Future<void> save({
    Quest? existing,
    required String title,
    required String description,
    required String relatedNpc,
    required String relatedLocation,
    required String rewardNote,
    required QuestStatus status,
    required List<CharacterListEntry> objectives,
    required String deadline,
  }) async {
    final now = DateTime.now();
    final quest = existing == null
        ? Quest(
            id: IdGenerator.create(),
            campaignId: _campaignId,
            title: title.trim(),
            description: description.trim(),
            relatedNpc: relatedNpc.trim(),
            relatedLocation: relatedLocation.trim(),
            rewardNote: rewardNote.trim(),
            status: status,
            objectives: objectives,
            deadline: deadline.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            title: title.trim(),
            description: description.trim(),
            relatedNpc: relatedNpc.trim(),
            relatedLocation: relatedLocation.trim(),
            rewardNote: rewardNote.trim(),
            status: status,
            objectives: objectives,
            deadline: deadline.trim(),
            updatedAt: now,
          );
    await _repository.save(quest);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<void> saveQuest(Quest quest) async {
    await _repository.save(quest.copyWith(updatedAt: DateTime.now()));
    await load();
  }
}
