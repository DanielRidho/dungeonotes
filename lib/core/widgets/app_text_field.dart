import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    super.key,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.enabled,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool? enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction:
          textInputAction ?? (maxLines == 1 ? TextInputAction.done : null),
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted ?? (_) => FocusScope.of(context).unfocus(),
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      enabled: enabled,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}
