import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_generator.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';

final sessionsControllerProvider = StateNotifierProvider.family<
    SessionsController,
    AsyncValue<List<SessionNote>>,
    String>((ref, campaignId) {
  return SessionsController(ref.read(sessionRepositoryProvider), campaignId)
    ..load();
});

class SessionsController extends StateNotifier<AsyncValue<List<SessionNote>>> {
  SessionsController(this._repository, this._campaignId)
      : super(const AsyncValue.loading());

  final SessionRepository _repository;
  final String _campaignId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getByCampaign(_campaignId));
  }

  Future<void> save({
    SessionNote? existing,
    required String title,
    required DateTime date,
    required String summary,
    required String importantEvents,
    required String loot,
    required String nextSessionReminderNote,
    required List<String> npcsMet,
    required List<String> locationsVisited,
    List<SessionEventEntry>? eventEntries,
    List<SessionLootEntry>? lootEntries,
  }) async {
    final now = DateTime.now();
    final session = existing == null
        ? SessionNote(
            id: IdGenerator.create(),
            campaignId: _campaignId,
            title: title.trim(),
            date: date,
            summary: summary.trim(),
            importantEvents: importantEvents.trim(),
            loot: loot.trim(),
            nextSessionReminderNote: nextSessionReminderNote.trim(),
            npcsMet: npcsMet,
            locationsVisited: locationsVisited,
            eventEntries: eventEntries ?? const [],
            lootEntries: lootEntries ?? const [],
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            title: title.trim(),
            date: date,
            summary: summary.trim(),
            importantEvents: importantEvents.trim(),
            loot: loot.trim(),
            nextSessionReminderNote: nextSessionReminderNote.trim(),
            npcsMet: npcsMet,
            locationsVisited: locationsVisited,
            eventEntries: eventEntries ?? existing.eventEntries,
            lootEntries: lootEntries ?? existing.lootEntries,
            updatedAt: now,
          );
    await _repository.save(session);
    await load();
  }

  Future<void> saveSession(SessionNote session) async {
    await _repository.save(session.copyWith(updatedAt: DateTime.now()));
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }
}
