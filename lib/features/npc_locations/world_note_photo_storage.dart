import 'package:flutter/material.dart';

import '../../core/utils/local_image_storage.dart';

class WorldNotePhotoStorage {
  const WorldNotePhotoStorage._();

  static Future<String?> pickCropAndSave(
    BuildContext context,
    String noteId,
  ) {
    return LocalImageStorage.pickCropAndSave(
      context: context,
      filePrefix: noteId,
      folderName: 'world_note_images',
      aspectRatio: 1,
      dialogTitle: 'Adjust Photo',
      instruction: 'Choose the square area for this note.',
      outputWidth: 512,
    );
  }
}
