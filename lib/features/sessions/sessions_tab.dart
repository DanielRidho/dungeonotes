import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_formatters.dart';
import '../../core/utils/snackbars.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/app_models.dart';
import '../dice_roller/dice_launcher.dart';
import '../campaigns/campaigns_controller.dart';
import 'session_detail_dialogs.dart';
import 'session_detail_screen.dart';
import 'session_form_sheet.dart';
import 'sessions_controller.dart';

class SessionsTab extends ConsumerStatefulWidget {
  const SessionsTab({required this.campaignId, super.key});

  final String campaignId;

  @override
  ConsumerState<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends ConsumerState<SessionsTab> {
  final _search = TextEditingController();
  var _newestFirst = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsControllerProvider(widget.campaignId));
    return Scaffold(
      floatingActionButton: DicePageActionGroup(
        primaryAction: FloatingActionButton(
          heroTag: 'add-session',
          tooltip: 'Add session',
          onPressed: () => _showForm(context),
          child: const Icon(Icons.add),
        ),
      ),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          title: 'Could not load sessions',
          message: error.toString(),
          onRetry: () => ref
              .read(sessionsControllerProvider(widget.campaignId).notifier)
              .load(),
        ),
        data: (items) {
          final query = _search.text.trim().toLowerCase();
          final filtered = items.where((session) {
            return session.title.toLowerCase().contains(query) ||
                session.summary.toLowerCase().contains(query) ||
                session.importantEvents.toLowerCase().contains(query) ||
                session.eventEntries.any(
                  (item) =>
                      item.title.toLowerCase().contains(query) ||
                      item.description.toLowerCase().contains(query),
                ) ||
                session.lootEntries.any(
                  (item) =>
                      item.name.toLowerCase().contains(query) ||
                      item.description.toLowerCase().contains(query),
                ) ||
                session.npcsMet
                    .any((item) => item.toLowerCase().contains(query)) ||
                session.locationsVisited
                    .any((item) => item.toLowerCase().contains(query));
          }).toList()
            ..sort(
              (a, b) => _newestFirst
                  ? b.date.compareTo(a.date)
                  : a.date.compareTo(b.date),
            );

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyState(
                      icon: Icons.event_note_outlined,
                      title: 'No session notes',
                      message: 'Add a recap after your next game night.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showQuickRecap(context),
                      icon: const Icon(Icons.bolt_outlined),
                      label: const Text('Quick recap'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _search,
                            label: 'Search sessions',
                            prefixIcon: Icons.search,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Sort sessions',
                          onPressed: _showSortSheet,
                          icon: const Icon(Icons.filter_list),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SessionToolbar(
                      onQuickRecap: () => _showQuickRecap(context),
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const SizedBox(
                        height: 300,
                        child: EmptyState(
                          icon: Icons.search_off,
                          title: 'No matching sessions',
                          message: 'Try another search term.',
                        ),
                      ),
                  ],
                );
              }

              final session = filtered[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SessionCard(
                  session: session,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SessionDetailScreen(
                        campaignId: widget.campaignId,
                        sessionId: session.id,
                      ),
                    ),
                  ),
                  onDelete: () => _delete(context, session),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showForm(BuildContext context, {SessionNote? existing}) async {
    final draft = await showModalBottomSheet<SessionFormDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SessionFormSheet(
        campaignId: widget.campaignId,
        existing: existing,
      ),
    );
    if (draft == null) {
      return;
    }
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await ref.read(sessionsControllerProvider(widget.campaignId).notifier).save(
            existing: existing,
            title: draft.title,
            date: draft.date,
            summary: draft.summary,
            importantEvents: draft.importantEvents,
            loot: draft.loot,
            nextSessionReminderNote: draft.nextSessionReminderNote,
            npcsMet: draft.npcsMet,
            locationsVisited: draft.locationsVisited,
          );
      ref.invalidate(campaignSummaryProvider(widget.campaignId));
      if (context.mounted) {
        showAppSnack(
          context,
          existing == null ? 'Session added' : 'Session saved',
        );
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _delete(BuildContext context, SessionNote session) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete session?',
      message: 'This recap will be removed from local storage.',
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref
          .read(sessionsControllerProvider(widget.campaignId).notifier)
          .delete(session.id);
      ref.invalidate(campaignSummaryProvider(widget.campaignId));
      if (context.mounted) {
        showAppSnack(context, 'Session deleted');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _showQuickRecap(BuildContext context) async {
    try {
      final draft = await showDialog<QuickRecapDraft>(
        context: context,
        builder: (context) => const QuickRecapDialog(),
      );

      if (draft == null) {
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await ref.read(sessionsControllerProvider(widget.campaignId).notifier).save(
            title: draft.title,
            date: DateTime.now(),
            summary: draft.summary,
            importantEvents: '',
            loot: '',
            nextSessionReminderNote: '',
            npcsMet: const [],
            locationsVisited: const [],
          );
      ref.invalidate(campaignSummaryProvider(widget.campaignId));
      if (context.mounted) {
        showAppSnack(context, 'Quick recap saved');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _showSortSheet() async {
    var next = _newestFirst;
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort sessions', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ChoiceChip(
                  label: const Text('Newest first'),
                  selected: next,
                  onSelected: (_) => setSheetState(() => next = true),
                ),
                const SizedBox(height: 8),
                ChoiceChip(
                  label: const Text('Oldest first'),
                  selected: !next,
                  onSelected: (_) => setSheetState(() => next = false),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(next),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _newestFirst = result);
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final SessionNote session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.primary.withValues(alpha: 0.68),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          DateFormatters.shortDate.format(session.date),
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        trailing: PopupMenuButton<String>(
          iconColor: colors.primary,
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: colors.primary),
                  const SizedBox(width: 10),
                  const Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionToolbar extends StatelessWidget {
  const _SessionToolbar({
    required this.onQuickRecap,
  });

  final VoidCallback onQuickRecap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final quick = SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: onQuickRecap,
            icon: const Icon(Icons.bolt_outlined),
            label: const Text('Quick recap'),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            constraints.maxWidth < 420
                ? quick
                : Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(width: 210, child: quick),
                  ),
          ],
        );
      },
    );
  }
}
