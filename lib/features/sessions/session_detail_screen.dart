import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/snackbars.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';
import '../campaigns/campaigns_controller.dart';
import '../dice_roller/dice_launcher.dart';
import 'session_detail_dialogs.dart';
import 'session_detail_sections.dart';
import 'sessions_controller.dart';

class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({
    required this.campaignId,
    required this.sessionId,
    super.key,
  });

  final String campaignId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsControllerProvider(campaignId));
    return sessions.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: ErrorView(
          title: 'Could not open session',
          message: error.toString(),
          onRetry: () =>
              ref.read(sessionsControllerProvider(campaignId).notifier).load(),
        ),
      ),
      data: (items) {
        final matches = items.where((session) => session.id == sessionId);
        final session = matches.isEmpty ? null : matches.first;
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorView(
              title: 'Session not found',
              message: 'It may have been deleted.',
            ),
          );
        }
        return _SessionDetailBody(session: session, campaignId: campaignId);
      },
    );
  }
}

class _SessionDetailBody extends ConsumerStatefulWidget {
  const _SessionDetailBody({
    required this.session,
    required this.campaignId,
  });

  final SessionNote session;
  final String campaignId;

  @override
  ConsumerState<_SessionDetailBody> createState() => _SessionDetailBodyState();
}

class _SessionDetailBodyState extends ConsumerState<_SessionDetailBody> {
  List<WorldNote> _worldNotes = const [];

  SessionNote get session => widget.session;

  @override
  void initState() {
    super.initState();
    _loadWorldNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const DiceActionButton(),
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SessionHeaderSection(session: session, onEdit: _editHeader),
          const SizedBox(height: 22),
          SessionTextSection(
            title: 'Summary',
            icon: Icons.description_outlined,
            text: session.summary,
            emptyMessage: 'Add the short recap for this session.',
            onEdit: () => _editText(
              title: 'Edit Summary',
              label: 'Summary',
              value: session.summary,
              onSaved: (value) => _save(session.copyWith(summary: value)),
            ),
            onClear: session.summary.isEmpty
                ? null
                : () => _clearText(
                      title: 'Clear summary?',
                      onClear: () => _save(session.copyWith(summary: '')),
                    ),
          ),
          const SizedBox(height: 22),
          SessionEventsSection(
            events: session.eventEntries,
            onAdd: _addEvent,
            onEdit: _editEvent,
            onDelete: _deleteEvent,
          ),
          const SizedBox(height: 22),
          SessionLinkedWorldSection(
            title: 'NPCs Met',
            emptyTitle: 'No NPCs met',
            emptyMessage: 'Link NPCs from this campaign world.',
            icon: Icons.person_outline,
            names: session.npcsMet,
            options: _availableWorldNames(WorldNoteType.npc, session.npcsMet),
            notesByName: _worldNotesByName,
            onAdd: _addNpc,
            onRemove: _removeNpc,
          ),
          const SizedBox(height: 22),
          SessionLinkedWorldSection(
            title: 'Locations Visited',
            emptyTitle: 'No locations visited',
            emptyMessage: 'Link locations from this campaign world.',
            icon: Icons.place_outlined,
            names: session.locationsVisited,
            options: _availableWorldNames(
              WorldNoteType.location,
              session.locationsVisited,
            ),
            notesByName: _worldNotesByName,
            onAdd: _addLocation,
            onRemove: _removeLocation,
          ),
          const SizedBox(height: 22),
          SessionLootSection(
            loot: session.lootEntries,
            onAdd: _addLoot,
            onEdit: _editLoot,
            onDelete: _deleteLoot,
            onQuantityChanged: _changeLootQuantity,
            onClaimedChanged: _setLootClaimed,
          ),
          const SizedBox(height: 22),
          SessionTextSection(
            title: 'Next Session Reminder',
            icon: Icons.notification_add_outlined,
            text: session.nextSessionReminderNote,
            emptyMessage: 'Add the next hook, reminder, or prep note.',
            onEdit: () => _editText(
              title: 'Edit Reminder',
              label: 'Next session reminder',
              value: session.nextSessionReminderNote,
              onSaved: (value) => _save(
                session.copyWith(nextSessionReminderNote: value),
              ),
            ),
            onClear: session.nextSessionReminderNote.isEmpty
                ? null
                : () => _clearText(
                      title: 'Clear reminder?',
                      onClear: () => _save(
                        session.copyWith(nextSessionReminderNote: ''),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  List<String> _availableWorldNames(WorldNoteType type, List<String> selected) {
    return _worldNotes
        .where((note) => note.type == type)
        .map((note) => note.name)
        .where((name) => !selected.contains(name))
        .toList()
      ..sort();
  }

  Map<String, WorldNote> get _worldNotesByName => {
        for (final note in _worldNotes) note.name: note,
      };

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

  Future<void> _save(SessionNote updated, {bool showMessage = false}) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) {
        return;
      }
      await ref
          .read(sessionsControllerProvider(widget.campaignId).notifier)
          .saveSession(updated);
      ref.invalidate(campaignSummaryProvider(widget.campaignId));
      if (mounted && showMessage) {
        showAppSnack(context, 'Session saved');
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _editHeader() async {
    final draft = await showDialog<SessionHeaderDraft>(
      context: context,
      builder: (context) => SessionHeaderDialog(session: session),
    );
    if (draft != null) {
      await _save(
        session.copyWith(title: draft.title, date: draft.date),
        showMessage: true,
      );
    }
  }

  Future<void> _editText({
    required String title,
    required String label,
    required String value,
    required ValueChanged<String> onSaved,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SessionTextEditDialog(
        title: title,
        label: label,
        value: value,
      ),
    );
    if (result != null) {
      onSaved(result.trim());
    }
  }

  Future<void> _clearText({
    required String title,
    required VoidCallback onClear,
  }) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: title,
      message: 'This clears the note text.',
      confirmLabel: 'Clear',
    );
    if (confirmed) {
      onClear();
    }
  }

  Future<void> _addEvent() async {
    final event = await showDialog<SessionEventEntry>(
      context: context,
      builder: (context) => const SessionEventDialog(),
    );
    if (event != null) {
      await _save(
        session.copyWith(
          importantEvents: '',
          eventEntries: [...session.eventEntries, event],
        ),
      );
    }
  }

  Future<void> _editEvent(SessionEventEntry event) async {
    final updated = await showDialog<SessionEventEntry>(
      context: context,
      builder: (context) => SessionEventDialog(existing: event),
    );
    if (updated == null) {
      return;
    }
    await _save(
      session.copyWith(
        importantEvents: '',
        eventEntries: [
          for (final item in session.eventEntries)
            item.id == updated.id ? updated : item,
        ],
      ),
    );
  }

  Future<void> _deleteEvent(SessionEventEntry event) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete event?',
      message: 'This removes the event from this session.',
    );
    if (!confirmed) {
      return;
    }
    await _save(
      session.copyWith(
        importantEvents: '',
        eventEntries:
            session.eventEntries.where((item) => item.id != event.id).toList(),
      ),
    );
  }

