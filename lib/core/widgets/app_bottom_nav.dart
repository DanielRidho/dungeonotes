import 'package:flutter/material.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    this.onlyShowSelectedLabel = false,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<AppBottomNavItem> items;
  final bool onlyShowSelectedLabel;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 72,
      selectedIndex: selectedIndex,
      labelBehavior: onlyShowSelectedLabel
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: onSelected,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
      ],
    );
  }
}
