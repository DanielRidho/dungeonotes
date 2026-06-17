import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/snackbars.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/app_models.dart';
import '../characters/character_entry_dialogs.dart';
import '../dice_roller/dice_launcher.dart';
import '../sessions/sessions_controller.dart';
import 'campaign_overview_header.dart';
import 'campaign_players_section.dart';
import 'campaign_shared_loot_section.dart';
import 'campaign_state_section.dart';
import 'campaign_timeline_section.dart';
import 'campaigns_controller.dart';

class CampaignOverviewTab extends ConsumerStatefulWidget {
  const CampaignOverviewTab({
    required this.campaign,
    super.key,
  });

  final Campaign campaign;

  @override
  ConsumerState<CampaignOverviewTab> createState() =>
      _CampaignOverviewTabState();
}

class _CampaignOverviewTabState extends ConsumerState<CampaignOverviewTab> {
  late final TextEditingController _location;
  late final TextEditingController _day;
  late final TextEditingController _date;
  late final TextEditingController _time;
  late final TextEditingController _description;
  late List<CharacterListEntry> _sharedLoot;
  late List<CampaignPlayer> _players;

  @override
  void initState() {
    super.initState();
    _location = TextEditingController(text: widget.campaign.currentLocation);
    _day = TextEditingController(text: widget.campaign.worldDay);
    _date = TextEditingController(text: widget.campaign.worldDate);
    _time = TextEditingController(text: widget.campaign.worldTime);
    _description = TextEditingController(text: widget.campaign.description);
    _sharedLoot = List.of(widget.campaign.sharedLoot);
    _players = List.of(widget.campaign.players);
  }

  @override
  void didUpdateWidget(covariant CampaignOverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaign.id != widget.campaign.id ||
        oldWidget.campaign.updatedAt != widget.campaign.updatedAt) {
      _location.text = widget.campaign.currentLocation;
      _day.text = widget.campaign.worldDay;
      _date.text = widget.campaign.worldDate;
      _time.text = widget.campaign.worldTime;
      _description.text = widget.campaign.description;
      _sharedLoot = List.of(widget.campaign.sharedLoot);
      _players = List.of(widget.campaign.players);
    }
  }

  @override
  void dispose() {
    _location.dispose();
    _day.dispose();
    _date.dispose();
    _time.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsControllerProvider(widget.campaign.id));
    return Scaffold(
      floatingActionButton: const DiceActionButton(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          CampaignStateSection(
            campaign: widget.campaign,
            location: _location,
            day: _day,
            date: _date,
            time: _time,
            onEdit: _editCampaignState,
          ),
          const SizedBox(height: 20),
          CampaignPlayersSection(
            players: _players,
            onAdd: _addPlayer,
            onDetail: _showPlayerDetail,
            onEdit: _editPlayer,
            onDelete: _deletePlayer,
          ),
          const SizedBox(height: 20),
          CampaignSharedLootSection(
            entries: _sharedLoot,
            onAdd: _addLoot,
            onEdit: _editLoot,
            onDelete: _deleteLoot,
            onQuantityChanged: _changeLootQuantity,
          ),
          const SizedBox(height: 20),
          const CampaignSectionHeader(title: 'Timeline / History'),
          const SizedBox(height: 10),
          sessions.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text(error.toString()),
            data: CampaignTimelineList.new,
          ),
          const SizedBox(height: 20),
          _DescriptionSection(
            text: _description.text.trim(),
            onEdit: _editDescription,
            onClear: _clearDescription,
          ),
        ],
      ),
    );
  }

  Future<void> _save({bool showMessage = true}) async {
    try {
      await ref.read(campaignsControllerProvider.notifier).saveOverview(
            campaign: widget.campaign,
            currentLocation: _location.text,
            worldDay: _day.text,
            worldDate: _date.text,
            worldTime: _time.text,
            sharedLoot: _sharedLoot,
            players: _players,
            description: _description.text,
          );
      if (mounted && showMessage) {
        showAppSnack(context, 'Campaign overview saved');
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _editCampaignState() async {
    final draft = await showDialog<_CampaignStateDraft>(
      context: context,
      builder: (context) => _CampaignStateDialog(
        location: _location.text,
        session: _day.text,
        date: _date.text,
        time: _time.text,
      ),
    );
    if (draft == null) {
      return;
    }
    setState(() {
      _location.text = draft.location.trim();
      _day.text = draft.session.trim();
      _date.text = draft.date.trim();
      _time.text = draft.time.trim();
    });
    await _save();
  }

  Future<void> _editDescription() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _DescriptionDialog(text: _description.text),
    );
    if (value == null) {
      return;
    }
    setState(() => _description.text = value.trim());
    await _save();
  }

  Future<void> _clearDescription() async {
    if (_description.text.trim().isEmpty) {
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Clear description?',
      message: 'This removes the campaign description.',
      confirmLabel: 'Clear',
    );
    if (!confirmed) {
      return;
    }
    setState(() => _description.clear());
    await _save();
  }

  Future<void> _addPlayer() async {
    final player = await showDialog<CampaignPlayer>(
      context: context,
      builder: (context) => const CampaignPlayerDialog(),
    );
    if (player != null) {
      setState(() => _players = [..._players, player]);
      await _save(showMessage: false);
    }
  }

  Future<void> _editPlayer(CampaignPlayer player) async {
    final updated = await showDialog<CampaignPlayer>(
      context: context,
      builder: (context) => CampaignPlayerDialog(existing: player),
    );
    if (updated == null) {
      return;
    }
    setState(() {
      _players = [
        for (final item in _players) item.id == updated.id ? updated : item,
      ];
    });
    await _save(showMessage: false);
  }

  Future<void> _deletePlayer(CampaignPlayer player) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete player?',
      message: 'This removes the player note from this campaign.',
    );
    if (confirmed) {
      setState(() {
        _players = _players.where((item) => item.id != player.id).toList();
      });
      await _save(showMessage: false);
    }
  }

  void _showPlayerDetail(CampaignPlayer player) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(player.characterName),
        content: Text(
          player.description.isEmpty
              ? 'No description yet.'
              : player.description,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _addLoot() async {
    final entry = await showCharacterEntryDialog(
      context,
      title: 'Add Shared Loot',
      quantity: true,
    );
    if (entry != null) {
      setState(() => _sharedLoot = [..._sharedLoot, entry]);
      await _save(showMessage: false);
    }
  }

  Future<void> _editLoot(CharacterListEntry entry) async {
    final updated = await showCharacterEntryDialog(
      context,
      title: 'Edit Shared Loot',
      existing: entry,
      quantity: true,
    );
    if (updated == null) {
      return;
    }
    setState(() {
      _sharedLoot = [
        for (final item in _sharedLoot) item.id == updated.id ? updated : item,
      ];
    });
    await _save(showMessage: false);
  }

  Future<void> _deleteLoot(CharacterListEntry entry) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete loot?',
      message: 'This removes the shared loot note from this campaign.',
    );
    if (confirmed) {
      setState(() {
        _sharedLoot = _sharedLoot.where((item) => item.id != entry.id).toList();
      });
      await _save(showMessage: false);
    }
  }

  void _changeLootQuantity(CharacterListEntry entry, int delta) {
    final next = (entry.quantity + delta).clamp(1, 999);
    setState(() {
      _sharedLoot = [
        for (final item in _sharedLoot)
          item.id == entry.id ? item.copyWith(quantity: next) : item,
      ];
    });
    _save(showMessage: false);
  }
}

