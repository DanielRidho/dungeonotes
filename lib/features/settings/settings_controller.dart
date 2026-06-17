import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_models.dart';
import '../../data/repositories/local_repositories.dart';

final onboardingSeenProvider =
    StateNotifierProvider<OnboardingSeenController, bool>((ref) {
  return OnboardingSeenController(ref.read(settingsRepositoryProvider));
});

final themeChoiceProvider =
    StateNotifierProvider<ThemeController, ThemeChoice>((ref) {
  return ThemeController(ref.read(settingsRepositoryProvider));
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final choice = ref.watch(themeChoiceProvider);
  return switch (choice) {
    ThemeChoice.system => ThemeMode.system,
    ThemeChoice.light => ThemeMode.light,
    ThemeChoice.dark => ThemeMode.dark,
  };
});

class OnboardingSeenController extends StateNotifier<bool> {
  OnboardingSeenController(this._repository) : super(false) {
    _load();
  }

  final SettingsRepository _repository;

  Future<void> _load() async {
    state = await _repository.getOnboardingSeen();
  }

  Future<void> complete() async {
    await _repository.setOnboardingSeen(true);
    state = true;
  }
}

class ThemeController extends StateNotifier<ThemeChoice> {
  ThemeController(this._repository) : super(ThemeChoice.system) {
    _load();
  }

  final SettingsRepository _repository;

  Future<void> _load() async {
    state = await _repository.getThemeChoice();
  }

  Future<void> setTheme(ThemeChoice choice) async {
    await _repository.setThemeChoice(choice);
    state = choice;
  }
}
