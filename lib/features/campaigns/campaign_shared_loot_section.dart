import 'package:flutter/material.dart';

import '../../data/models/app_models.dart';
import 'campaign_overview_header.dart';

class CampaignSharedLootSection extends StatelessWidget {
  const CampaignSharedLootSection({
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onQuantityChanged,
    super.key,
  });

  final List<CharacterListEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<CharacterListEntry> onEdit;
  final ValueChanged<CharacterListEntry> onDelete;
  final void Function(CharacterListEntry entry, int delta) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignSectionHeader(
          title: 'Shared Loot',
          action: IconButton(
            tooltip: 'Add shared loot',
            color: colors.primary,
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          const CampaignCompactEmpty(
            icon: Icons.inventory_2_outlined,
            title: 'No shared loot',
            message: 'Track party loot before it is divided.',
            filled: false,
          )
        else
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LootTile(
                entry: entry,
                onEdit: () => onEdit(entry),
                onDelete: () => onDelete(entry),
                onMinus: () => onQuantityChanged(entry, -1),
                onPlus: () => onQuantityChanged(entry, 1),
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
  });

  final CharacterListEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
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
                    const SizedBox(height: 4),
                    Text(
                      entry.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
