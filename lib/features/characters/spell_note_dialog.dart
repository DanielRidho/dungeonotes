import 'package:flutter/material.dart';

import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/app_models.dart';

Future<SpellNote?> showSpellNoteDialog(
  BuildContext context, {
  SpellNote? existing,
}) {
  return showDialog<SpellNote>(
    context: context,
    builder: (context) => _SpellNoteDialog(existing: existing),
  );
}

class _SpellNoteDialog extends StatefulWidget {
  const _SpellNoteDialog({this.existing});

  final SpellNote? existing;

  @override
  State<_SpellNoteDialog> createState() => _SpellNoteDialogState();
}

class _SpellNoteDialogState extends State<_SpellNoteDialog> {
  late final TextEditingController _name;
  late final TextEditingController _level;
  late final TextEditingController _castingTime;
  late final TextEditingController _range;
  late final TextEditingController _note;
  late final Set<String> _components;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.spellName ?? '');
    _level = TextEditingController(text: existing?.spellLevel ?? '');
    _castingTime = TextEditingController(text: existing?.castingTime ?? '');
    _range = TextEditingController(text: existing?.range ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _components = {...existing?.components ?? const <String>[]};
  }

  @override
  void dispose() {
    _name.dispose();
    _level.dispose();
    _castingTime.dispose();
    _range.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: Text(
        widget.existing == null ? 'Add Spell Note' : 'Edit Spell Note',
      ),
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
          controller: _name,
          label: 'Spell name',
          autofocus: true,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        AppTextField(controller: _level, label: 'Level'),
        const SizedBox(height: 12),
        AppTextField(controller: _castingTime, label: 'Casting time'),
        const SizedBox(height: 12),
        AppTextField(controller: _range, label: 'Range'),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final component in const ['C', 'R', 'V', 'S', 'M'])
                FilterChip(
                  label: Text(component),
                  selected: _components.contains(component),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _components.add(component);
                    } else {
                      _components.remove(component);
                    }
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _note,
          label: 'Note / description',
          maxLines: 3,
        ),
      ],
    );
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      SpellNote(
        spellName: _name.text.trim(),
        spellLevel: _level.text.trim(),
        prepared: false,
        note: _note.text.trim(),
        castingTime: _castingTime.text.trim(),
        range: _range.text.trim(),
        components: _components.toList()..sort(),
      ),
    );
  }
}
