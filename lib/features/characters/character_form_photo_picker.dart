import 'package:flutter/material.dart';

import '../../core/utils/snackbars.dart';
import 'character_avatar.dart';
import 'character_entry_dialogs.dart';
import 'character_profile_photo_storage.dart';

class CharacterFormPhotoPicker extends StatelessWidget {
  const CharacterFormPhotoPicker({
    required this.characterId,
    required this.imagePath,
    required this.name,
    required this.onChanged,
    super.key,
  });

  final String characterId;
  final String imagePath;
  final TextEditingController name;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = imagePath.trim().isNotEmpty;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CharacterAvatar(
                    imagePath: imagePath,
                    size: 156,
                    borderRadius: 24,
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Photo options',
                    onPressed: () => _showPhotoOptions(context, hasPhoto),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: name,
                builder: (context, value, child) {
                  final text = value.text.trim();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          text.isEmpty ? 'Unnamed Character' : text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit name',
                        onPressed: () => _editName(context),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPhotoOptions(BuildContext context, bool hasPhoto) async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  hasPhoto
                      ? Icons.edit_outlined
                      : Icons.add_photo_alternate_outlined,
                ),
                title: Text(hasPhoto ? 'Change photo' : 'Add photo'),
                onTap: () => Navigator.of(sheetContext).pop(_PhotoAction.pick),
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete photo'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_PhotoAction.delete),
                ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || action == null) {
      return;
    }
    switch (action) {
      case _PhotoAction.pick:
        await _pick(context);
      case _PhotoAction.delete:
        onChanged('');
    }
  }

  Future<void> _editName(BuildContext context) async {
    final value = await showTextValueDialog(
      context,
      title: 'Character name',
      label: 'Name',
      initialValue: name.text,
    );
    if (value != null) {
      name.text = value.trim();
    }
  }

  Future<void> _pick(BuildContext context) async {
    try {
      final path = await CharacterProfilePhotoStorage.pickCropAndSave(
        context,
        characterId,
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

enum _PhotoAction { pick, delete }
