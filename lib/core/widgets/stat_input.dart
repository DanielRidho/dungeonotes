import 'package:flutter/material.dart';

class StatInput extends StatelessWidget {
  const StatInput({
    required this.controller,
    required this.label,
    super.key,
    this.enabled = true,
    this.readOnly = false,
    this.hint,
    this.requiredField = false,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool readOnly;
  final String? hint;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          return requiredField ? 'Required' : null;
        }
        final number = int.tryParse(text);
        if (number == null) {
          return 'Enter a number';
        }
        if (number < 0) {
          return 'No negative values';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
