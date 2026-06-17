import '../../core/constants/app_constants.dart';
import 'app_enums.dart';
import 'character_structures.dart';

export 'app_enums.dart';
export 'character_structures.dart';

part 'campaign_models.dart';
part 'character_note_model.dart';
part 'world_models.dart';

DateTime _dateFromJson(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

int _intFromJson(Object? value, [int fallback = 0]) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

bool _boolFromJson(Object? value) => value == true;
List<String> _stringListFromJson(Object? value) {
  return value is List ? value.map((item) => item.toString()).toList() : const [];
}

bool _entryLooksLikeShield(CharacterListEntry entry) =>
    '${entry.name} ${entry.description}'.toLowerCase().contains('shield');

Map<String, String> _stringMapFromJson(Object? value) {
  return value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value.toString()))
      : const {};
}
