import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/utils/snackbars.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/data_portability_repository.dart';
import 'character_detail_screen.dart';
import 'characters_controller.dart';
import 'characters_tab.dart';

class CharacterSheetsScreen extends ConsumerStatefulWidget {
  const CharacterSheetsScreen({super.key});

  @override
  ConsumerState<CharacterSheetsScreen> createState() =>
      _CharacterSheetsScreenState();
}

class _CharacterSheetsScreenState extends ConsumerState<CharacterSheetsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characters = ref.watch(allCharactersControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Character Sheets')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add sheet',
        onPressed: () => _showSheetActions(context),
        child: const Icon(Icons.add),
      ),
      body: characters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          title: 'Could not load character sheets',
          message: error.toString(),
          onRetry: () =>
              ref.read(allCharactersControllerProvider.notifier).load(),
        ),
        data: (items) {
          final query = _search.text.trim().toLowerCase();
          final filtered = items.where((character) {
            return character.name.toLowerCase().contains(query) ||
                character.ancestryOrSpecies.toLowerCase().contains(query) ||
                character.className.toLowerCase().contains(query);
          }).toList();

          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_ind_outlined,
              title: 'No character sheets yet',
              message:
                  'Create sheets here, then link them to one or more campaigns.',
            );
          }

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Search sheets',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No matching sheets',
                    message: 'Try another name, species, or class.',
                  ),
                )
              else
                CharacterSummarySliverGrid(
                  characters: filtered,
                  onTap: (character) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CharacterDetailScreen(
                        characterId: character.id,
                      ),
                    ),
                  ),
                  onEdit: (character) => showCharacterForm(
                    context,
                    ref,
                    existing: character,
                  ),
                  onExportJson: (character) =>
                      _exportCharacter(context, character),
                  onDelete: (character) =>
                      deleteCharacterSheet(context, ref, character),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSheetActions(BuildContext context) {
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
              onTap: () {
                Navigator.of(sheetContext).pop();
                showCharacterForm(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import JSON'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _importCharacter(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCharacter(
    BuildContext context,
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

  Future<void> _importCharacter(BuildContext context) async {
    try {
      final imported =
          await ref.read(dataPortabilityRepositoryProvider).importCharacter();
      if (!imported) {
        return;
      }
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
}
