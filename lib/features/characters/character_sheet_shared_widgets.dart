part of 'character_sheet_tabs.dart';

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.name,
    required this.abilityCode,
    required this.base,
    required this.rank,
    required this.total,
  });

  final String name;
  final String abilityCode;
  final int base;
  final ProficiencyRank rank;
  final int total;

  @override
  Widget build(BuildContext context) {
    final proficiency = switch (rank) {
      ProficiencyRank.none => '-',
      ProficiencyRank.proficient => 'P',
      ProficiencyRank.expertise => 'E',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name)),
          _MiniBadge(abilityCode),
          const SizedBox(width: 8),
          SizedBox(width: 42, child: Text(_signed(base))),
          SizedBox(width: 32, child: Text(proficiency)),
          _TotalBadge(total),
        ],
      ),
    );
  }
}

class _EntrySection extends StatelessWidget {
  const _EntrySection({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<CharacterListEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _PlainSection(
      title: title,
      child: entries.isEmpty
          ? Text('None', style: TextStyle(color: colors.onSurfaceVariant))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in entries) _EntryChip(entry: entry),
              ],
            ),
    );
  }
}

class _PlainSection extends StatelessWidget {
  const _PlainSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TrainingSection extends StatelessWidget {
  const _TrainingSection({required this.training});

  final CharacterTraining training;

  @override
  Widget build(BuildContext context) {
    return _PlainSection(
      title: 'Training',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrainingGroup(
            title: 'Armor Training',
            labels: [
              if (training.lightArmor) 'Light',
              if (training.mediumArmor) 'Medium',
              if (training.heavyArmor) 'Heavy',
              if (training.shields) 'Shields',
            ],
          ),
          const SizedBox(height: 12),
          _TrainingGroup(
            title: 'Weapon Training',
            labels: [
              if (training.simpleWeapons) 'Simple',
              if (training.martialWeapons) 'Martial',
              if (training.improvisedWeapons) 'Improvised',
            ],
          ),
        ],
      ),
    );
  }
}

class _TrainingGroup extends StatelessWidget {
  const _TrainingGroup({required this.title, required this.labels});

  final String title;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (labels.isEmpty)
          Text('None', style: TextStyle(color: colors.onSurfaceVariant))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final label in labels) Chip(label: Text(label))],
          ),
      ],
    );
  }
}

class _EntryChip extends StatelessWidget {
  const _EntryChip({required this.entry});

  final CharacterListEntry entry;

  @override
  Widget build(BuildContext context) {
    final name = entry.quantity > 1
        ? '${entry.name} x${entry.quantity}'
        : entry.name;
    return Chip(
      label: Text(name.trim().isEmpty ? 'Unnamed' : name),
    );
  }
}

class _TabList extends StatelessWidget {
  const _TabList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        for (final child in children) ...[
          child,
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.items});

  final List<_Fact> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 680
            ? 4
            : constraints.maxWidth > 430
                ? 3
                : 2;
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items) _FactTile(item: item, width: width),
          ],
        );
      },
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.item, required this.width});

  final _Fact item;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(
                item.value.trim().isEmpty ? '-' : item.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact {
  const _Fact(this.label, this.value);

  final String label;
  final String value;
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(label),
      ),
    );
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge(this.value);

  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _signed(value),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

String _signed(int value) => value >= 0 ? '+$value' : '$value';
