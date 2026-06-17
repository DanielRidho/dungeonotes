import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/snackbars.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/app_models.dart';
import '../dice_roller/dice_launcher.dart';
import 'world_note_avatar.dart';
import 'world_note_detail_screen.dart';
import 'world_notes_controller.dart';

enum _WorldSort { newest, oldest, az, za }

class WorldNotesTab extends ConsumerStatefulWidget {
  const WorldNotesTab({
    required this.campaignId,
    required this.type,
    super.key,
  });

  final String campaignId;
  final WorldNoteType type;

  @override
  ConsumerState<WorldNotesTab> createState() => _WorldNotesTabState();
}

class _WorldNotesTabState extends ConsumerState<WorldNotesTab> {
  final _search = TextEditingController();
  final Set<String> _locationFilters = {};
  final Set<NpcRelationship> _relationshipFilters = {};
  final Set<NpcStatus> _statusFilters = {};
  var _sort = _WorldSort.az;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(worldNotesControllerProvider(widget.campaignId));
    final typeLabel = widget.type.label;

    return Scaffold(
      floatingActionButton: DicePageActionGroup(
        primaryAction: FloatingActionButton(
          heroTag: 'add-${widget.type.name}',
          tooltip: 'Add $typeLabel',
          onPressed: _openCreatePage,
          child: const Icon(Icons.add),
        ),
      ),
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          title: 'Could not load $typeLabel notes',
          message: error.toString(),
          onRetry: () => ref
              .read(worldNotesControllerProvider(widget.campaignId).notifier)
              .load(),
        ),
        data: (items) {
          final typed = items.where((note) => note.type == widget.type).toList();
          final query = _search.text.trim().toLowerCase();
          final filtered = typed.where((note) {
            final matchesSearch = note.name.toLowerCase().contains(query) ||
                note.description.toLowerCase().contains(query) ||
                note.locationName.toLowerCase().contains(query) ||
                note.role.toLowerCase().contains(query);
            if (!matchesSearch) {
              return false;
            }
            if (widget.type == WorldNoteType.npc) {
              if (_locationFilters.isNotEmpty &&
                  !_locationFilters.contains(note.locationName)) {
                return false;
              }
              if (_relationshipFilters.isNotEmpty &&
                  !_relationshipFilters.contains(note.relationship)) {
                return false;
              }
              if (_statusFilters.isNotEmpty &&
                  !_statusFilters.contains(note.status)) {
                return false;
              }
            }
            return true;
          }).toList()
            ..sort(_sortNotes);

          if (typed.isEmpty) {
            return EmptyState(
              icon: widget.type == WorldNoteType.npc
                  ? Icons.person_outline
                  : Icons.place_outlined,
              title: 'No ${typeLabel.toLowerCase()} notes',
              message: widget.type == WorldNoteType.npc
                  ? 'Track allies, enemies, contacts, and rumors.'
                  : 'Track kingdoms, towns, taverns, ruins, and routes.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _search,
                            label: 'Search $typeLabel',
                            prefixIcon: Icons.search,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: _hasFilters ? 'Filters on' : 'Filter',
                          onPressed: () => _showFilters(items),
                          icon: Icon(
                            _hasFilters ? Icons.filter_alt : Icons.filter_list,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const SizedBox(
                        height: 320,
                        child: EmptyState(
                          icon: Icons.search_off,
                          title: 'No matching notes',
                          message: 'Try another search term.',
                        ),
                      ),
                  ],
                );
              }

              final note = filtered[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorldNoteCard(
                  note: note,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WorldNoteDetailScreen(
                        campaignId: widget.campaignId,
                        noteId: note.id,
                      ),
                    ),
                  ),
                  onDelete: () => _delete(context, note),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool get _hasFilters =>
      _locationFilters.isNotEmpty ||
      _relationshipFilters.isNotEmpty ||
      _statusFilters.isNotEmpty ||
      _sort != _WorldSort.az;

  int _sortNotes(WorldNote a, WorldNote b) {
    return switch (_sort) {
      _WorldSort.newest => b.updatedAt.compareTo(a.updatedAt),
      _WorldSort.oldest => a.updatedAt.compareTo(b.updatedAt),
      _WorldSort.az => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      _WorldSort.za => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
    };
  }

  Future<void> _showFilters(List<WorldNote> allNotes) async {
    final locations = allNotes
        .where((note) => note.type == WorldNoteType.location)
        .map((note) => note.name)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    var nextLocations = Set<String>.of(_locationFilters);
    var nextRelationships = Set<NpcRelationship>.of(_relationshipFilters);
    var nextStatuses = Set<NpcStatus>.of(_statusFilters);
    var nextSort = _sort;
    final colors = Theme.of(context).colorScheme;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_WorldSort>(
                    value: nextSort,
                    decoration: const InputDecoration(labelText: 'Sort by'),
                    items: const [
                      DropdownMenuItem(
                        value: _WorldSort.newest,
                        child: Text('Newest'),
                      ),
                      DropdownMenuItem(
                        value: _WorldSort.oldest,
                        child: Text('Oldest'),
                      ),
                      DropdownMenuItem(
                        value: _WorldSort.az,
                        child: Text('A to Z'),
                      ),
                      DropdownMenuItem(
                        value: _WorldSort.za,
                        child: Text('Z to A'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => nextSort = value);
                      }
                    },
                  ),
                  if (widget.type == WorldNoteType.npc) ...[
                    const SizedBox(height: 12),
                    _FilterChips<String>(
                      title: 'Location',
                      values: locations,
                      selected: nextLocations,
                      label: (value) => value,
                      onChanged: (value) =>
                          setSheetState(() => nextLocations = value),
                    ),
                    const SizedBox(height: 12),
                    _FilterChips<NpcRelationship>(
                      title: 'Relationship',
                      values: NpcRelationship.values,
                      selected: nextRelationships,
                      label: (value) => value.label,
                      onChanged: (value) =>
                          setSheetState(() => nextRelationships = value),
                    ),
                    const SizedBox(height: 12),
                    _FilterChips<NpcStatus>(
                      title: 'Status',
                      values: NpcStatus.values,
                      selected: nextStatuses,
                      label: (value) => value.label,
                      onChanged: (value) =>
                          setSheetState(() => nextStatuses = value),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          nextLocations = {};
                          nextRelationships = {};
                          nextStatuses = {};
                          nextSort = _WorldSort.az;
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Clear all'),
                      ),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _locationFilters
          ..clear()
          ..addAll(nextLocations);
        _relationshipFilters
          ..clear()
          ..addAll(nextRelationships);
        _statusFilters
          ..clear()
          ..addAll(nextStatuses);
        _sort = nextSort;
      });
    }
  }

  Future<void> _openCreatePage() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorldNoteDetailScreen.create(
          campaignId: widget.campaignId,
          type: widget.type,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WorldNote note) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete ${note.type.label.toLowerCase()}?',
      message: 'This note will be removed from local storage.',
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref
          .read(worldNotesControllerProvider(widget.campaignId).notifier)
          .delete(note.id);
      if (context.mounted) {
        showAppSnack(context, 'Note deleted');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}

class _WorldNoteCard extends StatelessWidget {
  const _WorldNoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final WorldNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isNpc = note.type == WorldNoteType.npc;
    final colors = Theme.of(context).colorScheme;
    final subtitle = isNpc
        ? [
            if (note.role.isNotEmpty) note.role,
            if (note.locationName.isNotEmpty) 'in ${note.locationName}',
            note.relationship.label,
          ].join(' - ')
        : note.locationType;
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
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              WorldNoteAvatar(
                name: note.name,
                imagePath: note.imagePath,
                icon: isNpc ? Icons.person_outline : Icons.place_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      note.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              if (isNpc) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    note.status.label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
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

class _FilterChips<T> extends StatelessWidget {
  const _FilterChips({
    required this.title,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final List<T> values;
  final Set<T> selected;
  final String Function(T value) label;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        if (values.isEmpty)
          Text(
            'No options yet',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                FilterChip(
                  label: Text(label(value)),
                  selected: selected.contains(value),
                  onSelected: (checked) {
                    final next = Set<T>.of(selected);
                    if (checked) {
                      next.add(value);
                    } else {
                      next.remove(value);
                    }
                    onChanged(next);
                  },
                ),
              ],
            ),
      ],
    );
  }
}
