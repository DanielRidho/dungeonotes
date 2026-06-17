import 'package:flutter/material.dart';

import '../../core/utils/local_image_storage.dart';

class CharacterProfilePhotoStorage {
  const CharacterProfilePhotoStorage._();

  static Future<String?> pickCropAndSave(
    BuildContext context,
    String characterId,
  ) {
    return LocalImageStorage.pickCropAndSave(
      context: context,
      filePrefix: characterId,
      folderName: 'profile_images',
      aspectRatio: 1,
      dialogTitle: 'Adjust Profile Photo',
      instruction: 'Choose the square area for this character.',
      outputWidth: 512,
    );
  }
}
