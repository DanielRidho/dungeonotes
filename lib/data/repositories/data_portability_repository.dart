import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_exception.dart';
import '../local/local_database.dart';
import '../models/app_models.dart';

final dataPortabilityRepositoryProvider =
    Provider<DataPortabilityRepository>((ref) {
  return DataPortabilityRepository(ref.read(localDatabaseProvider));
});

class DataPortabilityRepository {
  const DataPortabilityRepository(this._database);

  final LocalDatabase _database;

  Future<bool> exportCampaign(Campaign campaign) async {
    final campaignId = campaign.id;
    final characters = _database.characters.values
        .map((value) => CharacterNote.fromJson(_asMap(value)))
        .where((character) => character.campaignIds.contains(campaignId))
        .toList();
    final worldNotes = _database.worldNotes.values
        .map((value) => WorldNote.fromJson(_asMap(value)))
        .where((note) => note.campaignId == campaignId)
        .toList();
    final characterImages = <String, Map<String, dynamic>>{};
    for (final character in characters) {
      final image = await _imagePayload(character.profileImagePath);
      if (image != null) {
        characterImages[character.id] = image;
      }
    }
    final worldImages = <String, Map<String, dynamic>>{};
    for (final note in worldNotes) {
      final image = await _imagePayload(note.imagePath);
      if (image != null) {
        worldImages[note.id] = image;
      }
    }

    final payload = {
      'type': 'dungeonnotes.campaign',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'campaign': campaign.toJson(),
      'sessions': _recordsByCampaign(_database.sessions, campaignId),
      'quests': _recordsByCampaign(_database.quests, campaignId),
      'worldNotes': worldNotes.map((note) => note.toJson()).toList(),
      'characters': characters.map((character) => character.toJson()).toList(),
      'campaignCharacterStates':
          _recordsByCampaign(_database.campaignCharacterStates, campaignId),
      'images': {
        'campaign': await _imagePayload(campaign.imagePath),
        'characters': characterImages,
        'worldNotes': worldImages,
      },
    };

    return _saveJson(
      fileName: '${_safeName(campaign.title)}_campaign.json',
      payload: payload,
    );
  }

  Future<bool> exportCharacter(CharacterNote character) async {
    final portableCharacter = character.copyWith(campaignIds: const []);
    final payload = {
      'type': 'dungeonnotes.character',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'character': portableCharacter.toJson(),
      'images': {
        'profile': await _imagePayload(character.profileImagePath),
      },
    };

    return _saveJson(
      fileName: '${_safeName(character.name)}_character.json',
      payload: payload,
    );
  }

  Future<bool> importCampaign() async {
    final payload = await _pickJson();
    if (payload == null) {
      return false;
    }
    if (payload['type'] != 'dungeonnotes.campaign') {
      throw const AppException('This is not a Dungeonotes campaign JSON file');
    }

    final images = _mapOrEmpty(payload['images']);
    final campaignJson = _mapOrEmpty(payload['campaign']);
    if (campaignJson.isEmpty) {
      throw const AppException('Campaign JSON is incomplete');
    }
    final campaign = Campaign.fromJson(campaignJson);
    final campaignImage = await _restoreImage(
      images['campaign'],
      folderName: 'campaign_covers',
      filePrefix: campaign.id,
    );
    final campaignToSave = campaignImage == null
        ? campaign
        : campaign.copyWith(imagePath: campaignImage);
    await _database.campaigns.put(campaignToSave.id, campaignToSave.toJson());

    for (final item in _mapList(payload['sessions'])) {
      final session = SessionNote.fromJson(item);
      await _database.sessions.put(session.id, session.toJson());
    }
    for (final item in _mapList(payload['quests'])) {
      final quest = Quest.fromJson(item);
      await _database.quests.put(quest.id, quest.toJson());
    }

    final characterImages = _mapOrEmpty(images['characters']);
    for (final item in _mapList(payload['characters'])) {
      var character = CharacterNote.fromJson(item);
      final imagePath = await _restoreImage(
        characterImages[character.id],
        folderName: 'profile_images',
        filePrefix: character.id,
      );
      if (imagePath != null) {
        character = character.copyWith(profileImagePath: imagePath);
      }
      await _database.characters.put(character.id, character.toJson());
    }

    final worldImages = _mapOrEmpty(images['worldNotes']);
    for (final item in _mapList(payload['worldNotes'])) {
      var note = WorldNote.fromJson(item);
      final imagePath = await _restoreImage(
        worldImages[note.id],
        folderName: 'world_note_images',
        filePrefix: note.id,
      );
      if (imagePath != null) {
        note = note.copyWith(imagePath: imagePath);
      }
      await _database.worldNotes.put(note.id, note.toJson());
    }

    for (final item in _mapList(payload['campaignCharacterStates'])) {
      final state = CampaignCharacterState.fromJson(item);
      await _database.campaignCharacterStates.put(state.id, state.toJson());
    }
    return true;
  }

