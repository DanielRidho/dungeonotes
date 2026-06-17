import 'package:flutter/material.dart';

import '../../data/models/app_models.dart';

class EntryListEditor extends StatelessWidget {
  const EntryListEditor({
    required this.title,
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    super.key,
    this.addLabel = 'Add',
    this.emptyText = 'No entries yet.',
  });

  final String title;
  final String addLabel;
  final String emptyText;
  final List<CharacterListEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleSmall),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(addLabel),
              ),
            ],
          ),
        if (entries.isEmpty)
          Text(
            emptyText,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          )
        else
          for (var i = 0; i < entries.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                entries[i].quantity > 1
                    ? '${entries[i].name} x${entries[i].quantity}'
                    : entries[i].name,
              ),
              subtitle: entries[i].description.isEmpty
                  ? null
                  : Text(
                      entries[i].description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: _RowActions(
                onEdit: () => onEdit(i),
                onDelete: () => onDelete(i),
              ),
            ),
      ],
    );
  }
}

class WeaponListEditor extends StatelessWidget {
  const WeaponListEditor({
    required this.weapons,
    required this.onAddFromDb,
    required this.onAddCustom,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<CharacterWeapon> weapons;
  final VoidCallback onAddFromDb;
  final VoidCallback onAddCustom;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Weapons', style: Theme.of(context).textTheme.titleSmall),
            ),
            TextButton.icon(
              onPressed: onAddFromDb,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
            TextButton.icon(
              onPressed: onAddCustom,
              icon: const Icon(Icons.add),
              label: const Text('Custom'),
            ),
          ],
        ),
        if (weapons.isEmpty)
          Text(
            'No weapons yet.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          )
        else
          for (var i = 0; i < weapons.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                weapons[i].quantity > 1
                    ? '${weapons[i].name} x${weapons[i].quantity}'
                    : weapons[i].name,
              ),
              subtitle: Text(
                [
                  if (weapons[i].damageLabel.isNotEmpty)
                    weapons[i].damageLabel,
                  if (weapons[i].attackLabel.isEmpty &&
                      weapons[i].attackBonus != 0)
                    'attack ${weapons[i].attackBonus > 0 ? '+' : ''}${weapons[i].attackBonus}',
                  if (weapons[i].attackLabel.isNotEmpty)
                    'ATK/DC ${weapons[i].attackLabel}',
                  if (weapons[i].description.isNotEmpty)
                    weapons[i].description,
                ].join(' - '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _RowActions(
                onEdit: () => onEdit(i),
                onDelete: () => onDelete(i),
              ),
            ),
      ],
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        IconButton(
          tooltip: 'Edit',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
