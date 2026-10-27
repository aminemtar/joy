# JOY — one screen, two rivals

An offline Flutter mini-game collection for two people sharing one Android phone, iPhone or tablet. Includes 30 playable prototypes, a filterable lobby, random quick play, five-round tournaments, player names, persistent win totals, and optional vibration. Action games use simultaneous pointers; board and question games use pass-and-play.

Tested with Flutter 3.47.8 / Dart 3.13.7. Use the current stable Flutter SDK.

## Run on your Mac

```bash
git clone https://github.com/aminemtar/joy.git
cd joy
flutter pub get
flutter run
```

If already cloned, run `git pull origin main` first. Android needs Android Studio/Android SDK. iOS needs macOS, Xcode and an installed simulator or signed physical device. This repository includes Android, iOS and web runners. For a browser preview: `flutter run -d chrome`. Touch hardware is recommended for simultaneous multiplayer: a mouse only provides one pointer.

## The 30 games

| # | Game | Controls / win condition |
|---|---|---|
| 1 | Neon Rally | Hold the left/right part of your half to steer; follow the gold racing line for speed. Ten checkpoints or survive your rival. |
| 2 | Car Football | Drag a car in your half; bump the ball into the opposite goal. Five goals. |
| 3 | Parking Duel | Drag to the highlighted bays in your half. Five bays. |
| 4 | Traffic Dodge | Hold left/right to avoid approaching traffic. Last survivor. |
| 5 | Bumper Cars | Drag and push the rival outside the arena. |
| 6 | Ping Pong | Drag a paddle horizontally. Five goals. |
| 7 | Air Hockey | Drag a striker in your half. Five goals. |
| 8 | Mini Football | Drag your player to kick the ball. Five goals. |
| 9 | Basket Shots | Tap your half when the moving ball aligns with the target. Five baskets. |
| 10 | Mini Golf | Drag back from the ball and release. Three holes. |
| 11 | Sumo Ring | Drag your wrestler to push the rival out. |
| 12 | Tank Battle | Drag to move, FIRE to shoot toward the rival. Five hits. |
| 13 | Snake Duel | Direction buttons; avoid walls and both trails. Last survivor. |
| 14 | Bomber Arena | Drag and drop timed bombs. Avoid all blasts, including your own. |
| 15 | Platform Survival | Drag on a shrinking platform. Last survivor. |
| 16 | Sliding Puzzle | Alternate legal moves in a shuffled, solvable board. Completing it wins. |
| 17 | Block Duel | Claim cells; completing a full row/column scores. Most points on a full board wins. |
| 18 | Maze Race | Alternate adjacent-cell moves around walls to reach the opposite corner. |
| 19 | Connect Four | Tap a column to drop a disc. Four in any direction. |
| 20 | Tic Tac Toe | Alternate turns. Three in a row. |
| 21 | Picture Pairs | Reveal matching illustrated symbols. Most pairs wins; matches retain the turn. |
| 22 | Spot the Difference | Compare two symbol rows and identify the changed position. Five correct answers. |
| 23 | Find the Object | Select the requested symbol. Five correct answers. |
| 24 | Sequence Memory | Memorize four colors before they hide; identify the last color. Five correct answers. |
| 25 | Follow the Cup | Watch five animated cup swaps and find the hidden diamond. Five correct answers. |
| 26 | Riddle Duel | Multiple-choice riddles. Five correct answers. |
| 27 | Math Sprint | Random addition/multiplication questions. Five correct answers. |
| 28 | Reaction Duel | Both players wait for NOW. Early taps award the rival a point. First to five. |
| 29 | Word Scramble | Identify the scrambled word. Five correct answers. |
| 30 | Rock Paper Scissors | Secret choices, then pass the phone. Five winning hands. |

## Structure

- `assets/art/app_icon.png`: JOY master icon, also exported to all Android/iOS/web runner sizes.
- `assets/art/game_atlas.png`: 30 bundled 3D game illustrations. See `assets/art/README.md` for the generation prompt and atlas layout.
- `lib/game_art.dart`: shared atlas loading and tile rendering.
- `lib/games/sprites.dart`: custom vector gameplay artwork.
- `lib/catalog.dart`: game names, families and instructions.
- `lib/main.dart`: responsive lobby, setup, persistence, navigation and tournament results.
- `lib/games/action.dart`: ticker-driven arenas, multi-touch input, collisions, timers and lifecycle pause. The engine uses Flutter CustomPainter without an additional game framework.
- `lib/games/puzzle.dart`: turn-based boards, legal moves, matching and win detection.
- `lib/games/brain.dart`: question generation, memory challenges, animated cups and reaction timing.
- `test/joy_test.dart`: catalog, navigation, winning-board cases and opening/disposal checks across all 30 games.

## Checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --no-tree-shake-icons
```

GitHub Actions runs these checks on pushes and pull requests. The web check retains the full icon font to avoid a const-finder error encountered with this SDK’s icon tree shaker.

## Current scope

This is a first playable version, not a store-ready release. The lobby and introductions use 30 custom 3D illustrations, with the same artwork on Picture Pairs cards. Action games use custom vector cars, tanks, wrestlers, balls, bombs and targets. A few text-based brain challenges still use emoji symbols; Picture Pairs uses illustrations rather than photographs. Several sports share a physics foundation, and arena games share pushing mechanics. Riddles and word lists are intentionally small. Menus and questions are currently English only. No sound pack, AI opponents, four-player mode, online/LAN multiplayer, ads, accounts or paid content. Device testing and balancing on actual Android/iOS hardware remain necessary before release. Native release signing is not configured; no credentials belong in this repository.
