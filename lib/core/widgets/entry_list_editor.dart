import 'package:flutter/material.dart';

import '../../core/utils/id_generator.dart';
import '../../data/models/app_models.dart';
import 'app_text_field.dart';

class EntryListEditor extends StatelessWidget {
  const EntryListEditor({
    required this.title,
    required this.entries,
    required this.onChanged,
    super.key,
    this.addLabel = 'Add',
    this.emptyText = 'No entries yet.',
  });

  final String title;
  final List<CharacterListEntry> entries;
  final ValueChanged<List<CharacterListEntry>> onChanged;
  final String addLabel;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.add),
                  label: Text(addLabel),
                ),
              ],
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  emptyText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var index = 0; index < entries.length; index++)
                _EntryTile(
                  entry: entries[index],
                  onEdit: () => _edit(context, index: index),
                  onDelete: () {
                    final next = List<CharacterListEntry>.of(entries)
                      ..removeAt(index);
                    onChanged(next);
                  },
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, {int? index}) async {
    final existing = index == null ? null : entries[index];
    final result = await showEntryDialog(
      context,
      title: existing == null ? addLabel : 'Edit $title',
      existing: existing,
    );
    if (result == null) {
      return;
    }
    final next = List<CharacterListEntry>.of(entries);
    if (index == null) {
      next.add(result);
    } else {
      next[index] = result;
    }
    onChanged(next);
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final CharacterListEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(entry.name),
      subtitle: entry.description.trim().isEmpty
          ? null
          : Text(
              entry.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            onEdit();
          }
          if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

Future<CharacterListEntry?> showEntryDialog(
  BuildContext context, {
  required String title,
  CharacterListEntry? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final description = TextEditingController(text: existing?.description ?? '');
  final formKey = GlobalKey<FormState>();

  try {
    return await showDialog<CharacterListEntry>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: name,
                  label: 'Name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: description,
                  label: 'Description',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }
              Navigator.of(context).pop(
                CharacterListEntry(
                  id: existing?.id ?? IdGenerator.create(),
                  name: name.text.trim(),
                  description: description.text.trim(),
                  refId: existing?.refId ?? '',
                  quantity: existing?.quantity ?? 1,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  } finally {
    name.dispose();
    description.dispose();
  }
}
