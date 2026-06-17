import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';

final campaignsControllerProvider =
    StateNotifierProvider<CampaignsController, AsyncValue<List<Campaign>>>(
  (ref) => CampaignsController(ref.read(campaignRepositoryProvider))..load(),
);

final campaignSummaryProvider =
    FutureProvider.family<CampaignSummary, String>((ref, campaignId) async {
  final sessions = await ref.read(sessionRepositoryProvider).getByCampaign(
        campaignId,
      );
  final lastSession = sessions.isEmpty ? null : sessions.first;
  final lastLocation = lastSession?.locationsVisited.isEmpty ?? true
      ? ''
      : lastSession!.locationsVisited.last;
  return CampaignSummary(
    totalSessions: sessions.length,
    lastSession: lastSession,
    lastLocation: lastLocation,
  );
});

class CampaignSummary {
  const CampaignSummary({
    required this.totalSessions,
    required this.lastSession,
    required this.lastLocation,
  });

  final int totalSessions;
  final SessionNote? lastSession;
  final String lastLocation;
}

class CampaignsController extends StateNotifier<AsyncValue<List<Campaign>>> {
  CampaignsController(this._repository) : super(const AsyncValue.loading());

  final CampaignRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getAll);
  }

  Future<void> save({
    Campaign? existing,
    required String title,
    required String partyName,
    required String imagePath,
  }) async {
    final now = DateTime.now();
    final campaign = existing == null
        ? Campaign(
            id: IdGenerator.create(),
            title: title.trim(),
            systemName: AppConstants.defaultSystemName,
            description: '',
            partyName: partyName.trim(),
            createdAt: now,
            updatedAt: now,
            imagePath: imagePath.trim(),
          )
        : existing.copyWith(
            title: title.trim(),
            systemName: AppConstants.defaultSystemName,
            description: existing.description,
            partyName: partyName.trim(),
            updatedAt: now,
            imagePath: imagePath.trim(),
          );
    await _repository.save(campaign);
    await load();
  }

  Future<void> saveOverview({
    required Campaign campaign,
    required String currentLocation,
    required String worldDay,
    required String worldDate,
    required String worldTime,
    required List<CharacterListEntry> sharedLoot,
    required List<CampaignPlayer> players,
    required String description,
  }) async {
    await _repository.save(
      campaign.copyWith(
        description: description.trim(),
        currentLocation: currentLocation.trim(),
        worldDay: worldDay.trim(),
        worldDate: worldDate.trim(),
        worldTime: worldTime.trim(),
        sharedLoot: sharedLoot,
        players: players,
        updatedAt: DateTime.now(),
      ),
    );
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }
}