  Future<bool> importCharacter({String? campaignId}) async {
    final payload = await _pickJson();
    if (payload == null) {
      return false;
    }
    if (payload['type'] != 'dungeonnotes.character') {
      throw const AppException('This is not a Dungeonotes character JSON file');
    }

    final characterJson = _mapOrEmpty(payload['character']);
    if (characterJson.isEmpty) {
      throw const AppException('Character JSON is incomplete');
    }
    var character = CharacterNote.fromJson(characterJson).copyWith(
      campaignIds: campaignId == null ? const [] : [campaignId],
    );

    final images = _mapOrEmpty(payload['images']);
    final imagePath = await _restoreImage(
      images['profile'],
      folderName: 'profile_images',
      filePrefix: character.id,
    );
    if (imagePath != null) {
      character = character.copyWith(profileImagePath: imagePath);
    }
    await _database.characters.put(character.id, character.toJson());
    return true;
  }

  List<Map<String, dynamic>> _recordsByCampaign(
    dynamic box,
    String campaignId,
  ) {
    final records = <Map<String, dynamic>>[];
    for (final value in box.values) {
      final map = _asMap(value);
      if (map['campaignId'] == campaignId) {
        records.add(map);
      }
    }
    return records;
  }

  Future<bool> _saveJson({
    required String fileName,
    required Map<String, dynamic> payload,
  }) async {
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Dungeonotes JSON',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
    if (path == null) {
      return false;
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return true;
  }

  Future<Map<String, dynamic>?> _pickJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.single;
    final bytes = file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) {
      throw const AppException('Could not read JSON file');
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const AppException('JSON root must be an object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<Map<String, dynamic>?> _imagePayload(String path) async {
    if (path.trim().isEmpty) {
      return null;
    }
    final file = File(path);
    if (!await file.exists()) {
      return null;
    }
    final name = path.split(RegExp(r'[\\/]')).last;
    return {
      'fileName': name,
      'base64': base64Encode(await file.readAsBytes()),
    };
  }

  Future<String?> _restoreImage(
    Object? value, {
    required String folderName,
    required String filePrefix,
  }) async {
    final image = _mapOrEmpty(value);
    final encoded = image['base64']?.toString() ?? '';
    if (encoded.isEmpty) {
      return null;
    }
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory('${directory.path}${Platform.pathSeparator}$folderName');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final fileName = image['fileName']?.toString() ?? '$filePrefix.jpg';
    final extension = fileName.contains('.') ? fileName.split('.').last : 'jpg';
    final file = File(
      '${folder.path}${Platform.pathSeparator}${_safeName(filePrefix)}_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await file.writeAsBytes(base64Decode(encoded), flush: true);
    return file.path;
  }

  String _safeName(String value) {
    final cleaned = value.trim().isEmpty ? 'dungeonnotes' : value.trim();
    return cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_').toLowerCase();
  }
}

Map<String, dynamic> _asMap(Object? value) => Map<String, dynamic>.from(value as Map);

Map<String, dynamic> _mapOrEmpty(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const {};
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}
