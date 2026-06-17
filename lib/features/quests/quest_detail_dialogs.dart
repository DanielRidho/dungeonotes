import 'package:flutter/material.dart';

import '../../core/utils/id_generator.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/app_models.dart';

Future<Quest?> showQuestHeaderDialog(BuildContext context, Quest quest) {
  return showDialog<Quest>(
    context: context,
    builder: (_) => _QuestHeaderDialog(quest: quest),
  );
}

Future<CharacterListEntry?> showQuestObjectiveDialog(
  BuildContext context, {
  CharacterListEntry? existing,
}) {
  return showDialog<CharacterListEntry>(
    context: context,
    builder: (_) => _QuestObjectiveDialog(existing: existing),
  );
}

Future<String?> showQuestTextDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _QuestTextDialog(title: title, initialValue: initialValue),
  );
}

class _QuestHeaderDialog extends StatefulWidget {
  const _QuestHeaderDialog({required this.quest});

  final Quest quest;

  @override
  State<_QuestHeaderDialog> createState() => _QuestHeaderDialogState();
}

class _QuestHeaderDialogState extends State<_QuestHeaderDialog> {
  late final TextEditingController _title;
  late final TextEditingController _deadline;
  late QuestStatus _status;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.quest.title);
    _deadline = TextEditingController(text: widget.quest.deadline);
    _status = widget.quest.status;
  }

  @override
  void dispose() {
    _title.dispose();
    _deadline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: const Text('Edit Quest'),
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
        AppTextField(controller: _title, label: 'Title'),
        const SizedBox(height: 12),
        AppTextField(controller: _deadline, label: 'Deadline'),
        const SizedBox(height: 12),
        AppDropdown<QuestStatus>(
          label: 'Status',
          value: _status,
          items: QuestStatus.values,
          labelBuilder: (value) => value.label,
          onChanged: (value) {
            if (value != null) {
              setState(() => _status = value);
            }
          },
        ),
      ],
    );
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      widget.quest.copyWith(
        title: _title.text.trim(),
        deadline: _deadline.text.trim(),
        status: _status,
      ),
    );
  }
}

class _QuestObjectiveDialog extends StatefulWidget {
  const _QuestObjectiveDialog({this.existing});

  final CharacterListEntry? existing;

  @override
  State<_QuestObjectiveDialog> createState() => _QuestObjectiveDialogState();
}

class _QuestObjectiveDialogState extends State<_QuestObjectiveDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _description =
        TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeAlertDialog(
      title: Text(widget.existing == null ? 'Add Objective' : 'Edit Objective'),
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
        AppTextField(controller: _name, label: 'Title'),
        const SizedBox(height: 12),
        AppTextField(
          controller: _description,
          label: 'Description',
          maxLines: 4,
        ),
      ],
    );
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      CharacterListEntry(
        id: widget.existing?.id ?? IdGenerator.create(),
        name: _name.text.trim(),
        description: _description.text.trim(),
      ),
    );
  }
}

class _QuestTextDialog extends StatefulWidget {
  const _QuestTextDialog({
    required this.title,
    required this.initialValue,
  });

  final String title;
  final String initialValue;

  @override
  State<_QuestTextDialog> createState() => _QuestTextDialogState();
}

class _QuestTextDialogState extends State<_QuestTextDialog> {
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
      title: Text('Edit ${widget.title}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
      children: [
        AppTextField(
          controller: _controller,
          label: widget.title,
          maxLines: 5,
        ),
      ],
    );
  }
}
