import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_generator.dart';
import '../../core/utils/snackbars.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';
import '../dice_roller/dice_launcher.dart';
import 'characters_controller.dart';
import 'characters_tab.dart';
import 'character_sheet_tabs.dart';

class CharacterDetailScreen extends ConsumerStatefulWidget {
  const CharacterDetailScreen({
    required this.characterId,
    super.key,
    this.campaignId,
  });

  final String characterId;
  final String? campaignId;

  @override
  ConsumerState<CharacterDetailScreen> createState() =>
      _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends ConsumerState<CharacterDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.campaignId == null
        ? ref.watch(allCharactersControllerProvider)
        : ref.watch(charactersControllerProvider(widget.campaignId!));

    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          title: 'Could not load character sheet',
          message: error.toString(),
          onRetry: () {
            if (widget.campaignId == null) {
              ref.read(allCharactersControllerProvider.notifier).load();
            } else {
              ref
                  .read(charactersControllerProvider(widget.campaignId!).notifier)
                  .load();
            }
          },
        ),
      ),
      data: (items) {
        final character = _find(items);
        if (character == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorView(
              title: 'Character sheet not found',
              message: 'It may have been deleted or removed from this campaign.',
            ),
          );
        }
        return DiceDraggableLauncher(
          child: Scaffold(
            appBar: AppBar(
              title: Text(character.name),
              actions: [
                IconButton(
                  tooltip: 'Edit sheet',
                  onPressed: () => showCharacterForm(
                    context,
                    ref,
                    campaignId: widget.campaignId,
                    existing: character,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'export') {
                      _exportCopy(context, ref, character);
                    }
                    if (value == 'unlink') {
                      _unlink(context, ref, character);
                    }
                    if (value == 'delete') {
                      deleteCharacterSheet(context, ref, character);
                    }
                  },
                  itemBuilder: (context) => [
                    if (widget.campaignId != null)
                      const PopupMenuItem(
                        value: 'export',
                        child: Text('Export copy to library'),
                      ),
                    if (widget.campaignId != null)
                      const PopupMenuItem(
                        value: 'unlink',
                        child: Text('Remove from campaign'),
                      ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Basics'),
                  Tab(text: 'Combat'),
                  Tab(text: 'Spells'),
                  Tab(text: 'Abilities'),
                  Tab(text: 'Inventory'),
                ],
              ),
            ),
            body: CharacterSheetTabs(
              character: character,
              campaignId: widget.campaignId,
              controller: _tabController,
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportCopy(
    BuildContext context,
    WidgetRef ref,
    CharacterNote character,
  ) async {
    final now = DateTime.now();
    var copy = character.copyWith(
      id: IdGenerator.create(),
      campaignIds: const [],
      name: '${character.name} (Campaign Copy)',
      createdAt: now,
      updatedAt: now,
    );
    if (widget.campaignId != null) {
      final states = ref
          .read(campaignCharacterStatesControllerProvider(widget.campaignId!))
          .valueOrNull;
      CampaignCharacterState? runtime;
      for (final state in states ?? const <CampaignCharacterState>[]) {
        if (state.characterId == character.id) {
          runtime = state;
          break;
        }
      }
      if (runtime != null) {
        copy = copy.copyWith(
          currentHp: runtime.currentHp,
          temporaryHp: runtime.temporaryHp,
          armorClass: runtime.armorClass <= 0
              ? character.armorClass
              : runtime.armorClass,
          deathSaveSuccesses: runtime.deathSaveSuccesses,
          deathSaveFailures: runtime.deathSaveFailures,
          armorName: runtime.activeArmorName.isEmpty
              ? character.armorName
              : runtime.activeArmorName,
          equippedArmorId: runtime.activeArmorId,
          equippedWeaponId: runtime.activeWeaponId,
          equippedShieldId: runtime.activeShieldId,
          shieldEquipped: runtime.shieldEquipped,
        );
      }
    }
    try {
      await ref.read(characterRepositoryProvider).save(copy);
      ref.invalidate(allCharactersControllerProvider);
      if (context.mounted) {
        showAppSnack(context, 'Character exported to library');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  CharacterNote? _find(List<CharacterNote> items) {
    for (final item in items) {
      if (item.id == widget.characterId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _unlink(
    BuildContext context,
    WidgetRef ref,
    CharacterNote character,
  ) async {
    if (widget.campaignId == null) {
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Remove from campaign?',
      message:
          'The character sheet stays in your library and can still be used elsewhere.',
      confirmLabel: 'Remove',
    );
    if (!confirmed) {
      return;
    }
    await ref
        .read(charactersControllerProvider(widget.campaignId!).notifier)
        .unlink(character);
    ref.invalidate(allCharactersControllerProvider);
    if (context.mounted) {
      Navigator.of(context).maybePop();
    }
  }
}
