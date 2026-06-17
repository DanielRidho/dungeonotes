import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/multi_select_field.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';

class SessionFormDraft {
  const SessionFormDraft({
    required this.title,
    required this.date,
    required this.summary,
    required this.importantEvents,
    required this.loot,
    required this.nextSessionReminderNote,
    required this.npcsMet,
    required this.locationsVisited,
  });

  final String title;
  final DateTime date;
  final String summary;
  final String importantEvents;
  final String loot;
  final String nextSessionReminderNote;
  final List<String> npcsMet;
  final List<String> locationsVisited;
}

class SessionFormSheet extends ConsumerStatefulWidget {
  const SessionFormSheet({
    required this.campaignId,
    super.key,
    this.existing,
  });

  final String campaignId;
  final SessionNote? existing;

  @override
  ConsumerState<SessionFormSheet> createState() => _SessionFormSheetState();
}

class _SessionFormSheetState extends ConsumerState<SessionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _events;
  late final TextEditingController _loot;
  late final TextEditingController _next;
  List<String> _npcsMet = const [];
  List<String> _locationsVisited = const [];
  List<WorldNote> _worldNotes = const [];
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final session = widget.existing;
    _title = TextEditingController(text: session?.title ?? '');
    _summary = TextEditingController(text: session?.summary ?? '');
    _events = TextEditingController(text: session?.importantEvents ?? '');
    _loot = TextEditingController(text: session?.loot ?? '');
    _next = TextEditingController(text: session?.nextSessionReminderNote ?? '');
    _npcsMet = List.of(session?.npcsMet ?? const []);
    _locationsVisited = List.of(session?.locationsVisited ?? const []);
    _date = session?.date ?? DateTime.now();
    _loadWorldNotes();
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _events.dispose();
    _loot.dispose();
    _next.dispose();
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
                  widget.existing == null ? 'Add Session' : 'Edit Session',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _title,
                  label: 'Title',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date'),
                  subtitle: Text(DateFormatters.shortDate.format(_date)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _summary, label: 'Summary', maxLines: 4),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _events,
                  label: 'Important events',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                MultiSelectField(
                  label: 'NPCs met',
                  options: _worldNames(WorldNoteType.npc),
                  selected: _npcsMet,
                  onChanged: (value) => setState(() => _npcsMet = value),
                  emptyText: 'No NPCs linked',
                ),
                const SizedBox(height: 12),
                MultiSelectField(
                  label: 'Locations visited',
                  options: _worldNames(WorldNoteType.location),
                  selected: _locationsVisited,
                  onChanged: (value) =>
                      setState(() => _locationsVisited = value),
                  emptyText: 'No locations linked',
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _loot, label: 'Loot', maxLines: 3),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _next,
                  label: 'Next session reminder note',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
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

  List<String> _worldNames(WorldNoteType type) {
    return _worldNotes
        .where((note) => note.type == type)
        .map((note) => note.name)
        .toList();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
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

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      SessionFormDraft(
        title: _title.text.trim(),
        date: _date,
        summary: _summary.text.trim(),
        importantEvents: _events.text.trim(),
        loot: _loot.text.trim(),
        nextSessionReminderNote: _next.text.trim(),
        npcsMet: List.of(_npcsMet),
        locationsVisited: List.of(_locationsVisited),
      ),
    );
  }
}
