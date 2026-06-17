import 'package:flutter/material.dart';

class CampaignSectionHeader extends StatelessWidget {
  const CampaignSectionHeader({
    required this.title,
    super.key,
    this.action,
  });

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class CampaignCompactEmpty extends StatelessWidget {
  const CampaignCompactEmpty({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.filled = true,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (!filled) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.82),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }
}
