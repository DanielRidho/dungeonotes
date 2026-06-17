import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';

final diceControllerProvider =
    StateNotifierProvider<DiceController, AsyncValue<List<DiceRoll>>>((ref) {
  return DiceController(ref.read(diceRepositoryProvider))..load();
});

class DiceController extends StateNotifier<AsyncValue<List<DiceRoll>>> {
  DiceController(this._repository) : super(const AsyncValue.loading());

  final DiceRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getHistory);
  }

  Future<DiceRoll> recordRoll({
    required List<int> sides,
    required List<int> rolls,
    required int modifier,
    required int total,
    String rollType = 'Dice',
    String label = '',
  }) async {
    final result = await _repository.recordRoll(
      sides: sides,
      rolls: rolls,
      modifier: modifier,
      total: total,
      rollType: rollType,
      label: label,
    );
    await load();
    return result;
  }

  Future<void> clear() async {
    await _repository.clearHistory();
    await load();
  }
}
