import 'dart:convert';

enum ReferenceType { classes, species, backgrounds, spells, items }

extension ReferenceTypeLabel on ReferenceType {
  String get label {
    return switch (this) {
      ReferenceType.classes => 'Class',
      ReferenceType.species => 'Species',
      ReferenceType.backgrounds => 'Background',
      ReferenceType.spells => 'Spell',
      ReferenceType.items => 'Item',
    };
  }

  String get assetPath {
    return switch (this) {
      ReferenceType.classes => 'assets/reference/v1/classes.json',
      ReferenceType.species => 'assets/reference/v1/species.json',
      ReferenceType.backgrounds => 'assets/reference/v1/backgrounds.json',
      ReferenceType.spells => 'assets/reference/v1/spells.json',
      ReferenceType.items => 'assets/reference/v1/items.json',
    };
  }
}

class ReferenceEntry {
  const ReferenceEntry({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.properties,
    required this.publisher,
    required this.book,
  });

  final String id;
  final ReferenceType type;
  final String name;
  final String description;
  final Map<String, Object?> properties;
  final String publisher;
  final String book;

  factory ReferenceEntry.fromJson(
    Map<String, Object?> json,
    ReferenceType type,
    int index,
  ) {
    final name = json['name']?.toString() ?? 'Unnamed';
    final book = json['book']?.toString() ?? '';
    final publisher = json['publisher']?.toString() ?? '';
    return ReferenceEntry(
      id: _stableId(type, name, book, publisher, index),
      type: type,
      name: name,
      description: json['description']?.toString() ?? '',
      properties: Map<String, Object?>.from(
        json['properties'] as Map? ?? const {},
      ),
      publisher: publisher,
      book: book,
    );
  }

  String property(String key) => properties[key]?.toString() ?? '';

  String get sourceLabel {
    if (book.isNotEmpty && publisher.isNotEmpty) {
      return '$book - $publisher';
    }
    return book.isNotEmpty ? book : publisher;
  }

  bool matches(String query) {
    final normalized = query.toLowerCase();
    if (name.toLowerCase().contains(normalized) ||
        book.toLowerCase().contains(normalized) ||
        publisher.toLowerCase().contains(normalized) ||
        property('Item Type').toLowerCase().contains(normalized) ||
        property('School').toLowerCase().contains(normalized)) {
      return true;
    }

    final propertyText = properties.values.join(' ').toLowerCase();
    if (propertyText.contains(normalized)) {
      return true;
    }

    if (normalized.length < 3) {
      return false;
    }
    final descriptionPreview = description.length > 420
        ? description.substring(0, 420)
        : description;
    return descriptionPreview.toLowerCase().contains(normalized);
  }
}

String _stableId(
  ReferenceType type,
  String name,
  String book,
  String publisher,
  int index,
) {
  final raw = '${type.name}|$name|$book|$publisher|$index';
  final slug = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? '${type.name}-$index' : slug;
}

List<Map<String, Object?>> decodeReferenceList(String raw) {
  final decoded = jsonDecode(raw) as List<dynamic>;
  return [
    for (final item in decoded) Map<String, Object?>.from(item as Map),
  ];
}