class _CampaignStateDraft {
  const _CampaignStateDraft({
    required this.location,
    required this.session,
    required this.date,
    required this.time,
  });

  final String location;
  final String session;
  final String date;
  final String time;
}

class _CampaignStateDialog extends StatefulWidget {
  const _CampaignStateDialog({
    required this.location,
    required this.session,
    required this.date,
    required this.time,
  });

  final String location;
  final String session;
  final String date;
  final String time;

  @override
  State<_CampaignStateDialog> createState() => _CampaignStateDialogState();
}

class _CampaignStateDialogState extends State<_CampaignStateDialog> {
  late final TextEditingController _location;
  late final TextEditingController _session;
  late final TextEditingController _date;
  late final TextEditingController _time;

  @override
  void initState() {
    super.initState();
    _location = TextEditingController(text: widget.location);
    _session = TextEditingController(text: widget.session);
    _date = TextEditingController(text: widget.date);
    _time = TextEditingController(text: widget.time);
  }

  @override
  void dispose() {
    _location.dispose();
    _session.dispose();
    _date.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: const Text('Edit Campaign State'),
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
        AppTextField(
          controller: _location,
          label: 'Current location',
          prefixIcon: Icons.place_outlined,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _session,
          label: 'Session',
          hint: 'Session 4',
          prefixIcon: Icons.event_note_outlined,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _date,
          label: 'Fantasy date',
          hint: '15th Hammer',
          prefixIcon: Icons.calendar_month_outlined,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _time,
          label: 'Time',
          hint: 'Noon',
          prefixIcon: Icons.schedule_outlined,
          onSubmitted: (_) => _save(),
        ),
      ],
    );
  }

  void _save() {
    Navigator.of(context).pop(
      _CampaignStateDraft(
        location: _location.text,
        session: _session.text,
        date: _date.text,
        time: _time.text,
      ),
    );
  }
}

class _DescriptionDialog extends StatefulWidget {
  const _DescriptionDialog({required this.text});

  final String text;

  @override
  State<_DescriptionDialog> createState() => _DescriptionDialogState();
}

class _DescriptionDialogState extends State<_DescriptionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: const Text('Edit Description'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
      children: [
        AppTextField(
          controller: _controller,
          label: 'Campaign description',
          maxLines: 5,
          autofocus: true,
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.text,
    required this.onEdit,
    required this.onClear,
  });

  final String text;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignSectionHeader(
          title: 'Description',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit description',
                color: colors.primary,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Clear description',
                color: colors.primary,
                onPressed: text.isEmpty ? null : onClear,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (text.isEmpty)
          const CampaignCompactEmpty(
            icon: Icons.notes_outlined,
            title: 'No description yet',
            message: 'Add a short campaign premise or table note.',
            filled: false,
          )
        else
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
          ),
      ],
    );
  }
}
