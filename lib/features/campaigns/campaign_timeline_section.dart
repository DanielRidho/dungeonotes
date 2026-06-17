import 'package:flutter/material.dart';

import '../../core/utils/date_formatters.dart';
import '../../data/models/app_models.dart';
import 'campaign_overview_header.dart';

class CampaignTimelineList extends StatelessWidget {
  const CampaignTimelineList(this.sessions, {super.key});

  final List<SessionNote> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const CampaignCompactEmpty(
        icon: Icons.timeline_outlined,
        title: 'No timeline yet',
        message: 'Session notes will appear here automatically.',
        filled: false,
      );
    }

    final chronological = List<SessionNote>.of(sessions)
      ..sort((a, b) => a.date.compareTo(b.date));
    final newestFirst = chronological.reversed.toList();
    return Column(
      children: [
        for (var index = 0; index < newestFirst.length; index++)
          _TimelineTile(
            number: chronological.indexOf(newestFirst[index]) + 1,
            session: newestFirst[index],
            isFirst: index == 0,
            isLast: index == newestFirst.length - 1,
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.number,
    required this.session,
    required this.isFirst,
    required this.isLast,
  });

  final int number;
  final SessionNote session;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Expanded(child: _TimelineLine(visible: !isFirst)),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Text('$number'),
                ),
                Expanded(child: _TimelineLine(visible: !isLast)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session $number - ${session.title}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(DateFormatters.shortDate.format(session.date)),
                      if (session.locationsVisited.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(session.locationsVisited.join(', ')),
                      ],
                      if (session.importantEvents.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          session.importantEvents,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineLine extends StatelessWidget {
  const _TimelineLine({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      color: visible
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.45)
          : Colors.transparent,
    );
  }
}
