part of 'character_sheet_tabs.dart';

class _InventoryListPanel<T> extends StatefulWidget {
  const _InventoryListPanel({
    required this.title,
    required this.entries,
    required this.emptyText,
    required this.onSearch,
    required this.onCustom,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEdit,
    required this.onDelete,
    required this.titleOf,
    required this.quantityOf,
    required this.subtitleOf,
    required this.detailLinesOf,
    this.idOf,
    this.equippedId = '',
    this.onEquipChanged,
  });

  final String title;
  final List<T> entries;
  final String emptyText;
  final VoidCallback onSearch;
  final VoidCallback onCustom;
  final ValueChanged<int> onIncrement;
  final ValueChanged<int> onDecrement;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final String Function(T entry) titleOf;
  final int Function(T entry) quantityOf;
  final String Function(T entry) subtitleOf;
  final List<_InventoryDetailLine> Function(T entry) detailLinesOf;
  final String Function(T entry)? idOf;
  final String equippedId;
  final void Function(int index, bool equipped)? onEquipChanged;

  @override
  State<_InventoryListPanel<T>> createState() => _InventoryListPanelState<T>();
}

class _InventoryListPanelState<T> extends State<_InventoryListPanel<T>> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      '${widget.entries.length}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _InventoryListContent<T>(panel: widget),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryListContent<T> extends StatelessWidget {
  const _InventoryListContent({required this.panel});

  final _InventoryListPanel<T> panel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                TextButton(onPressed: panel.onSearch, child: const Text('Search')),
                TextButton(onPressed: panel.onCustom, child: const Text('Custom')),
              ],
            ),
          ),
          if (panel.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text(
                panel.emptyText,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            )
          else
            for (var i = 0; i < panel.entries.length; i++)
              _InventoryItemTile<T>(
                entry: panel.entries[i],
              index: i,
                titleOf: panel.titleOf,
                quantityOf: panel.quantityOf,
                subtitleOf: panel.subtitleOf,
                detailLinesOf: panel.detailLinesOf,
                idOf: panel.idOf,
                equippedId: panel.equippedId,
                onEquipChanged: panel.onEquipChanged,
                onIncrement: panel.onIncrement,
                onDecrement: panel.onDecrement,
                onEdit: panel.onEdit,
                onDelete: panel.onDelete,
              ),
        ],
      ),
    );
  }
}

class _InventoryItemTile<T> extends StatelessWidget {
  const _InventoryItemTile({
    required this.entry,
    required this.index,
    required this.titleOf,
    required this.quantityOf,
    required this.subtitleOf,
    required this.detailLinesOf,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEdit,
    required this.onDelete,
    this.idOf,
    this.equippedId = '',
    this.onEquipChanged,
  });

  final T entry;
  final int index;
  final String Function(T entry) titleOf;
  final int Function(T entry) quantityOf;
  final String Function(T entry) subtitleOf;
  final List<_InventoryDetailLine> Function(T entry) detailLinesOf;
  final String Function(T entry)? idOf;
  final String equippedId;
  final void Function(int index, bool equipped)? onEquipChanged;
  final ValueChanged<int> onIncrement;
  final ValueChanged<int> onDecrement;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final quantity = quantityOf(entry);
    final subtitle = subtitleOf(entry);
    final title = titleOf(entry);
    final entryId = idOf?.call(entry) ?? '';
    final equipped = entryId.isNotEmpty && entryId == equippedId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: equipped
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: 'Details',
                              icon: const Icon(Icons.info_outline, size: 18),
                              onPressed: () => _showDetails(context, title),
                            ),
                          ],
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _QuantityStepper(
                    quantity: quantity,
                    onIncrement: () => onIncrement(index),
                    onDecrement:
                        quantity <= 1 ? null : () => onDecrement(index),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Edit item',
                    icon: const Icon(Icons.edit_outlined),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(index);
                      } else if (value == 'delete') {
                        onDelete(index);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              if (onEquipChanged != null && entryId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: equipped
                      ? FilledButton.tonalIcon(
                          onPressed: () => onEquipChanged?.call(index, false),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Unequip'),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => onEquipChanged?.call(index, true),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Equip'),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, String title) {
    final lines = detailLinesOf(entry);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lines.isEmpty)
                const Text('No details noted.')
              else
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.label,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(line.value.trim().isEmpty ? '-' : line.value),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _InventoryDetailLine {
  const _InventoryDetailLine(this.label, this.value);

  final String label;
  final String value;
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            tooltip: 'Decrease quantity',
            onPressed: onDecrement,
            icon: const Icon(Icons.remove, size: 18),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            tooltip: 'Increase quantity',
            onPressed: onIncrement,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}
