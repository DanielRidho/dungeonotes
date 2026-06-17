import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/snackbars.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';
import '../sessions/session_detail_sections.dart';
import 'quest_detail_dialogs.dart';
import 'quest_detail_sections.dart';
import 'quests_controller.dart';

class QuestDetailScreen extends ConsumerStatefulWidget {
  const QuestDetailScreen({
    required this.campaignId,
    required this.questId,
    super.key,
  });

  final String campaignId;
  final String questId;

  @override
  ConsumerState<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends ConsumerState<QuestDetailScreen> {
  List<WorldNote> _worldNotes = const [];

  @override
  void initState() {
    super.initState();
    _loadWorldNotes();
  }

  @override
  Widget build(BuildContext context) {
    final quests = ref.watch(questsControllerProvider(widget.campaignId));
    return quests.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          title: 'Could not load quest',
          message: error.toString(),
          onRetry: () => ref
              .read(questsControllerProvider(widget.campaignId).notifier)
              .load(),
        ),
      ),
      data: (items) {
        final matches = items.where((item) => item.id == widget.questId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorView(
              title: 'Quest not found',
              message: 'It may have been deleted.',
            ),
          );
        }
        final quest = matches.first;
        final npcs = _worldNotes
            .where((note) => note.type == WorldNoteType.npc)
            .map((note) => note.name)
            .toList();
        final locations = _worldNotes
            .where((note) => note.type == WorldNoteType.location)
            .map((note) => note.name)
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Quest')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              QuestHeaderSection(
                quest: quest,
                onEdit: () => _editHeader(quest),
              ),
              const SizedBox(height: 20),
              QuestObjectivesSection(
                objectives: quest.objectives,
                onAdd: () => _editObjective(quest),
                onEdit: (entry) => _editObjective(quest, existing: entry),
                onDelete: (entry) => _deleteObjective(quest, entry),
              ),
              const SizedBox(height: 12),
              QuestLinkedNameSection(
                title: 'Related NPC',
                name: quest.relatedNpc,
                icon: Icons.person_outline,
                options: npcs,
                notesByName: _worldNotesByName,
                onChanged: (name) => _save(quest.copyWith(relatedNpc: name)),
              ),
              const SizedBox(height: 12),
              QuestLinkedNameSection(
                title: 'Related Location',
                name: quest.relatedLocation,
                icon: Icons.place_outlined,
                options: locations,
                notesByName: _worldNotesByName,
                onChanged: (name) =>
                    _save(quest.copyWith(relatedLocation: name)),
              ),
              const SizedBox(height: 12),
              SessionTextSection(
                title: 'Reward',
                icon: Icons.toll_outlined,
                text: quest.rewardNote,
                emptyMessage: 'Add promised rewards or loose payment notes.',
                onEdit: () => _editText(
                  quest,
                  title: 'Reward',
                  value: quest.rewardNote,
                  apply: (value) => quest.copyWith(rewardNote: value),
                ),
                onClear: quest.rewardNote.isEmpty
                    ? null
                    : () => _confirmAndSave(
                          title: 'Clear reward?',
                          message: 'This clears the reward note.',
                          quest: quest.copyWith(rewardNote: ''),
                        ),
              ),
              const SizedBox(height: 12),
              SessionTextSection(
                title: 'Description',
                icon: Icons.notes_outlined,
                text: quest.description,
                emptyMessage: 'Add the quest premise, stakes, and clues.',
                onEdit: () => _editText(
                  quest,
                  title: 'Description',
                  value: quest.description,
                  apply: (value) => quest.copyWith(description: value),
                ),
                onClear: quest.description.isEmpty
                    ? null
                    : () => _confirmAndSave(
                          title: 'Clear description?',
                          message: 'This clears the quest description.',
                          quest: quest.copyWith(description: ''),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadWorldNotes() async {
    try {
      final notes = await ref
          .read(worldNoteRepositoryProvider)
          .getByCampaign(widget.campaignId);
      if (mounted) {
        setState(() => _worldNotes = notes);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _worldNotes = const []);
      }
    }
  }

  Map<String, WorldNote> get _worldNotesByName => {
        for (final note in _worldNotes) note.name: note,
      };

  Future<void> _editHeader(Quest quest) async {
    final updated = await showQuestHeaderDialog(context, quest);
    if (updated != null) {
      await _save(updated);
    }
  }

  Future<void> _editObjective(
    Quest quest, {
    CharacterListEntry? existing,
  }) async {
    final entry = await showQuestObjectiveDialog(context, existing: existing);
    if (entry == null) {
      return;
    }
    final next = [...quest.objectives];
    final index = next.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      next.add(entry);
    } else {
      next[index] = entry;
    }
    await _save(quest.copyWith(objectives: next));
  }

  Future<void> _deleteObjective(Quest quest, CharacterListEntry entry) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete objective?',
      message: 'This removes the objective from this quest.',
    );
    if (!confirmed) {
      return;
    }
    await _save(
      quest.copyWith(
        objectives:
            quest.objectives.where((item) => item.id != entry.id).toList(),
      ),
    );
  }

  Future<void> _confirmAndSave({
    required String title,
    required String message,
    required Quest quest,
  }) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: title,
      message: message,
    );
    if (confirmed) {
      await _save(quest);
    }
  }

  Future<void> _editText(
    Quest quest, {
    required String title,
    required String value,
    required Quest Function(String value) apply,
  }) async {
    final updated = await showQuestTextDialog(
      context,
      title: title,
      initialValue: value,
    );
    if (updated != null) {
      await _save(apply(updated));
    }
  }

  Future<void> _save(Quest quest) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) {
        return;
      }
      await ref
          .read(questsControllerProvider(widget.campaignId).notifier)
          .saveQuest(quest);
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}