  Future<void> _addNpc() => _addWorldName(
        type: WorldNoteType.npc,
        selected: session.npcsMet,
        onPicked: (value) => session.copyWith(
          npcsMet: [...session.npcsMet, value],
        ),
      );

  Future<void> _addLocation() => _addWorldName(
        type: WorldNoteType.location,
        selected: session.locationsVisited,
        onPicked: (value) => session.copyWith(
          locationsVisited: [...session.locationsVisited, value],
        ),
      );

  Future<void> _addWorldName({
    required WorldNoteType type,
    required List<String> selected,
    required SessionNote Function(String value) onPicked,
  }) async {
    final value = await _pickName(
      title: type == WorldNoteType.npc ? 'Add NPC' : 'Add Location',
      options: _availableWorldNames(type, selected),
    );
    if (value != null) {
      await _save(onPicked(value));
    }
  }

  Future<String?> _pickName({
    required String title,
    required List<String> options,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          if (options.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text('No available records. Add them in World first.'),
            )
          else
            for (final option in options)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(option),
                child: Text(option),
              ),
        ],
      ),
    );
  }

  Future<void> _removeNpc(String name) {
    return _save(
      session.copyWith(
        npcsMet: session.npcsMet.where((item) => item != name).toList(),
      ),
    );
  }

  Future<void> _removeLocation(String name) {
    return _save(
      session.copyWith(
        locationsVisited:
            session.locationsVisited.where((item) => item != name).toList(),
      ),
    );
  }

  Future<void> _addLoot() async {
    final entry = await showDialog<SessionLootEntry>(
      context: context,
      builder: (context) => const SessionLootDialog(),
    );
    if (entry != null) {
      await _save(
        session.copyWith(
          loot: '',
          lootEntries: [...session.lootEntries, entry],
        ),
      );
    }
  }

  Future<void> _editLoot(SessionLootEntry entry) async {
    final updated = await showDialog<SessionLootEntry>(
      context: context,
      builder: (context) => SessionLootDialog(existing: entry),
    );
    if (updated != null) {
      await _replaceLoot(updated);
    }
  }

  Future<void> _deleteLoot(SessionLootEntry entry) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete loot?',
      message: 'This removes the loot from this session.',
    );
    if (!confirmed) {
      return;
    }
    await _save(
      session.copyWith(
        loot: '',
        lootEntries:
            session.lootEntries.where((item) => item.id != entry.id).toList(),
      ),
    );
  }

  Future<void> _changeLootQuantity(SessionLootEntry entry, int delta) {
    return _replaceLoot(
      entry.copyWith(quantity: (entry.quantity + delta).clamp(1, 999)),
    );
  }

  Future<void> _setLootClaimed(SessionLootEntry entry, bool claimed) {
    return _replaceLoot(entry.copyWith(claimed: claimed));
  }

  Future<void> _replaceLoot(SessionLootEntry entry) {
    return _save(
      session.copyWith(
        loot: '',
        lootEntries: [
          for (final item in session.lootEntries)
            item.id == entry.id ? entry : item,
        ],
      ),
    );
  }
}
