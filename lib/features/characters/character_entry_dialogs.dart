import 'package:flutter/material.dart';

import '../../core/utils/id_generator.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/app_models.dart';

Future<String?> showTextValueDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextValueDialog(
      title: title,
      label: label,
      initialValue: initialValue,
    ),
  );
}

Future<CharacterListEntry?> showCharacterEntryDialog(
  BuildContext context, {
  required String title,
  CharacterListEntry? existing,
  bool description = true,
  bool quantity = false,
}) {
  return showDialog<CharacterListEntry>(
    context: context,
    builder: (context) => _CharacterEntryDialog(
      title: title,
      existing: existing,
      description: description,
      quantity: quantity,
    ),
  );
}

Future<CharacterWeapon?> showCharacterWeaponDialog(
  BuildContext context, {
  CharacterWeapon? existing,
}) {
  return showDialog<CharacterWeapon>(
    context: context,
    builder: (context) => _CharacterWeaponDialog(existing: existing),
  );
}

class _TextValueDialog extends StatefulWidget {
  const _TextValueDialog({
    required this.title,
    required this.label,
    required this.initialValue,
  });

  final String title;
  final String label;
  final String initialValue;

  @override
  State<_TextValueDialog> createState() => _TextValueDialogState();
}

class _TextValueDialogState extends State<_TextValueDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: Text(widget.title),
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
          controller: _controller,
          label: widget.label,
          autofocus: true,
          onSubmitted: (_) => _save(),
        ),
      ],
    );
  }

  void _save() {
    Navigator.of(context).pop(_controller.text.trim());
  }
}

class _CharacterEntryDialog extends StatefulWidget {
  const _CharacterEntryDialog({
    required this.title,
    required this.description,
    required this.quantity,
    this.existing,
  });

  final String title;
  final CharacterListEntry? existing;
  final bool description;
  final bool quantity;

  @override
  State<_CharacterEntryDialog> createState() => _CharacterEntryDialogState();
}

class _CharacterEntryDialogState extends State<_CharacterEntryDialog> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late final TextEditingController _quantity;
  String? _quantityError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _note = TextEditingController(text: widget.existing?.description ?? '');
    _quantity =
        TextEditingController(text: '${widget.existing?.quantity ?? 1}');
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: Text(widget.title),
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
          label: 'Name',
          autofocus: true,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
          onSubmitted: (_) => _save(),
        ),
        if (widget.quantity) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              labelText: 'Quantity',
              errorText: _quantityError,
            ),
          ),
        ],
        if (widget.description) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _note,
            label: 'Description',
            maxLines: 3,
          ),
        ],
      ],
    );
  }

  void _save() {
    final parsedQuantity = int.tryParse(_quantity.text.trim()) ?? 1;
    if (_name.text.trim().isEmpty) {
      return;
    }
    if (widget.quantity && parsedQuantity < 1) {
      setState(() => _quantityError = 'Must be at least 1');
      return;
    }
    Navigator.of(context).pop(
      CharacterListEntry(
        id: widget.existing?.id ?? IdGenerator.create(),
        name: _name.text.trim(),
        description: _note.text.trim(),
        refId: widget.existing?.refId ?? '',
        quantity: widget.quantity
            ? parsedQuantity
            : widget.existing?.quantity ?? 1,
      ),
    );
  }
}

class _CharacterWeaponDialog extends StatefulWidget {
  const _CharacterWeaponDialog({this.existing});

  final CharacterWeapon? existing;

  @override
  State<_CharacterWeaponDialog> createState() => _CharacterWeaponDialogState();
}

class _CharacterWeaponDialogState extends State<_CharacterWeaponDialog> {
  late final TextEditingController _name;
  late final TextEditingController _attackOrDc;
  late final TextEditingController _damageAndType;
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  String? _quantityError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _attackOrDc = TextEditingController(text: existing?.attackLabel ?? '');
    _damageAndType = TextEditingController(text: existing?.damageLabel ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _quantity = TextEditingController(text: '${existing?.quantity ?? 1}');
  }

  @override
  void dispose() {
    _name.dispose();
    _attackOrDc.dispose();
    _damageAndType.dispose();
    _description.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: Text(widget.existing == null ? 'Add Weapon' : 'Edit Weapon'),
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
          label: 'Weapon name',
          autofocus: true,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        AppTextField(controller: _attackOrDc, label: 'ATK bonus / DC'),
        const SizedBox(height: 12),
        AppTextField(controller: _damageAndType, label: 'Damage & type'),
        const SizedBox(height: 12),
        TextField(
          controller: _quantity,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            labelText: 'Quantity',
            errorText: _quantityError,
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _description,
          label: 'Description',
          maxLines: 3,
        ),
      ],
    );
  }

  void _save() {
    final parsedQuantity = int.tryParse(_quantity.text.trim()) ?? 1;
    if (_name.text.trim().isEmpty) {
      return;
    }
    if (parsedQuantity < 1) {
      setState(() => _quantityError = 'Must be at least 1');
      return;
    }
    Navigator.of(context).pop(
      CharacterWeapon(
        id: widget.existing?.id ?? IdGenerator.create(),
        name: _name.text.trim(),
        refId: widget.existing?.refId ?? '',
        attackOrDc: _attackOrDc.text.trim(),
        damageAndType: _damageAndType.text.trim(),
        description: _description.text.trim(),
        quantity: parsedQuantity,
      ),
    );
  }
}
