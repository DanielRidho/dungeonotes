import 'dart:io';

import 'package:flutter/material.dart';

class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    required this.imagePath,
    super.key,
    this.size = 64,
    this.borderRadius = 999,
  });

  final String imagePath;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: imagePath.trim().isEmpty
            ? _placeholder(colors)
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                cacheWidth: cacheSize,
                cacheHeight: cacheSize,
                errorBuilder: (context, error, stackTrace) =>
                    _placeholder(colors),
              ),
      ),
    );
  }

  Widget _placeholder(ColorScheme colors) {
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.person_outline,
        color: colors.onSurfaceVariant,
        size: size * 0.46,
      ),
    );
  }
}
