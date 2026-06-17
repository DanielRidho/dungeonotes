import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_generator.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';

final worldNotesControllerProvider = StateNotifierProvider.family<
    WorldNotesController,
    AsyncValue<List<WorldNote>>,
    String>((ref, campaignId) {
  return WorldNotesController(
    ref.read(worldNoteRepositoryProvider),
    campaignId,
  )..load();
});

class WorldNotesController extends StateNotifier<AsyncValue<List<WorldNote>>> {
  WorldNotesController(this._repository, this._campaignId)
      : super(const AsyncValue.loading());

  final WorldNoteRepository _repository;
  final String _campaignId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getByCampaign(_campaignId));
  }

  Future<void> save({
    WorldNote? existing,
    required String name,
    required WorldNoteType type,
    required String description,
    required String relationshipStatus,
    required List<String> tags,
    required String lastSeenSession,
    required String species,
    required String role,
    required String locationName,
    required NpcRelationship relationship,
    required NpcStatus status,
    required String locationType,
    required List<String> relatedNpcs,
    required List<String> relatedQuests,
    String imagePath = '',
  }) async {
    final now = DateTime.now();
    final note = existing == null
        ? WorldNote(
            id: IdGenerator.create(),
            campaignId: _campaignId,
            name: name.trim(),
            type: type,
            description: description.trim(),
            relationshipStatus: relationshipStatus.trim(),
            tags: tags,
            lastSeenSession: lastSeenSession.trim(),
            species: species.trim(),
            role: role.trim(),
            locationName: locationName.trim(),
            relationship: relationship,
            status: status,
            locationType: locationType.trim(),
            relatedNpcs: relatedNpcs,
            relatedQuests: relatedQuests,
            imagePath: imagePath.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            name: name.trim(),
            type: type,
            description: description.trim(),
            relationshipStatus: relationshipStatus.trim(),
            tags: tags,
            lastSeenSession: lastSeenSession.trim(),
            species: species.trim(),
            role: role.trim(),
            locationName: locationName.trim(),
            relationship: relationship,
            status: status,
            locationType: locationType.trim(),
            relatedNpcs: relatedNpcs,
            relatedQuests: relatedQuests,
            imagePath: imagePath.trim(),
            updatedAt: now,
          );
    await _repository.save(note);
    await load();
  }

  Future<void> saveNote(WorldNote note) async {
    await _repository.save(note.copyWith(updatedAt: DateTime.now()));
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }
}
