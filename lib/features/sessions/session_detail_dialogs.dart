import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/date_formatters.dart';
import '../../core/utils/id_generator.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/app_models.dart';

class QuickRecapDraft {
  const QuickRecapDraft({required this.title, required this.summary});

  final String title;
  final String summary;
}

class QuickRecapDialog extends StatefulWidget {
  const QuickRecapDialog({super.key});

  @override
  State<QuickRecapDialog> createState() => _QuickRecapDialogState();
}

class _QuickRecapDialogState extends State<QuickRecapDialog> {
  late final TextEditingController _title;
  late final TextEditingController _summary;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _summary = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: const Text('Quick Recap'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
      children: [
        AppTextField(
          controller: _title,
          label: 'Title',
          autofocus: true,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _summary,
          label: 'What happened?',
          maxLines: 4,
        ),
      ],
    );
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      QuickRecapDraft(title: title, summary: _summary.text.trim()),
    );
  }
}

class SessionHeaderDraft {
  const SessionHeaderDraft({required this.title, required this.date});

  final String title;
  final DateTime date;
}

class SessionHeaderDialog extends StatefulWidget {
  const SessionHeaderDialog({required this.session, super.key});

  final SessionNote session;

  @override
  State<SessionHeaderDialog> createState() => _SessionHeaderDialogState();
}

class _SessionHeaderDialogState extends State<SessionHeaderDialog> {
  late final TextEditingController _title;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.session.title);
    _date = widget.session.date;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: const Text('Edit Session'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
      children: [
        AppTextField(
          controller: _title,
          label: 'Title',
          autofocus: true,
          onSubmitted: (_) => _save(),
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
      ],
    );
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

  void _save() {
    if (_title.text.trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      SessionHeaderDraft(title: _title.text.trim(), date: _date),
    );
  }
}

class SessionTextEditDialog extends StatefulWidget {
  const SessionTextEditDialog({
    required this.title,
    required this.label,
    required this.value,
    super.key,
  });

  final String title;
  final String label;
  final String value;

  @override
  State<SessionTextEditDialog> createState() => _SessionTextEditDialogState();
}

class _SessionTextEditDialogState extends State<SessionTextEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
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
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
      children: [
        AppTextField(
          controller: _controller,
          label: widget.label,
          maxLines: 5,
          autofocus: true,
        ),
      ],
    );
  }
}

class SessionEventDialog extends StatefulWidget {
  const SessionEventDialog({super.key, this.existing});

  final SessionEventEntry? existing;

  @override
  State<SessionEventDialog> createState() => _SessionEventDialogState();
}

class _SessionEventDialogState extends State<SessionEventDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _description =
        TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: Text(widget.existing == null ? 'Add Event' : 'Edit Event'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
      children: [
        AppTextField(
          controller: _title,
          label: 'Title',
          autofocus: true,
          onSubmitted: (_) => _save(),
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
    if (_title.text.trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      SessionEventEntry(
        id: widget.existing?.id ?? IdGenerator.create(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class SessionLootDialog extends StatefulWidget {
  const SessionLootDialog({super.key, this.existing});

  final SessionLootEntry? existing;

  @override
  State<SessionLootDialog> createState() => _SessionLootDialogState();
}

class _SessionLootDialogState extends State<SessionLootDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _quantity = TextEditingController(text: '${existing?.quantity ?? 1}');
    _claimed = existing?.claimed ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: Text(widget.existing == null ? 'Add Loot' : 'Edit Loot'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
      children: [
        AppTextField(
          controller: _name,
          label: 'Name',
          autofocus: true,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _quantity,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _description,
          label: 'Description',
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Claimed'),
          value: _claimed,
          onChanged: (value) => setState(() => _claimed = value),
        ),
      ],
    );
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      return;
    }
    final quantity = int.tryParse(_quantity.text.trim()) ?? 1;
    Navigator.of(context).pop(
      SessionLootEntry(
        id: widget.existing?.id ?? IdGenerator.create(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        quantity: quantity < 1 ? 1 : quantity,
        claimed: _claimed,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
