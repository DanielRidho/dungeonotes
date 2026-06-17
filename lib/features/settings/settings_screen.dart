import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/snackbars.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';
import '../campaigns/campaigns_controller.dart';
import '../characters/characters_controller.dart';
import '../dice_roller/dice_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeChoice = ref.watch(themeChoiceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('More'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Settings'),
              Tab(text: 'About'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        AppDropdown<ThemeChoice>(
                          label: 'Theme',
                          value: themeChoice,
                          items: ThemeChoice.values,
                          labelBuilder: (value) => value.label,
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(themeChoiceProvider.notifier)
                                  .setTheme(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined),
                    title: const Text('Clear all local data'),
                    subtitle:
                        const Text('Remove campaigns, notes, and dice history.'),
                    onTap: () => _clearData(context, ref),
                  ),
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _AboutHeader(),
                const SizedBox(height: 12),
                const _AboutCard(
                  title: 'About Dungeonotes',
                  body:
                      'Dungeonotes is an offline-first companion app for D&D and tabletop roleplaying campaigns. It helps players and Dungeon Masters organize campaigns, sessions, quests, characters, NPCs, locations, inventory, spells, and dice rolls without requiring an account, backend, or internet connection.',
                ),
                const SizedBox(height: 12),
                const _AboutCard(
                  title: 'Why It Exists',
                  body:
                      'This app was built for groups who want a fast, lightweight way to keep campaign notes organized during play. The goal is to stay simple, readable, and useful at the table.',
                ),
                const SizedBox(height: 12),
                const _AboutCard(
                  title: 'About The Creator',
                  body:
                      'Created by Daniel Ridho Abadi, an independent developer who enjoys building practical tools for tabletop players and storytellers.',
                ),
                const SizedBox(height: 12),
                const _PrinciplesCard(),
                const SizedBox(height: 12),
                const _LegalCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Clear all local data?',
      message:
          'This deletes campaigns, notes, and dice history stored on this device.',
      confirmLabel: 'Clear',
    );
    if (!confirmed) {
      return;
    }

    try {
      await ref.read(settingsRepositoryProvider).clearAllLocalData();
      ref.invalidate(campaignsControllerProvider);
      ref.invalidate(allCharactersControllerProvider);
      ref.invalidate(diceControllerProvider);
      if (context.mounted) {
        showAppSnack(context, 'Local data cleared');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLogo(height: 34, color: colors.primary),
            const SizedBox(height: 10),
            Text(
              'Version 0.1.0',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              'Offline D&D campaign notes for players and Dungeon Masters.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}

class _PrinciplesCard extends StatelessWidget {
  const _PrinciplesCard();

  @override
  Widget build(BuildContext context) {
    const principles = [
      'Offline-first',
      'No login required',
      'No backend or cloud dependency',
      'User-created notes and data',
      'Lightweight and table-friendly',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Core Principles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final item in principles)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppConstants.legalNote,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
