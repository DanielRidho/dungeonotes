import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/utils/date_formatters.dart';
import '../../data/models/app_models.dart';
import '../campaigns/campaign_overview_header.dart';

class SessionHeaderSection extends StatelessWidget {
  const SessionHeaderSection({
    required this.session,
    required this.onEdit,
    super.key,
  });

  final SessionNote session;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormatters.shortDate.format(session.date),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit title and date',
              color: colors.primary,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
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

class SessionTextSection extends StatelessWidget {
  const SessionTextSection({
    required this.title,
    required this.icon,
    required this.text,
    required this.emptyMessage,
    required this.onEdit,
    required this.onClear,
    super.key,
  });

  final String title;
  final IconData icon;
  final String text;
  final String emptyMessage;
  final VoidCallback onEdit;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignSectionHeader(
          title: title,
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit $title',
                color: colors.primary,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Clear $title',
                color: colors.primary,
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (text.trim().isEmpty)
          CampaignCompactEmpty(
            icon: icon,
            title: 'No $title yet',
            message: emptyMessage,
            filled: false,
          )
        else
          Text(text),
      ],
    );
  }
}

class SessionEventsSection extends StatelessWidget {
  const SessionEventsSection({
    required this.events,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<SessionEventEntry> events;
  final VoidCallback onAdd;
  final ValueChanged<SessionEventEntry> onEdit;
  final ValueChanged<SessionEventEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignSectionHeader(
          title: 'Important Events',
          action: IconButton(
            tooltip: 'Add event',
            color: colors.primary,
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          const CampaignCompactEmpty(
            icon: Icons.timeline_outlined,
            title: 'No important events',
            message: 'Add turning points, reveals, and consequences.',
            filled: false,
          )
        else
          for (var index = 0; index < events.length; index++)
            _EventTile(
              event: events[index],
              isFirst: index == 0,
              isLast: index == events.length - 1,
              onEdit: () => onEdit(events[index]),
              onDelete: () => onDelete(events[index]),
            ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  final SessionEventEntry event;
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
                Expanded(child: _EventLine(visible: !isFirst)),
                CircleAvatar(radius: 7, backgroundColor: colors.primary),
                Expanded(child: _EventLine(visible: !isLast)),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (event.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(event.description),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Updated ${DateFormatters.shortDate.format(event.updatedAt)}',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        iconColor: colors.onSurfaceVariant,
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          }
                          if (value == 'delete') {
                            onDelete();
                          }
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

class _EventLine extends StatelessWidget {
  const _EventLine({required this.visible});

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

class SessionLinkedWorldSection extends StatelessWidget {
  const SessionLinkedWorldSection({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.icon,
    required this.names,
    required this.options,
    required this.onAdd,
    required this.onRemove,
    super.key,
    this.notesByName = const {},
  });

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final IconData icon;
  final List<String> names;
  final List<String> options;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final Map<String, WorldNote> notesByName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignSectionHeader(
          title: title,
          action: IconButton(
            tooltip: 'Add $title',
            color: colors.primary,
            onPressed: options.isEmpty ? null : onAdd,
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 8),
        if (names.isEmpty)
          CampaignCompactEmpty(
            icon: icon,
            title: emptyTitle,
            message: emptyMessage,
            filled: false,
          )
        else
          for (final name in names)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NameTile(
                name: name,
                note: notesByName[name],
                onRemove: () => onRemove(name),
              ),
            ),
      ],
    );
  }
}

class _NameTile extends StatelessWidget {
  const _NameTile({
    required this.name,
    required this.note,
    required this.onRemove,
  });

  final String name;
  final WorldNote? note;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imagePath = note?.imagePath.trim() ?? '';
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 42,
            child: imagePath.isEmpty
                ? ColoredBox(
                    color: colors.surfaceContainerHigh,
                    child: Center(child: Text(initial.toUpperCase())),
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    cacheWidth: 96,
                    cacheHeight: 96,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: colors.surfaceContainerHigh,
                      child: Center(child: Text(initial.toUpperCase())),
                    ),
                  ),
          ),
        ),
        title: Text(name),
        trailing: IconButton(
          tooltip: 'Remove',
          color: colors.primary,
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class SessionLootSection extends StatelessWidget {
  const SessionLootSection({
    required this.loot,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onQuantityChanged,
    required this.onClaimedChanged,
    super.key,
  });

  final List<SessionLootEntry> loot;
  final VoidCallback onAdd;
  final ValueChanged<SessionLootEntry> onEdit;
  final ValueChanged<SessionLootEntry> onDelete;
  final void Function(SessionLootEntry entry, int delta) onQuantityChanged;
  final void Function(SessionLootEntry entry, bool claimed) onClaimedChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignSectionHeader(
          title: 'Loot',
          action: IconButton(
            tooltip: 'Add loot',
            color: colors.primary,
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 8),
        if (loot.isEmpty)
          const CampaignCompactEmpty(
            icon: Icons.inventory_2_outlined,
            title: 'No loot yet',
            message: 'Track found items and whether they were claimed.',
            filled: false,
          )
        else
          for (final entry in loot)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LootTile(
                entry: entry,
                onEdit: () => onEdit(entry),
                onDelete: () => onDelete(entry),
                onMinus: () => onQuantityChanged(entry, -1),
                onPlus: () => onQuantityChanged(entry, 1),
                onClaimedChanged: (value) => onClaimedChanged(entry, value),
              ),
            ),
      ],
    );
  }
}

class _LootTile extends StatelessWidget {
  const _LootTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onMinus,
    required this.onPlus,
    required this.onClaimedChanged,
  });

  final SessionLootEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<bool> onClaimedChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (entry.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      entry.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  InputChip(
                    label: Text(entry.claimed ? 'Claimed' : 'Unclaimed'),
                    selected: entry.claimed,
                    onSelected: onClaimedChanged,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Decrease quantity',
              color: colors.onSurfaceVariant,
              onPressed: entry.quantity <= 1 ? null : onMinus,
              icon: const Icon(Icons.remove),
            ),
            Text('${entry.quantity}'),
            IconButton(
              tooltip: 'Increase quantity',
              color: colors.onSurfaceVariant,
              onPressed: onPlus,
              icon: const Icon(Icons.add),
            ),
            PopupMenuButton<String>(
              iconColor: colors.onSurfaceVariant,
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                }
                if (value == 'delete') {
                  onDelete();
                }
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
