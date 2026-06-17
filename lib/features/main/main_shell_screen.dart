import 'package:flutter/material.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../campaigns/campaign_list_screen.dart';
import '../characters/character_sheets_screen.dart';
import '../dice_roller/dice_roller_screen.dart';
import '../settings/settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          CampaignListScreen(),
          CharacterSheetsScreen(),
          DiceRollerScreen(),
          ReferenceComingSoonScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
        items: const [
          AppBottomNavItem(
            icon: Icons.map_outlined,
            selectedIcon: Icons.map,
            label: 'Campaign',
          ),
          AppBottomNavItem(
            icon: Icons.assignment_ind_outlined,
            selectedIcon: Icons.assignment_ind,
            label: 'Sheets',
          ),
          AppBottomNavItem(
            icon: Icons.casino_outlined,
            selectedIcon: Icons.casino,
            label: 'Dice',
          ),
          AppBottomNavItem(
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book,
            label: 'Reference',
          ),
          AppBottomNavItem(
            icon: Icons.more_vert,
            selectedIcon: Icons.more_vert,
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class ReferenceComingSoonScreen extends StatelessWidget {
  const ReferenceComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reference')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined, size: 72),
              SizedBox(height: 16),
              Text(
                'Coming soon',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'A lightweight Q&A-style rules reference will live here later.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
