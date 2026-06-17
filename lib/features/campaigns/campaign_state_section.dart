import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/app_models.dart';
import 'campaign_overview_header.dart';

class CampaignStateSection extends StatelessWidget {
  const CampaignStateSection({
    required this.campaign,
    required this.location,
    required this.day,
    required this.date,
    required this.time,
    required this.onEdit,
    super.key,
  });

  final Campaign campaign;
  final TextEditingController location;
  final TextEditingController day;
  final TextEditingController date;
  final TextEditingController time;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignSectionHeader(
          title: 'Campaign State',
          action: IconButton(
            tooltip: 'Edit campaign state',
            color: colors.primary,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ),
        const SizedBox(height: 10),
        _CampaignCoverState(
          campaign: campaign,
          location: location.text.trim().isEmpty
              ? 'Unknown location'
              : location.text.trim(),
        ),
        const SizedBox(height: 12),
        _StateValueRow(
          icon: Icons.event_note_outlined,
          label: 'Session',
          value: day.text.trim().isEmpty ? '-' : day.text.trim(),
        ),
        const SizedBox(height: 8),
        _StateValueRow(
          icon: Icons.calendar_month_outlined,
          label: 'Fantasy Date',
          value: date.text.trim().isEmpty ? '-' : date.text.trim(),
        ),
        const SizedBox(height: 8),
        _StateValueRow(
          icon: Icons.schedule_outlined,
          label: 'Time',
          value: time.text.trim().isEmpty ? '-' : time.text.trim(),
        ),
      ],
    );
  }
}

class _CampaignCoverState extends StatelessWidget {
  const _CampaignCoverState({
    required this.campaign,
    required this.location,
  });

  final Campaign campaign;
  final String location;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final path = campaign.imagePath.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (path.isEmpty)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(campaign.colorTag).withValues(alpha: 0.38),
                      colors.surfaceContainerHighest,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.map_outlined,
                  size: 54,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.72),
                ),
              )
            else
              Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                  ),
                  child: const Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Current Location',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white70,
                                    letterSpacing: 0.6,
                                  ),
                        ),
                        Text(
                          location,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateValueRow extends StatelessWidget {
  const _StateValueRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon),
        title: Text(label),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
