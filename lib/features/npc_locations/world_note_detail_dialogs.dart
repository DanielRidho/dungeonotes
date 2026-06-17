import 'package:flutter/material.dart';

import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/multi_select_field.dart';

Future<String?> showWorldTextDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  int maxLines = 1,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _WorldTextDialog(
      title: title,
      initialValue: initialValue,
      maxLines: maxLines,
    ),
  );
}

Future<String?> showSessionPickerDialog(
  BuildContext context, {
  required String current,
  required List<String> sessions,
}) async {
  var selected = current;
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => KeyboardSafeAlertDialog(
        title: const Text('Last Seen Session'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: const Text('Save'),
          ),
        ],
        children: [
          DropdownButtonFormField<String>(
            value: sessions.contains(selected) ? selected : '',
            decoration: const InputDecoration(labelText: 'Session'),
            items: [
              const DropdownMenuItem(value: '', child: Text('None')),
              for (final session in sessions)
                DropdownMenuItem(value: session, child: Text(session)),
            ],
            onChanged: (value) => setState(() => selected = value ?? ''),
          ),
        ],
      ),
    ),
  );
}

Future<List<String>?> showWorldMultiPickerDialog(
  BuildContext context, {
  required String title,
  required List<String> options,
  required List<String> selected,
}) {
  var values = List<String>.of(selected);
  return showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => KeyboardSafeAlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(values),
            child: const Text('Save'),
          ),
        ],
        children: [
          MultiSelectField(
            label: title,
            options: options,
            selected: values,
            onChanged: (next) => setState(() => values = next),
            emptyText: 'None selected',
          ),
        ],
      ),
    ),
  );
}

class _WorldTextDialog extends StatefulWidget {
  const _WorldTextDialog({
    required this.title,
    required this.initialValue,
    required this.maxLines,
  });

  final String title;
  final String initialValue;
  final int maxLines;

  @override
  State<_WorldTextDialog> createState() => _WorldTextDialogState();
}

class _WorldTextDialogState extends State<_WorldTextDialog> {
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
          maxLines: widget.maxLines,
        ),
      ],
    );
  }
}
