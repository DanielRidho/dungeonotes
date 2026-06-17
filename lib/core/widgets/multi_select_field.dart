import 'package:flutter/material.dart';

class MultiSelectField extends StatelessWidget {
  const MultiSelectField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
    this.emptyText = 'None selected',
    this.allowCustom = false,
  });

  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String emptyText;
  final bool allowCustom;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected.isEmpty)
            Text(
              emptyText,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in selected) Chip(label: Text(item)),
              ],
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showPicker(context),
              icon: const Icon(Icons.checklist_outlined),
              label: const Text('Choose'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final search = TextEditingController();
    final custom = TextEditingController();
    final values = selected.toSet();
    final allOptions = {...options, ...selected}.where((item) => item.trim().isNotEmpty).toList()
      ..sort();

    try {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (context) {
          var query = '';
          return StatefulBuilder(
            builder: (context, setState) {
              final filtered = allOptions
                  .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                  .toList();
              return AlertDialog(
                title: Text(label),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: search,
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() => query = value),
                      ),
                      if (allowCustom) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: custom,
                                decoration: const InputDecoration(
                                  labelText: 'Custom',
                                ),
                                onSubmitted: (_) => _addCustom(
                                  custom,
                                  allOptions,
                                  values,
                                  setState,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _addCustom(
                                custom,
                                allOptions,
                                values,
                                setState,
                              ),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Flexible(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No options'))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return CheckboxListTile(
                                    value: values.contains(item),
                                    title: Text(item),
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked ?? false) {
                                          values.add(item);
                                        } else {
                                          values.remove(item);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      values.toList()..sort(),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (result != null) {
        onChanged(result);
      }
    } finally {
      search.dispose();
      custom.dispose();
    }
  }

  void _addCustom(
    TextEditingController controller,
    List<String> options,
    Set<String> values,
    StateSetter setState,
  ) {
    final value = controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    setState(() {
      if (!options.contains(value)) {
        options.add(value);
        options.sort();
      }
      values.add(value);
      controller.clear();
    });
  }
}
