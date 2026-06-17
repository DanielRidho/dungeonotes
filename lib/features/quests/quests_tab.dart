import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/snackbars.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/entry_list_editor.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';
import '../dice_roller/dice_launcher.dart';
import 'quest_detail_screen.dart';
import 'quest_detail_sections.dart';
import 'quests_controller.dart';

class QuestsTab extends ConsumerStatefulWidget {
  const QuestsTab({required this.campaignId, super.key});

  final String campaignId;

  @override
  ConsumerState<QuestsTab> createState() => _QuestsTabState();
}

class _QuestsTabState extends ConsumerState<QuestsTab> {
  final _search = TextEditingController();
  QuestStatus? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quests = ref.watch(questsControllerProvider(widget.campaignId));

    return Scaffold(
      floatingActionButton: DicePageActionGroup(
        primaryAction: FloatingActionButton(
          heroTag: 'add-quest',
          tooltip: 'Add quest',
          onPressed: () => _showForm(context),
          child: const Icon(Icons.add),
        ),
      ),
      body: quests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          title: 'Could not load quests',
          message: error.toString(),
          onRetry: () => ref
              .read(questsControllerProvider(widget.campaignId).notifier)
              .load(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.flag_outlined,
              title: 'No quests tracked',
              message: 'Add active leads, completed jobs, or loose ends.',
            );
          }
          final query = _search.text.trim().toLowerCase();
          final filtered = items.where((quest) {
            final matchesStatus = _filter == null || quest.status == _filter;
            final matchesSearch = query.isEmpty ||
                quest.title.toLowerCase().contains(query) ||
                quest.deadline.toLowerCase().contains(query) ||
                quest.description.toLowerCase().contains(query);
            return matchesStatus && matchesSearch;
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _search,
                            label: 'Search quests',
                            prefixIcon: Icons.search,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Filter quests',
                          onPressed: _showFilterSheet,
                          icon: Icon(
                            _filter == null
                                ? Icons.filter_list
                                : Icons.filter_alt,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const SizedBox(
                        height: 320,
                        child: EmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'No quests here',
                          message: 'Try a different status filter.',
                        ),
                      ),
                  ],
                );
              }

              final quest = filtered[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuestCard(
                  quest: quest,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuestDetailScreen(
                        campaignId: widget.campaignId,
                        questId: quest.id,
                      ),
                    ),
                  ),
                  onDelete: () => _delete(context, quest),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    var next = _filter;
    final result = await showModalBottomSheet<QuestStatus?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter quests', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: next == null,
                      onSelected: (_) => setSheetState(() => next = null),
                    ),
                    for (final status in QuestStatus.values)
                      ChoiceChip(
                        label: Text(status.label),
                        selected: next == status,
                        onSelected: (_) => setSheetState(() => next = status),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(next),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) {
      setState(() => _filter = result);
    }
  }

  Future<void> _showForm(BuildContext context, {Quest? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => QuestFormSheet(
        campaignId: widget.campaignId,
        existing: existing,
      ),
    );
    if (context.mounted && saved == true) {
      showAppSnack(context, existing == null ? 'Quest added' : 'Quest saved');
    }
  }

  Future<void> _delete(BuildContext context, Quest quest) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete quest?',
      message: 'This quest note will be removed.',
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref
          .read(questsControllerProvider(widget.campaignId).notifier)
          .delete(quest.id);
      if (context.mounted) {
        showAppSnack(context, 'Quest deleted');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.onTap,
    required this.onDelete,
  });

  final Quest quest;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.68)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quest.deadline.isEmpty
                        ? 'No deadline'
                        : 'Deadline: ${quest.deadline}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Center(child: QuestStatusChip(status: quest.status)),
            PopupMenuButton<String>(
              iconColor: colors.primary,
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: colors.primary),
                      const SizedBox(width: 10),
                      const Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class QuestFormSheet extends ConsumerStatefulWidget {
  const QuestFormSheet({
    required this.campaignId,
    super.key,
    this.existing,
  });

  final String campaignId;
  final Quest? existing;

  @override
  ConsumerState<QuestFormSheet> createState() => _QuestFormSheetState();
}

class _QuestFormSheetState extends ConsumerState<QuestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _npc;
  late final TextEditingController _location;
  late final TextEditingController _reward;
  late final TextEditingController _deadline;
  late QuestStatus _status;
  List<CharacterListEntry> _objectives = const [];
  List<WorldNote> _worldNotes = const [];

  @override
  void initState() {
    super.initState();
    final quest = widget.existing;
    _title = TextEditingController(text: quest?.title ?? '');
    _description = TextEditingController(text: quest?.description ?? '');
    _npc = TextEditingController(text: quest?.relatedNpc ?? '');
    _location = TextEditingController(text: quest?.relatedLocation ?? '');
    _reward = TextEditingController(text: quest?.rewardNote ?? '');
    _deadline = TextEditingController(text: quest?.deadline ?? '');
    _status = quest?.status ?? QuestStatus.active;
    _objectives = List.of(quest?.objectives ?? const []);
    _loadWorldNotes();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _npc.dispose();
    _location.dispose();
    _reward.dispose();
    _deadline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existing == null ? 'Add Quest' : 'Edit Quest',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _title,
                  label: 'Title',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                AppDropdown<QuestStatus>(
                  label: 'Status',
                  value: _status,
                  items: QuestStatus.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _description,
                  label: 'Description',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                EntryListEditor(
                  title: 'Objectives',
                  entries: _objectives,
                  addLabel: 'Add objective',
                  emptyText: 'No objectives yet.',
                  onChanged: (value) => setState(() => _objectives = value),
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _npc, label: 'Related NPC'),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _pickWorldNote(WorldNoteType.npc, _npc),
                    icon: const Icon(Icons.person_search_outlined),
                    label: const Text('Pick NPC'),
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _location, label: 'Related location'),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        _pickWorldNote(WorldNoteType.location, _location),
                    icon: const Icon(Icons.travel_explore_outlined),
                    label: const Text('Pick Location'),
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _reward, label: 'Reward note'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _deadline,
                  label: 'Deadline',
                  hint: 'Day 12, after the festival, before dawn...',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
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

  Future<void> _pickWorldNote(
    WorldNoteType type,
    TextEditingController target,
  ) async {
    final options = _worldNotes.where((note) => note.type == type).toList();
    if (options.isEmpty) {
      showAppSnack(
        context,
        'No ${type.label.toLowerCase()} notes available yet',
      );
      return;
    }

    final picked = await showDialog<WorldNote>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick ${type.label}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final note = options[index];
              return ListTile(
                leading: Icon(
                  type == WorldNoteType.npc
                      ? Icons.person_outline
                      : Icons.place_outlined,
                ),
                title: Text(note.name),
                subtitle: note.description.isEmpty
                    ? null
                    : Text(
                        note.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: () => Navigator.of(context).pop(note),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (picked != null) {
      target.text = picked.name;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      await ref.read(questsControllerProvider(widget.campaignId).notifier).save(
            existing: widget.existing,
            title: _title.text,
            description: _description.text,
            relatedNpc: _npc.text,
            relatedLocation: _location.text,
            rewardNote: _reward.text,
            status: _status,
            objectives: _objectives,
            deadline: _deadline.text,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}
