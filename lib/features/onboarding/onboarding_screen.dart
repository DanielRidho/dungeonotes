import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../settings/settings_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).complete();
    if (mounted) {
      context.go('/campaigns');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _OnboardingPage(
        icon: Icons.shield_moon_outlined,
        title: 'Keep Campaigns Organized',
        body:
            'Track sessions, quests, characters, NPCs, locations, and shared loot without login or internet.',
      ),
      const _OnboardingPage(
        icon: Icons.assignment_ind_outlined,
        title: 'Build Table-Ready Sheets',
        body:
            'Create lightweight character sheets, manage inventory, spells, combat state, and campaign copies.',
      ),
      const _OnboardingPage(
        icon: Icons.casino_outlined,
        title: 'Play Faster Offline',
        body:
            'Roll dice, search notes, and update your table state with a clean fantasy-minimal workflow.',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _index == i ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _index == i
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _index == pages.length - 1
                        ? _finish
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOut,
                            ),
                    child: Text(
                      _index == pages.length - 1 ? 'Start' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 136,
            height: 136,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Image.asset('assets/brand/dungeonotes_mark_clear.png'),
          ),
          const SizedBox(height: 28),
          Icon(icon, size: 32, color: colors.primary),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
