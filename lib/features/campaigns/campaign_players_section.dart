import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/id_generator.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/app_models.dart';
import 'campaign_overview_header.dart';

class CampaignPlayersSection extends StatelessWidget {
  const CampaignPlayersSection({
    required this.players,
    required this.onAdd,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<CampaignPlayer> players;
  final VoidCallback onAdd;
  final ValueChanged<CampaignPlayer> onDetail;
  final ValueChanged<CampaignPlayer> onEdit;
  final ValueChanged<CampaignPlayer> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignSectionHeader(
          title: 'Players',
          action: IconButton(
            tooltip: 'Add player',
            color: colors.primary,
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 10),
        if (players.isEmpty)
          const CampaignCompactEmpty(
            icon: Icons.groups_outlined,
            title: 'No players yet',
            message: 'Add table members and their campaign roles.',
            filled: false,
          )
        else
          for (final player in players)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlayerTile(
                player: player,
                onDetail: () => onDetail(player),
                onEdit: () => onEdit(player),
                onDelete: () => onDelete(player),
              ),
            ),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.player,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  final CampaignPlayer player;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmedName = player.characterName.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.characters.first;
    final subtitle = [
      if (player.species.isNotEmpty) player.species,
      if (player.className.isNotEmpty) player.className,
      'Level ${player.level}',
    ].join(' - ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(child: Text(initial.toUpperCase())),
        title: Text(player.characterName),
        subtitle: Text(
          [
            if (player.playerName.isNotEmpty) player.playerName,
            subtitle,
          ].join('\n'),
        ),
        isThreeLine: player.playerName.isNotEmpty,
        trailing: PopupMenuButton<String>(
          iconColor: colors.onSurfaceVariant,
          onSelected: (value) {
            if (value == 'detail') {
              onDetail();
            }
            if (value == 'edit') {
              onEdit();
            }
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'detail',
              child: _MenuAction(
                icon: Icons.info_outline,
                label: 'Detail',
                color: colors.onSurfaceVariant,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: _MenuAction(
                icon: Icons.edit_outlined,
                label: 'Edit',
                color: colors.onSurfaceVariant,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: _MenuAction(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class CampaignPlayerDialog extends StatefulWidget {
  const CampaignPlayerDialog({super.key, this.existing});

  final CampaignPlayer? existing;

  @override
  State<CampaignPlayerDialog> createState() => _CampaignPlayerDialogState();
}

class _CampaignPlayerDialogState extends State<CampaignPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _characterName;
  late final TextEditingController _playerName;
  late final TextEditingController _className;
  late final TextEditingController _species;
  late final TextEditingController _level;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _characterName = TextEditingController(text: existing?.characterName ?? '');
    _playerName = TextEditingController(text: existing?.playerName ?? '');
    _className = TextEditingController(text: existing?.className ?? '');
    _species = TextEditingController(text: existing?.species ?? '');
    _level = TextEditingController(text: '${existing?.level ?? 1}');
    _description = TextEditingController(text: existing?.description ?? '');
  }

  @override
  void dispose() {
    _characterName.dispose();
    _playerName.dispose();
    _className.dispose();
    _species.dispose();
    _level.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: Text(widget.existing == null ? 'Add Player' : 'Edit Player'),
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
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _characterName,
                label: 'Character name',
                validator: _required,
                autofocus: true,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _playerName, label: 'Player name'),
              const SizedBox(height: 12),
              AppTextField(controller: _species, label: 'Species'),
              const SizedBox(height: 12),
              AppTextField(controller: _className, label: 'Class'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _level,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final level = int.tryParse(value?.trim() ?? '');
                  if (level == null || level < 1 || level > 20) {
                    return 'Level must be 1-20';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _save(),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: const InputDecoration(labelText: 'Level'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _description,
                label: 'Description',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final level = int.tryParse(_level.text.trim()) ?? 1;
    Navigator.of(context).pop(
      CampaignPlayer(
        id: widget.existing?.id ?? IdGenerator.create(),
        characterName: _characterName.text.trim(),
        playerName: _playerName.text.trim(),
        className: _className.text.trim(),
        species: _species.text.trim(),
        level: level.clamp(1, 20),
        description: _description.text.trim(),
      ),
    );
  }
}
