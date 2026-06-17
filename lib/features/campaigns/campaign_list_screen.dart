import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/local_image_storage.dart';
import '../../core/utils/snackbars.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/data_portability_repository.dart';
import '../characters/characters_controller.dart';
import 'campaigns_controller.dart';

class CampaignListScreen extends ConsumerStatefulWidget {
  const CampaignListScreen({super.key});

  @override
  ConsumerState<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends ConsumerState<CampaignListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 24),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add campaign',
        onPressed: () => _showCampaignActions(context),
        child: const Icon(Icons.add),
      ),
      body: campaigns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          title: 'Could not load campaigns',
          message: error.toString(),
          onRetry: () => ref.read(campaignsControllerProvider.notifier).load(),
        ),
        data: (items) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = items.where((campaign) {
            return campaign.title.toLowerCase().contains(query) ||
                campaign.partyName.toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(campaignsControllerProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                AppTextField(
                  controller: _searchController,
                  label: 'Search campaign',
                  prefixIcon: Icons.search,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const SizedBox(
                    height: 420,
                    child: EmptyState(
                      icon: Icons.map_outlined,
                      title: 'No campaigns yet',
                      message: 'Create a campaign to start keeping notes.',
                    ),
                  )
                else if (filtered.isEmpty)
                  const SizedBox(
                    height: 420,
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'No matches',
                      message: 'Try a different title, party, or keyword.',
                    ),
                  )
                else
                  for (final campaign in filtered) ...[
                    _CampaignCard(
                      campaign: campaign,
                      onTap: () => context.push('/campaigns/${campaign.id}'),
                      onEdit: () =>
                          _showCampaignForm(context, existing: campaign),
                      onExport: () => _exportCampaign(context, campaign),
                      onDelete: () => _deleteCampaign(context, campaign),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCampaignForm(
    BuildContext context, {
    Campaign? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CampaignFormSheet(existing: existing),
    );
    if (!context.mounted || saved != true) {
      return;
    }
    showAppSnack(context, existing == null ? 'Campaign added' : 'Campaign saved');
  }

  void _showCampaignActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add campaign'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showCampaignForm(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import JSON'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _importCampaign(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCampaign(BuildContext context, Campaign campaign) async {
    try {
      final exported = await ref
          .read(dataPortabilityRepositoryProvider)
          .exportCampaign(campaign);
      if (context.mounted && exported) {
        showAppSnack(context, 'Campaign JSON exported');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _importCampaign(BuildContext context) async {
    try {
      final imported =
          await ref.read(dataPortabilityRepositoryProvider).importCampaign();
      if (!imported) {
        return;
      }
      ref.invalidate(campaignsControllerProvider);
      ref.invalidate(allCharactersControllerProvider);
      if (context.mounted) {
        showAppSnack(context, 'Campaign JSON imported');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _deleteCampaign(BuildContext context, Campaign campaign) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete campaign?',
      message:
          'This removes the campaign and all linked sessions, quests, characters, NPCs, and locations.',
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(campaignsControllerProvider.notifier).delete(campaign.id);
      if (context.mounted) {
        showAppSnack(context, 'Campaign deleted');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}

class _CampaignCard extends ConsumerWidget {
  const _CampaignCard({
    required this.campaign,
    required this.onTap,
    required this.onEdit,
    required this.onExport,
    required this.onDelete,
  });

  final Campaign campaign;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final summary = ref.watch(campaignSummaryProvider(campaign.id));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CampaignCover(campaign: campaign),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: Theme.of(context).textTheme.titleMedium,
                            children: [
                              TextSpan(
                                text: campaign.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (campaign.partyName.trim().isNotEmpty)
                                TextSpan(
                                  text: ' - ${campaign.partyName}',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          }
                          if (value == 'export') {
                            onExport();
                          }
                          if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'export',
                            child: Text('Export JSON'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  summary.when(
                    loading: () => Text(
                      'Loading summary...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    error: (_, __) => Text(
                      'Summary unavailable',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    data: (value) => Text(
                      '${value.totalSessions} ${value.totalSessions == 1 ? 'Session' : 'Sessions'} - Updated ${DateFormatters.shortDate.format(campaign.updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignCover extends StatelessWidget {
  const _CampaignCover({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final path = campaign.imagePath.trim();
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(campaign.colorTag).withValues(alpha: 0.22),
        ),
        child: path.isEmpty
            ? _CampaignCoverPlaceholder(color: Color(campaign.colorTag))
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _CampaignCoverPlaceholder(color: Color(campaign.colorTag)),
              ),
      ),
    );
  }
}

class _CampaignCoverPlaceholder extends StatelessWidget {
  const _CampaignCoverPlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.26),
            colors.surfaceContainerHighest.withValues(alpha: 0.72),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 46,
          color: colors.onSurfaceVariant.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _CampaignCoverPicker extends StatelessWidget {
  const _CampaignCoverPicker({
    required this.campaignId,
    required this.imagePath,
    required this.color,
    required this.onChanged,
  });

  final String campaignId;
  final String imagePath;
  final int color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.trim().isNotEmpty;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _CampaignCover(
                campaign: Campaign(
                  id: campaignId,
                  title: '',
                  systemName: AppConstants.defaultSystemName,
                  description: '',
                  partyName: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  colorTag: color,
                  imagePath: imagePath,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _pick(context),
                  icon: Icon(
                    hasImage
                        ? Icons.edit_outlined
                        : Icons.add_photo_alternate_outlined,
                  ),
                  label: Text(hasImage ? 'Change Cover' : 'Add Cover'),
                ),
                if (hasImage)
                  OutlinedButton.icon(
                    onPressed: () => onChanged(''),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    try {
      final path = await LocalImageStorage.pickCropAndSave(
        context: context,
        filePrefix: campaignId,
        folderName: 'campaign_covers',
        aspectRatio: 16 / 9,
        dialogTitle: 'Adjust Campaign Cover',
        instruction: 'Choose the wide cover area for this campaign.',
        outputWidth: 960,
      );
      if (path != null) {
        onChanged(path);
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}

class CampaignFormSheet extends ConsumerStatefulWidget {
  const CampaignFormSheet({super.key, this.existing});

  final Campaign? existing;

  @override
  ConsumerState<CampaignFormSheet> createState() => _CampaignFormSheetState();
}

class _CampaignFormSheetState extends ConsumerState<CampaignFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final String _draftId;
  late final TextEditingController _title;
  late final TextEditingController _party;
  late int _colorTag;
  late String _imagePath;

  static const _defaultColor = 0xFF9C7A2F;

  @override
  void initState() {
    super.initState();
    final campaign = widget.existing;
    _draftId = campaign?.id ?? IdGenerator.create();
    _title = TextEditingController(text: campaign?.title ?? '');
    _party = TextEditingController(text: campaign?.partyName ?? '');
    _colorTag = campaign?.colorTag ?? _defaultColor;
    _imagePath = campaign?.imagePath ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _party.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existing == null ? 'Add Campaign' : 'Edit Campaign',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _CampaignCoverPicker(
                  campaignId: _draftId,
                  imagePath: _imagePath,
                  color: _colorTag,
                  onChanged: (value) => setState(() => _imagePath = value),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _title,
                  label: 'Campaign name',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _party, label: 'Party name'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      await ref.read(campaignsControllerProvider.notifier).save(
            existing: widget.existing,
            title: _title.text,
            partyName: _party.text,
            imagePath: _imagePath,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }
}
