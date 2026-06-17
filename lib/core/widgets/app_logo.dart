import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 28,
    this.color,
    this.alignment = Alignment.centerLeft,
  });

  static const assetPath = 'assets/brand/dungeonotes_horizontal.svg';

  final double height;
  final Color? color;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: alignment,
      widthFactor: 1,
      child: SvgPicture.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
        semanticsLabel: 'Dungeonotes',
      ),
    );
  }
}
