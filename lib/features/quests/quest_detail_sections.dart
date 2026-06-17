import 'package:flutter/material.dart';

import '../../data/models/app_models.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../campaigns/campaign_overview_header.dart';
import '../sessions/session_detail_sections.dart';

class QuestHeaderSection extends StatelessWidget {
  const QuestHeaderSection({
    required this.quest,
    required this.onEdit,
    super.key,
  });

  final Quest quest;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text(
                    quest.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  QuestStatusChip(status: quest.status),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit quest',
              color: colors.primary,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        if (quest.deadline.isNotEmpty)
          Text(
            'Deadline: ${quest.deadline}',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        const SizedBox(height: 12),
        Divider(
          height: 1,
          thickness: 1.2,
          color: colors.primary.withValues(alpha: 0.72),
        ),
      ],
    );
  }
}

class QuestStatusChip extends StatelessWidget {
  const QuestStatusChip({required this.status, super.key});

  final QuestStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = switch (status) {
      QuestStatus.active => colors.primary,
      QuestStatus.completed => Colors.green.shade700,
      QuestStatus.failed => colors.error,
      QuestStatus.onHold => colors.surfaceContainerHighest,
    };
    final foreground =
        status == QuestStatus.onHold ? colors.onSurfaceVariant : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class QuestObjectivesSection extends StatelessWidget {
  const QuestObjectivesSection({
    required this.objectives,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<CharacterListEntry> objectives;
  final VoidCallback onAdd;
  final ValueChanged<CharacterListEntry> onEdit;
  final ValueChanged<CharacterListEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignSectionHeader(
          title: 'Objectives',
          action: IconButton(
            tooltip: 'Add objective',
            color: colors.primary,
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 8),
        if (objectives.isEmpty)
          const CampaignCompactEmpty(
            icon: Icons.flag_outlined,
            title: 'No objectives',
            message: 'Break this quest into clear steps.',
            filled: false,
          )
        else
          for (var index = 0; index < objectives.length; index++)
            _ObjectiveTile(
              entry: objectives[index],
              isFirst: index == 0,
              isLast: index == objectives.length - 1,
              onEdit: () => onEdit(objectives[index]),
              onDelete: () => onDelete(objectives[index]),
            ),
      ],
    );
  }
}

class _ObjectiveTile extends StatelessWidget {
  const _ObjectiveTile({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  final CharacterListEntry entry;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Expanded(child: _Line(visible: !isFirst)),
                CircleAvatar(radius: 7, backgroundColor: colors.primary),
                Expanded(child: _Line(visible: !isLast)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(entry.name),
                  subtitle:
                      entry.description.isEmpty ? null : Text(entry.description),
                  trailing: PopupMenuButton<String>(
                    iconColor: colors.onSurfaceVariant,
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      color: visible
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.45)
          : Colors.transparent,
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

class QuestLinkedNameSection extends StatelessWidget {
  const QuestLinkedNameSection({
    required this.title,
    required this.name,
    required this.icon,
    required this.options,
    required this.onChanged,
    super.key,
    this.notesByName = const {},
  });

  final String title;
  final String name;
  final IconData icon;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final Map<String, WorldNote> notesByName;

  @override
  Widget build(BuildContext context) {
    return SessionLinkedWorldSection(
      title: title,
      emptyTitle: 'No $title',
      emptyMessage: 'Pick one from your World notes.',
      icon: icon,
      names: name.isEmpty ? const [] : [name],
      options: options,
      notesByName: notesByName,
      onAdd: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text('Pick $title'),
            children: [
              for (final option in options)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(option),
                  child: Text(option),
                ),
            ],
          ),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      onRemove: (_) async {
        final confirmed = await ConfirmDialog.show(
          context,
          title: 'Remove $title?',
          message: 'This unlinks the record from this quest.',
        );
        if (confirmed) {
          onChanged('');
        }
      },
    );
  }
}
