import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_generator.dart';
import '../../core/utils/snackbars.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';
import '../campaigns/campaign_overview_header.dart';
import '../sessions/session_detail_sections.dart';
import 'world_note_avatar.dart';
import 'world_note_detail_dialogs.dart';
import 'world_note_photo_storage.dart';
import 'world_notes_controller.dart';

class WorldNoteDetailScreen extends ConsumerStatefulWidget {
  const WorldNoteDetailScreen({
    required this.campaignId,
    required this.noteId,
    super.key,
  }) : createType = null;

  const WorldNoteDetailScreen.create({
    required this.campaignId,
    required WorldNoteType type,
    super.key,
  })  : noteId = null,
        createType = type;

  final String campaignId;
  final String? noteId;
  final WorldNoteType? createType;

  @override
  ConsumerState<WorldNoteDetailScreen> createState() =>
      _WorldNoteDetailScreenState();
}

class _WorldNoteDetailScreenState extends ConsumerState<WorldNoteDetailScreen> {
  List<WorldNote> _worldNotes = const [];
  List<Quest> _quests = const [];
  List<SessionNote> _sessions = const [];
  WorldNote? _draft;
  String? _activeNoteId;
  bool _openedInitialEditor = false;

  @override
  void initState() {
    super.initState();
    _activeNoteId = widget.noteId;
    final createType = widget.createType;
    if (createType != null) {
      final now = DateTime.now();
      _draft = WorldNote(
        id: IdGenerator.create(),
        campaignId: widget.campaignId,
        name: '',
        type: createType,
        description: '',
        relationshipStatus: NpcRelationship.unknown.label,
        tags: const [],
        lastSeenSession: '',
        createdAt: now,
        updatedAt: now,
      );
    }
    _loadReferences();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(worldNotesControllerProvider(widget.campaignId));
    return notes.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          title: 'Could not load world note',
          message: error.toString(),
          onRetry: () => ref
              .read(worldNotesControllerProvider(widget.campaignId).notifier)
              .load(),
        ),
      ),
      data: (items) {
        final noteId = _activeNoteId;
        final matches = noteId == null
            ? const <WorldNote>[]
            : items.where((item) => item.id == noteId);
        final note = matches.isNotEmpty ? matches.first : _draft;
        if (note == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorView(
              title: 'World note not found',
              message: 'It may have been deleted.',
            ),
          );
        }
        if (_activeNoteId == null && !_openedInitialEditor) {
          _openedInitialEditor = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _editHero(note, closeIfCancelled: true);
            }
          });
        }
        final isNpc = note.type == WorldNoteType.npc;
        final locations = _worldNotes
            .where((item) => item.type == WorldNoteType.location)
            .map((item) => item.name)
            .toList();
        final npcs = _worldNotes
            .where((item) =>
                item.type == WorldNoteType.npc && item.name != note.name)
            .map((item) => item.name)
            .toList();
        final questTitles = _quests.map((quest) => quest.title).toList();
        final sessionTitles = _sessions.map((session) => session.title).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _activeNoteId == null
                  ? 'New ${note.type.label}'
                  : isNpc
                      ? 'NPC'
                      : 'Location',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _WorldHeroCard(
                note: note,
                onEdit: () => _editHero(note),
              ),
              const SizedBox(height: 16),
              if (isNpc) ...[
                _NpcMetaSection(
                  note: note,
                  locations: locations,
                  onSave: _save,
                ),
                const SizedBox(height: 16),
                _SingleInfoSection(
                  title: 'Last Seen Session',
                  value: note.lastSeenSession,
                  empty: 'No session selected.',
                  onEdit: () => _editLastSeen(note, sessionTitles),
                ),
              ] else ...[
                SessionLinkedWorldSection(
                  title: 'Related NPCs',
                  emptyTitle: 'No related NPCs',
                  emptyMessage: 'Link NPCs connected to this location.',
                  icon: Icons.person_outline,
                  names: note.relatedNpcs,
                  options: npcs,
                  notesByName: _worldNotesByName,
                  onAdd: () => _pickMultiple(
                    note,
                    title: 'Related NPCs',
                    options: npcs,
                    selected: note.relatedNpcs,
                    apply: (value) => note.copyWith(relatedNpcs: value),
                  ),
                  onRemove: (name) => _removeRelatedNpc(note, name),
                ),
                const SizedBox(height: 16),
                SessionLinkedWorldSection(
                  title: 'Related Quests',
                  emptyTitle: 'No related quests',
                  emptyMessage: 'Link quests connected to this place.',
                  icon: Icons.flag_outlined,
                  names: note.relatedQuests,
                  options: questTitles,
                  onAdd: () => _pickMultiple(
                    note,
                    title: 'Related Quests',
                    options: questTitles,
                    selected: note.relatedQuests,
                    apply: (value) => note.copyWith(relatedQuests: value),
                  ),
                  onRemove: (name) => _removeRelatedQuest(note, name),
                ),
              ],
              const SizedBox(height: 16),
              SessionTextSection(
                title: 'Description',
                icon: Icons.notes_outlined,
                text: note.description,
                emptyMessage: 'Add useful details, rumors, and reminders.',
                onEdit: () => _editText(
                  note,
                  title: 'Description',
                  value: note.description,
                  apply: (value) => note.copyWith(description: value),
                  maxLines: 5,
                ),
                onClear: note.description.isEmpty
                    ? null
                    : () => _confirmAndSave(
                          title: 'Clear description?',
                          message: 'This clears the description.',
                          note: note.copyWith(description: ''),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadReferences() async {
    try {
      final results = await Future.wait([
        ref.read(worldNoteRepositoryProvider).getByCampaign(widget.campaignId),
        ref.read(questRepositoryProvider).getByCampaign(widget.campaignId),
        ref.read(sessionRepositoryProvider).getByCampaign(widget.campaignId),
      ]);
      if (!mounted) return;
      setState(() {
        _worldNotes = results[0] as List<WorldNote>;
        _quests = results[1] as List<Quest>;
        _sessions = results[2] as List<SessionNote>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _worldNotes = const [];
        _quests = const [];
        _sessions = const [];
      });
    }
  }

  Map<String, WorldNote> get _worldNotesByName => {
        for (final note in _worldNotes) note.name: note,
      };

  Future<void> _editText(
    WorldNote note, {
    required String title,
    required String value,
    required WorldNote Function(String value) apply,
    int maxLines = 1,
  }) async {
    final updated = await showWorldTextDialog(
      context,
      title: title,
      initialValue: value,
      maxLines: maxLines,
    );
    if (updated != null && (maxLines > 1 || updated.isNotEmpty)) {
      await _save(apply(updated));
    }
  }

  Future<void> _editHero(
    WorldNote note, {
    bool closeIfCancelled = false,
  }) async {
    final updated = await showDialog<WorldNote>(
      context: context,
      builder: (_) => _WorldHeroEditDialog(note: note),
    );
    if (updated == null) {
      if (closeIfCancelled && mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    await _save(updated, showMessage: _activeNoteId == null);
  }

  Future<void> _editLastSeen(WorldNote note, List<String> sessions) async {
    final selected = await showSessionPickerDialog(
      context,
      current: note.lastSeenSession,
      sessions: sessions,
    );
    if (selected != null) {
      await _save(note.copyWith(lastSeenSession: selected));
    }
  }

  Future<void> _pickMultiple(
    WorldNote note, {
    required String title,
    required List<String> options,
    required List<String> selected,
    required WorldNote Function(List<String> value) apply,
  }) async {
    final updated = await showWorldMultiPickerDialog(
      context,
      title: title,
      options: options,
      selected: selected,
    );
    if (updated != null) {
      await _save(apply(updated));
    }
  }

  Future<void> _removeRelatedNpc(WorldNote note, String name) {
    return _confirmAndSave(
      title: 'Remove related NPC?',
      message: 'This unlinks the NPC from this location.',
      note: note.copyWith(
        relatedNpcs: note.relatedNpcs.where((item) => item != name).toList(),
      ),
    );
  }

  Future<void> _removeRelatedQuest(WorldNote note, String name) {
    return _confirmAndSave(
      title: 'Remove related quest?',
      message: 'This unlinks the quest from this location.',
      note: note.copyWith(
        relatedQuests:
            note.relatedQuests.where((item) => item != name).toList(),
      ),
    );
  }

  Future<void> _confirmAndSave({
    required String title,
    required String message,
    required WorldNote note,
  }) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: title,
      message: message,
    );
    if (confirmed) {
      await _save(note);
    }
  }

  Future<void> _save(WorldNote note, {bool showMessage = false}) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) {
        return;
      }
      await ref
          .read(worldNotesControllerProvider(widget.campaignId).notifier)
          .saveNote(note);
      _activeNoteId = note.id;
      _draft = note;
      await _loadReferences();
      if (mounted && showMessage) {
        showAppSnack(context, '${note.type.label} added');
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}

class _WorldHeroCard extends StatelessWidget {
  const _WorldHeroCard({
    required this.note,
    required this.onEdit,
  });

  final WorldNote note;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final subtitle =
        note.type == WorldNoteType.npc ? note.role : note.locationType;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Edit',
                color: colors.primary,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  WorldNoteAvatar(
                    name: note.name,
                    imagePath: note.imagePath,
                    icon: note.type == WorldNoteType.npc
                        ? Icons.person_outline
                        : Icons.place_outlined,
                    size: 132,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    note.name.isEmpty ? 'New ${note.type.label}' : note.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.isEmpty
                        ? 'No ${note.type.label.toLowerCase()} role'
                        : subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldHeroEditDialog extends StatefulWidget {
  const _WorldHeroEditDialog({required this.note});

  final WorldNote note;

  @override
  State<_WorldHeroEditDialog> createState() => _WorldHeroEditDialogState();
}

class _WorldHeroEditDialogState extends State<_WorldHeroEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _subtitle;
  late String _imagePath;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.note.name);
    _subtitle = TextEditingController(
      text: widget.note.type == WorldNoteType.npc
          ? widget.note.role
          : widget.note.locationType,
    );
    _imagePath = widget.note.imagePath;
  }

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNpc = widget.note.type == WorldNoteType.npc;
    return KeyboardSafeAlertDialog(
      title: Text('Edit ${widget.note.type.label}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
      children: [
        Center(
          child: WorldNoteAvatar(
            name: _name.text,
            imagePath: _imagePath,
            icon: isNpc ? Icons.person_outline : Icons.place_outlined,
            size: 112,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.tonal(
              onPressed: _pickPhoto,
              child: Text(_imagePath.isEmpty ? 'Add photo' : 'Change photo'),
            ),
            if (_imagePath.isNotEmpty)
              OutlinedButton(
                onPressed: () => setState(() => _imagePath = ''),
                child: const Text('Delete photo'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(controller: _name, label: 'Name'),
        const SizedBox(height: 12),
        AppTextField(
          controller: _subtitle,
          label: isNpc ? 'Role' : 'Location type',
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    final path = await WorldNotePhotoStorage.pickCropAndSave(
      context,
      widget.note.id,
    );
    if (path != null && mounted) {
      setState(() => _imagePath = path);
    }
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      return;
    }
    final isNpc = widget.note.type == WorldNoteType.npc;
    Navigator.of(context).pop(
      widget.note.copyWith(
        name: _name.text.trim(),
        role: isNpc ? _subtitle.text.trim() : widget.note.role,
        locationType: isNpc ? widget.note.locationType : _subtitle.text.trim(),
        imagePath: _imagePath,
      ),
    );
  }
}

class _NpcMetaSection extends StatelessWidget {
  const _NpcMetaSection({
    required this.note,
    required this.locations,
    required this.onSave,
  });

  final WorldNote note;
  final List<String> locations;
  final ValueChanged<WorldNote> onSave;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _NpcInfoRow(
              icon: Icons.favorite_border,
              label: 'Status',
              value: note.status.label,
              onEdit: () => _editStatus(context),
            ),
            _NpcInfoRow(
              icon: Icons.handshake_outlined,
              label: 'Relationship',
              value: note.relationship.label,
              onEdit: () => _editRelationship(context),
            ),
            _NpcInfoRow(
              icon: Icons.badge_outlined,
              label: 'Species',
              value: note.species.isEmpty ? '-' : note.species,
              onEdit: () => _editSpecies(context),
            ),
            _NpcInfoRow(
              icon: Icons.place_outlined,
              label: 'Location',
              value: note.locationName.isEmpty ? '-' : note.locationName,
              onEdit: () => _editLocation(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSpecies(BuildContext context) async {
    final value = await showWorldTextDialog(
      context,
      title: 'Species',
      initialValue: note.species,
    );
    if (value != null) {
      onSave(note.copyWith(species: value));
    }
  }

  Future<void> _editStatus(BuildContext context) async {
    var status = note.status;
    final updated = await showDialog<NpcStatus>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => KeyboardSafeAlertDialog(
          title: const Text('Status'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(status),
              child: const Text('Save'),
            ),
          ],
          children: [
            AppDropdown<NpcStatus>(
              label: 'Status',
              value: status,
              items: NpcStatus.values,
              labelBuilder: (value) => value.label,
              onChanged: (value) {
                if (value != null) setState(() => status = value);
              },
            ),
          ],
        ),
      ),
    );
    if (updated != null) {
      onSave(note.copyWith(status: updated));
    }
  }

  Future<void> _editRelationship(BuildContext context) async {
    var relationship = note.relationship;
    final updated = await showDialog<NpcRelationship>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => KeyboardSafeAlertDialog(
          title: const Text('Relationship'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(relationship),
              child: const Text('Save'),
            ),
          ],
          children: [
            AppDropdown<NpcRelationship>(
              label: 'Relationship',
              value: relationship,
              items: NpcRelationship.values,
              labelBuilder: (value) => value.label,
              onChanged: (value) {
                if (value != null) setState(() => relationship = value);
              },
            ),
          ],
        ),
      ),
    );
    if (updated != null) {
      onSave(
        note.copyWith(
          relationship: updated,
          relationshipStatus: updated.label,
        ),
      );
    }
  }

  Future<void> _editLocation(BuildContext context) async {
    var location = note.locationName;
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => KeyboardSafeAlertDialog(
          title: const Text('Location'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(location),
              child: const Text('Save'),
            ),
          ],
          children: [
            DropdownButtonFormField<String>(
              value: locations.contains(location) ? location : '',
              decoration: const InputDecoration(labelText: 'Location'),
              items: [
                const DropdownMenuItem(value: '', child: Text('None')),
                for (final item in locations)
                  DropdownMenuItem(value: item, child: Text(item)),
              ],
              onChanged: (value) => setState(() => location = value ?? ''),
            ),
          ],
        ),
      ),
    );
    if (updated != null) {
      onSave(note.copyWith(locationName: updated));
    }
  }
}

class _NpcInfoRow extends StatelessWidget {
  const _NpcInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Edit $label',
            color: colors.primary,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _SingleInfoSection extends StatelessWidget {
  const _SingleInfoSection({
    required this.title,
    required this.value,
    required this.empty,
    required this.onEdit,
  });

  final String title;
  final String value;
  final String empty;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignSectionHeader(
          title: title,
          action: IconButton(
            tooltip: 'Edit $title',
            color: colors.primary,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.isEmpty ? empty : value,
          style: TextStyle(
            color: value.isEmpty ? colors.onSurfaceVariant : null,
          ),
        ),
      ],
    );
  }
}
