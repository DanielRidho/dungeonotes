import 'dart:io';

import 'package:flutter/material.dart';

class WorldNoteAvatar extends StatelessWidget {
  const WorldNoteAvatar({
    required this.name,
    required this.imagePath,
    required this.icon,
    super.key,
    this.size = 52,
  });

  final String name;
  final String imagePath;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: size,
        child: imagePath.trim().isEmpty
            ? ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Center(
                  child: Text(
                    initial.toUpperCase(),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                cacheWidth: cacheSize,
                cacheHeight: cacheSize,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: colors.surfaceContainerHighest,
                  child: Icon(icon, color: colors.onSurfaceVariant),
                ),
              ),
      ),
    );
  }
}
