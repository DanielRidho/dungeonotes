class AppConstants {
  const AppConstants._();

  static const appName = 'Dungeonotes';
  static const defaultSystemName = 'D&D 5e 2024 / TTRPG';
  static const legalNote =
      'Dungeonotes is an unofficial TTRPG campaign tracker. It does not include official rulebook content. Users create and manage their own notes.';

  static const enableDevSeed = bool.fromEnvironment(
    'DUNGEONNOTES_ENABLE_DEV_SEED',
    defaultValue: false,
  );
  static const maxDiceHistory = 20;
  static const maxDiceCount = 50;
}
