import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/error_view.dart';
import 'data/local/local_database.dart';
import 'features/campaigns/campaign_detail_screen.dart';
import 'features/dice_roller/dice_roller_screen.dart';
import 'features/main/main_shell_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_controller.dart';
import 'features/settings/settings_screen.dart';

final appInitProvider = FutureProvider<void>((ref) async {
  await ref.read(localDatabaseProvider).init();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingSeen = ref.watch(onboardingSeenProvider);

  return GoRouter(
    initialLocation: onboardingSeen ? '/campaigns' : '/onboarding',
    redirect: (context, state) {
      final isOnboarding = state.matchedLocation == '/onboarding';
      if (!onboardingSeen && !isOnboarding) {
        return '/onboarding';
      }
      if (onboardingSeen && isOnboarding) {
        return '/campaigns';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/campaigns',
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/campaigns/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CampaignDetailScreen(campaignId: id);
        },
      ),
      GoRoute(
        path: '/dice',
        builder: (context, state) => const DiceRollerScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class DungeonNotesBootstrap extends ConsumerWidget {
  const DungeonNotesBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(appInitProvider);

    return init.when(
      data: (_) => const DungeonNotesApp(),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const _AppSplashScreen(),
      ),
      error: (error, stackTrace) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(
          body: ErrorView(
            title: 'Local database failed to open',
            message: error.toString(),
            actionLabel: 'Retry',
            onRetry: () => ref.invalidate(appInitProvider),
          ),
        ),
      ),
    );
  }
}

class _AppSplashScreen extends StatelessWidget {
  const _AppSplashScreen();

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF171A1F);
    const gold = Color(0xFF9C7A2F);
    return const Scaffold(
      backgroundColor: background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(28)),
              child: Image(
                image: AssetImage('assets/brand/dungeonotes_mark.png'),
                width: 112,
                height: 112,
              ),
            ),
            SizedBox(height: 18),
            Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Offline campaign notes',
              style: TextStyle(color: gold),
            ),
          ],
        ),
      ),
    );
  }
}

class DungeonNotesApp extends ConsumerWidget {
  const DungeonNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
