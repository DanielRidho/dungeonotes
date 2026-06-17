import 'package:flutter/material.dart';

void showAppSnack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final colors = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? colors.error : null,
    ),
  );
}
