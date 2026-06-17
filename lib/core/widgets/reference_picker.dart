import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/reference_models.dart';
import '../../data/repositories/reference_repository.dart';

class ReferencePickerField extends ConsumerWidget {
  const ReferencePickerField({
    required this.label,
    required this.type,
    required this.value,
    required this.onPicked,
    super.key,
    this.filter,
  });

  final String label;
  final ReferenceType type;
  final String value;
  final ValueChanged<ReferenceEntry> onPicked;
  final bool Function(ReferenceEntry entry)? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        final picked = await showReferencePicker(
          context,
          ref,
          type: type,
          title: label,
          filter: filter,
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.search),
        ),
        child: Text(
          value.isEmpty ? 'Choose ${type.label.toLowerCase()}' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

Future<ReferenceEntry?> showReferencePicker(
  BuildContext context,
  WidgetRef ref, {
  required ReferenceType type,
  required String title,
  bool Function(ReferenceEntry entry)? filter,
}) {
  return showDialog<ReferenceEntry>(
    context: context,
    builder: (context) => _ReferencePickerDialog(
      type: type,
      title: title,
      filter: filter,
    ),
  );
}

class _ReferencePickerDialog extends ConsumerStatefulWidget {
  const _ReferencePickerDialog({
    required this.type,
    required this.title,
    this.filter,
  });

  final ReferenceType type;
  final String title;
  final bool Function(ReferenceEntry entry)? filter;

  @override
  ConsumerState<_ReferencePickerDialog> createState() =>
      _ReferencePickerDialogState();
}

class _ReferencePickerDialogState
    extends ConsumerState<_ReferencePickerDialog> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  int _page = 0;
  static const _pageSize = 100;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _query = value.trim().toLowerCase();
          _page = 0;
        });
      }
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    setState(() {
      _query = '';
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(referenceEntriesProvider(widget.type));
    final media = MediaQuery.of(context);
    final dialogHeight = math.max(
      260.0,
      math.min(
        560.0,
        media.size.height -
            media.viewInsets.bottom -
            media.padding.top -
            media.padding.bottom -
            150,
      ),
    );
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: dialogHeight,
        child: entries.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => SizedBox(
            height: 180,
            child: Center(child: Text(error.toString())),
          ),
          data: (items) {
            final matches = items.where((entry) {
              final passes = widget.filter == null || widget.filter!(entry);
              return passes && (_query.isEmpty || entry.matches(_query));
            }).toList();
            final pageCount = matches.isEmpty
                ? 1
                : ((matches.length - 1) ~/ _pageSize) + 1;
            if (_page >= pageCount) {
              _page = pageCount - 1;
            }
            final start = _page * _pageSize;
            final end = start + _pageSize > matches.length
                ? matches.length
                : start + _pageSize;
            final filtered = matches.sublist(start, end);

            return Column(
              children: [
                TextField(
                  controller: _search,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    labelText: 'Search',
                    helperText: matches.isEmpty
                        ? 'No results'
                        : 'Showing ${start + 1}-$end of ${matches.length}',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: _clearSearch,
                          ),
                        ),
                ),
                if (matches.length > _pageSize) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Page ${_page + 1} of $pageCount'),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Previous page',
                        onPressed: _page == 0
                            ? null
                            : () => setState(() => _page -= 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        tooltip: 'Next page',
                        onPressed: _page >= pageCount - 1
                            ? null
                            : () => setState(() => _page += 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('No matches. Try another name or source.'),
                        )
                      : ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            return ListTile(
                              title: Text(entry.name),
                              subtitle: Text(
                                [
                                  if (entry.book.isNotEmpty) entry.book,
                                  if (entry.publisher.isNotEmpty)
                                    entry.publisher,
                                  if (entry.property('Item Type').isNotEmpty)
                                    entry.property('Item Type'),
                                  if (entry.property('Level').isNotEmpty)
                                    'Level ${entry.property('Level')}',
                                  if (entry.property('School').isNotEmpty)
                                    entry.property('School'),
                                ].join(' - '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.of(context).pop(entry),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
