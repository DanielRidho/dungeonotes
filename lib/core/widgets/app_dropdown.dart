import 'package:flutter/material.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelBuilder,
    super.key,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T value) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(labelBuilder(item))),
      ],
      onChanged: onChanged,
    );
  }
}
