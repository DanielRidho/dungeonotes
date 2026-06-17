# Dungeonotes

Dungeonotes is an offline-first Flutter app for D&D and tabletop roleplaying campaign notes. It helps players and Dungeon Masters track campaigns, sessions, quests, character sheets, NPCs, locations, inventory, spells, dice rolls, and campaign state without login, backend, Firebase, or internet access.

The Flutter project lives in [`dungeonnotes/`](dungeonnotes/).

## Highlights

- Offline-first local data with Hive.
- Riverpod state management and GoRouter navigation.
- Campaign tracker with sessions, quests, characters, NPCs, locations, shared loot, and timeline/history.
- Lightweight D&D character sheets with reusable library sheets and campaign-specific runtime state.
- Dice roller, theme settings, JSON import/export, local images, and responsive Material 3 UI.
- No official rulebook database or copyrighted rules content. Users create and manage their own notes.

## Run

```bash
cd dungeonnotes
flutter pub get
flutter run
```

## Build

```bash
cd dungeonnotes
flutter build apk --release
```

## Legal Note

Dungeonotes is an unofficial TTRPG campaign tracker. It is not affiliated with, endorsed, sponsored, or approved by Wizards of the Coast. It does not include official rulebook content. Users create and manage their own notes.
