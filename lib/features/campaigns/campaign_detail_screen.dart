import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/error_view.dart';
import '../../data/models/app_models.dart';
import '../characters/characters_tab.dart';
import '../npc_locations/world_notes_tab.dart';
import '../quests/quests_tab.dart';
import '../sessions/sessions_tab.dart';
import 'campaign_overview_tab.dart';
import 'campaigns_controller.dart';

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignsControllerProvider);

    return campaigns.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: ErrorView(
          title: 'Could not open campaign',
          message: error.toString(),
          onRetry: () => ref.read(campaignsControllerProvider.notifier).load(),
        ),
      ),
      data: (items) {
        final matches = items.where((item) => item.id == campaignId);
        final campaign = matches.isEmpty ? null : matches.first;
        if (campaign == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorView(
              title: 'Campaign not found',
              message: 'It may have been deleted.',
            ),
          );
        }
        return _CampaignDetailBody(campaign: campaign);
      },
    );
  }
}

class _CampaignDetailBody extends StatefulWidget {
  const _CampaignDetailBody({required this.campaign});

  final Campaign campaign;

  @override
  State<_CampaignDetailBody> createState() => _CampaignDetailBodyState();
}

class _CampaignDetailBodyState extends State<_CampaignDetailBody> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    return Scaffold(
      appBar: AppBar(
        title: Text(campaign.title),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CampaignOverviewTab(campaign: campaign),
          SessionsTab(campaignId: campaign.id),
          CharactersTab(campaignId: campaign.id),
          QuestsTab(campaignId: campaign.id),
          _WorldCombinedTab(campaignId: campaign.id),
        ],
      ),
      bottomNavigationBar: _CampaignBottomNav(
        selectedIndex: _selectedIndex,
        onSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _WorldCombinedTab extends StatelessWidget {
  const _WorldCombinedTab({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Material(
            child: TabBar(
              tabs: [
                Tab(text: 'NPCs'),
                Tab(text: 'Locations'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                WorldNotesTab(campaignId: campaignId, type: WorldNoteType.npc),
                WorldNotesTab(
                  campaignId: campaignId,
                  type: WorldNoteType.location,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignBottomNav extends StatelessWidget {
  const _CampaignBottomNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _CampaignNavData(Icons.dashboard_outlined, Icons.dashboard, 'Overview'),
    _CampaignNavData(Icons.event_note_outlined, Icons.event_note, 'Sessions'),
    _CampaignNavData(Icons.groups_outlined, Icons.groups, 'Characters'),
    _CampaignNavData(Icons.flag_outlined, Icons.flag, 'Quest'),
    _CampaignNavData(Icons.public_outlined, Icons.public, 'World'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 12,
        color: colors.surface,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: _CampaignNavButton(
                    data: _items[index],
                    selected: index == selectedIndex,
                    prominent: index == 2,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignNavData {
  const _CampaignNavData(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _CampaignNavButton extends StatelessWidget {
  const _CampaignNavButton({
    required this.data,
    required this.selected,
    required this.prominent,
    required this.onTap,
  });

  final _CampaignNavData data;
  final bool selected;
  final bool prominent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    final icon = Icon(selected ? data.selectedIcon : data.icon);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );

    if (prominent) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 58 : 54,
              height: selected ? 58 : 54,
              decoration: BoxDecoration(
                color: selected ? colors.primary : colors.surfaceContainerHigh,
                shape: BoxShape.circle,
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
                child: icon,
              ),
            ),
            const SizedBox(height: 2),
            Text(data.label, maxLines: 1, style: labelStyle),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(data: IconThemeData(color: foreground), child: icon),
          const SizedBox(height: 4),
          Text(data.label, maxLines: 1, style: labelStyle),
        ],
      ),
    );
  }
}
