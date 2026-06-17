import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../models/reference_models.dart';

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return ReferenceRepository();
});

final referenceEntriesProvider =
    FutureProvider.family<List<ReferenceEntry>, ReferenceType>((ref, type) {
  return ref.read(referenceRepositoryProvider).load(type);
});

class ReferenceRepository {
  final Map<ReferenceType, List<ReferenceEntry>> _cache = {};

  Future<List<ReferenceEntry>> load(ReferenceType type) async {
    final cached = _cache[type];
    if (cached != null) {
      return cached;
    }

    try {
      final raw = await rootBundle.loadString(type.assetPath);
      final decoded = await compute(decodeReferenceList, raw);
      final entries = [
        for (var i = 0; i < decoded.length; i++)
          ReferenceEntry.fromJson(decoded[i], type, i),
      ]..sort((a, b) => a.name.compareTo(b.name));
      _cache[type] = entries;
      return entries;
    } catch (error) {
      throw AppException('Unable to load ${type.label} reference data', error);
    }
  }

  Future<List<ReferenceEntry>> search(
    ReferenceType type,
    String query, {
    int limit = 50,
    bool Function(ReferenceEntry entry)? filter,
  }) async {
    final entries = await load(type);
    final normalized = query.trim();
    final matches = entries.where((entry) {
      final passesFilter = filter == null || filter(entry);
      if (!passesFilter) {
        return false;
      }
      return normalized.isEmpty || entry.matches(normalized);
    }).take(limit).toList();
    return matches;
  }
}
