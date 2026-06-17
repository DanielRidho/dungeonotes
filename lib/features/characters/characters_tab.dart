import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_generator.dart';
import '../../core/utils/snackbars.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/data_portability_repository.dart';
import '../../data/repositories/local_repositories.dart';
import '../dice_roller/dice_launcher.dart';
import 'character_cards.dart';
import 'character_detail_screen.dart';
import 'character_form_screen.dart';
import 'characters_controller.dart';

export 'character_cards.dart';
export 'character_form_screen.dart';

class CharactersTab extends ConsumerWidget {
  const CharactersTab({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characters = ref.watch(charactersControllerProvider(campaignId));

    return Scaffold(
      floatingActionButton: DicePageActionGroup(
        primaryAction: FloatingActionButton(
          heroTag: 'character-actions',
          tooltip: 'Add character',
          onPressed: () => _showCharacterActions(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
      body: characters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          title: 'Could not load character sheets',
          message: error.toString(),
          onRetry: () =>
              ref.read(charactersControllerProvider(campaignId).notifier).load(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _CharacterTabHeader();
          }
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              CharacterSummarySliverGrid(
                characters: items,
                onTap: (character) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CharacterDetailScreen(
                      characterId: character.id,
                      campaignId: campaignId,
                    ),
                  ),
                ),
                onEdit: (character) => showCharacterForm(
                  context,
                  ref,
                  campaignId: campaignId,
                  existing: character,
                ),
                onExport: (character) => _exportToCharacterSheets(
                  context,
                  ref,
                  character,
                ),
                onExportJson: (character) =>
                    _exportCharacterJson(context, ref, character),
                onUnlink: (character) => _unlink(context, ref, character),
                onDelete: (character) =>
                    deleteCharacterSheet(context, ref, character),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _unlink(
    BuildContext context,
    WidgetRef ref,
    CharacterNote character,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Remove from campaign?',
      message:
          'This removes only the campaign copy. Your character library stays separate.',
      confirmLabel: 'Remove',
    );
    if (!confirmed) {
      return;
    }

    try {
      await ref
          .read(charactersControllerProvider(campaignId).notifier)
          .unlink(character);
      ref.invalidate(allCharactersControllerProvider);
      if (context.mounted) {
        showAppSnack(context, 'Character removed from campaign');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _exportToCharacterSheets(
    BuildContext context,
    WidgetRef ref,
    CharacterNote character,
  ) async {
    try {
      final runtime = await ref
          .read(campaignCharacterStatesControllerProvider(campaignId).notifier)
          .ensure(character);
      final now = DateTime.now();
      final copy = character.copyWith(
        id: IdGenerator.create(),
        campaignIds: const [],
        name: '${character.name} (Campaign Copy)',
        currentHp: runtime.currentHp,
        temporaryHp: runtime.temporaryHp,
        armorClass: runtime.armorClass <= 0
            ? character.armorClass
            : runtime.armorClass,
        deathSaveSuccesses: runtime.deathSaveSuccesses,
        deathSaveFailures: runtime.deathSaveFailures,
        equippedArmorId: runtime.activeArmorId,
        equippedWeaponId: runtime.activeWeaponId,
        equippedShieldId: runtime.activeShieldId,
        shieldEquipped: runtime.activeShieldId.isNotEmpty,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(characterRepositoryProvider).save(copy);
      ref.invalidate(allCharactersControllerProvider);
      if (context.mounted) {
        showAppSnack(context, 'Exported to character sheets');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _exportCharacterJson(
    BuildContext context,
    WidgetRef ref,
    CharacterNote character,
  ) async {
    try {
      final exported = await ref
          .read(dataPortabilityRepositoryProvider)
          .exportCharacter(character);
      if (context.mounted && exported) {
        showAppSnack(context, 'Character JSON exported');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _importCharacterJson(BuildContext context, WidgetRef ref) async {
    try {
      final imported = await ref
          .read(dataPortabilityRepositoryProvider)
          .importCharacter(campaignId: campaignId);
      if (!imported) {
        return;
      }
      ref.invalidate(charactersControllerProvider(campaignId));
      ref.invalidate(allCharactersControllerProvider);
      if (context.mounted) {
        showAppSnack(context, 'Character JSON imported');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  void _showCharacterActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New Sheet'),
              subtitle: const Text('Create a fresh character for this campaign.'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showCharacterForm(context, ref, campaignId: campaignId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_outlined),
              title: const Text('Link Existing'),
              subtitle: const Text('Use a sheet from your character library.'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showLinkCharacterDialog(context, ref, campaignId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import JSON'),
              subtitle: const Text('Import a character into this campaign.'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _importCharacterJson(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterTabHeader extends StatelessWidget {
  const _CharacterTabHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 360,
          child: EmptyState(
            icon: Icons.assignment_ind_outlined,
            title: 'No sheets in this campaign',
            message:
                'Create a new sheet or link one from your character library.',
          ),
        ),
      ],
    );
  }
}

Future<void> showLinkCharacterDialog(
  BuildContext context,
  WidgetRef ref,
  String campaignId,
) async {
  ref.invalidate(allCharactersControllerProvider);
  final controller = ref.read(charactersControllerProvider(campaignId).notifier);
  final allCharacters = await ref.read(characterRepositoryProvider).getAll();
  final available = allCharacters
      .where((character) => character.campaignIds.isEmpty)
      .toList();

  if (!context.mounted) {
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Link Character Sheet'),
      content: SizedBox(
        width: double.maxFinite,
        child: available.isEmpty
            ? const Text('No unlinked character sheets are available.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final character = available[index];
                  return ListTile(
                    leading: const Icon(Icons.assignment_ind_outlined),
                    title: Text(character.name),
                    subtitle: Text(
                      [
                        if (character.className.isNotEmpty)
                          character.className,
                        'Level ${character.level}',
                      ].join(' / '),
                    ),
                    onTap: () async {
                      try {
                        await controller.link(character);
                        ref.invalidate(allCharactersControllerProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          showAppSnack(context, 'Character linked');
                        }
                      } catch (error) {
                        if (context.mounted) {
                          showAppSnack(
                            context,
                            error.toString(),
                            isError: true,
                          );
                        }
                      }
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> deleteCharacterSheet(
  BuildContext context,
  WidgetRef ref,
  CharacterNote character,
) async {
  final confirmed = await ConfirmDialog.show(
    context,
    title: 'Delete character sheet?',
    message:
        'This deletes the sheet from your library and all linked campaigns.',
  );
  if (!confirmed) {
    return;
  }

  try {
    await ref.read(characterRepositoryProvider).delete(character.id);
    for (final campaignId in character.campaignIds) {
      ref.invalidate(charactersControllerProvider(campaignId));
    }
    ref.invalidate(allCharactersControllerProvider);
    if (context.mounted) {
      showAppSnack(context, 'Character sheet deleted');
    }
  } catch (error) {
    if (context.mounted) {
      showAppSnack(context, error.toString(), isError: true);
    }
  }
}
