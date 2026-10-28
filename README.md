# JOY — one screen, big rivalries

36 offline mini-games for 2–4 people sharing an Android phone, iPhone or tablet. Includes a searchable illustrated lobby, favorites and recent games, custom party playlists, local profiles, saved results, and optional vibration. Four games also offer solo computer practice. Real-time games support simultaneous touch; strategy and word games use alternating turns.

Tested with Flutter 3.47.8 / Dart 3.13.7. Use the current stable Flutter SDK.

## Run

```bash
git clone https://github.com/aminemtar/joy.git
cd joy
flutter pub get
flutter run
```

If already cloned, run `git pull origin main` first. Android requires Android Studio/SDK. iOS requires macOS, Xcode and a simulator or a signed physical device. For a browser preview: `flutter run -d chrome`. A mouse provides only one pointer, so touch hardware is recommended for simultaneous multiplayer.

## Look and feel

A consistent navy interface with blue accents, bordered information panels, clear play buttons and a dedicated 2/3/4-player party selector. The lobby, settings, splash and play boards share the same surface and control styles.

## Party features (1.4)

- **Quick rematch:** replay from the result dialog without returning to the lobby. Each completed match is counted once. In a league, Continue advances the fixture instead of replaying it. Quick play also offers a random Next game.
- **Party mode:** choose 2–4 players, 3/5/8/12 rounds and one or more categories. Playlists contain unique concepts and shorten automatically when a category has fewer games. Interrupted sessions show only completed matches. End-of-session standings and awards use actual results.
- **Library:** heart a game, filter Favorites or Recent, and search by name. The latest eight unique games are saved.
- **Profiles and history:** edit the four local nicknames and avatars in Settings. The latest 100 completed results include participants, winner/draw, duration and practice status. No account or internet is required. Computer wins never increase a human profile’s total.
- **Tutorials:** all 36 games have a three-step animated control guide before first play, with Skip and a Watch tutorial replay button. Guides illustrate controls; the actual game begins after dismissal.
- **Computer practice:** Ping Pong, Tic Tac Toe, Connect Four and Rock Paper Scissors. Board bots make legal moves; normal bots win/block immediate threats, hard Tic Tac Toe uses minimax, and hard Connect Four avoids immediate losing replies. RPS chooses randomly without inspecting the human choice.
- **Difficulty:** Easy/Normal/Hard affects Ping Pong ball/bot speed, board bot strength in practice, Simon sequence length/flash speed, cup shuffle speed, and Math Sprint number ranges. Other concepts retain their standard rules.
- **Round duration:** Untimed or 60/120/180 seconds on score-based games (racing, parking, paddles, baskets, picture pairs, observation searches, riddles, math, reaction, scramble and crossword). Expiry compares live scores; equal leaders draw. The clock pauses in the background and during action-game countdown/manual pause. Other games use their natural finish condition.
- **Accessibility:** saved reduced motion and larger text settings, P1–P4 scoreboard labels, and distinct Connect Four shapes. Existing Simon pads are numbered and Tic Tac Toe uses cross/circle shapes.
- **Scorecards:** share a PNG from match or party results. Android/iOS open the native share sheet; browsers download the image. Unsupported platform sharing falls back to copying the result text. Images are generated locally; nothing is posted automatically.

## Opening and player choice

The native launch surfaces use JOY’s navy background, followed by an animated logo, orbiting particles and a short loading transition. The splash can be skipped and respects reduced-motion settings.

Choose **2 players**, **3 players** or **4 players** in the lobby. The selection, four player names and individual win totals are saved. The 16 group games use shared turns or individual reaction pads: Treasure Auction, Sliding Puzzle, Picture Pairs, Spot the Difference, Hidden Objects, Simon Echo, Follow the Cup, Riddle Duel, Math Sprint, Reaction Duel, Word Scramble, Crossword Duel, Word Search, Dots and Boxes, Code Breaker and Minesweeper Duel.

The remaining 20 games are two-sided contests. With 3 or 4 players they run as an explicit **round-robin league**, including every unique pair (3 matches for 3 players, 6 for 4). Wins award 3 league points; draws award 1 point to each opponent. The standings select the game’s overall winner. The lobby labels group games as shared turns and the others as leagues. Three/four simultaneous controls are not claimed for those two-sided arenas.

## Fixed play areas and paddle input

Active gameplay has no scrolling parent. Boards and their controls are laid out together and scaled into the available viewport, with a compact clue selector and keyboard for crosswords. The lobby and settings may still scroll. Ping-pong uses a single horizontal drag path, preserves the initial finger grip, clamps the paddle inside its rails and fixes its vertical position. The frame loop no longer moves a held paddle toward a competing target.

## The 36 concepts

| # | Game | Core interaction and objective |
|---|---|---|
| 1 | Neon Rally | Steer along a moving racing line to gain checkpoint progress while avoiding traffic. |
| 2 | Treasure Auction | Secret bids, limited coins and six changing-value treasures; maximize gems. |
| 3 | Parking Duel | Drag the car into changing parking bays. First to five bays. |
| 4 | Traffic Control | Schedule perpendicular traffic flows through two intersections; clear cars without collisions. |
| 5 | Stack Tower | Drop moving blocks; cut away overhang and preserve enough overlap to survive. |
| 6 | Ping Pong | Horizontal paddle deflection across the full baseline. Five points. |
| 7 | Air Hockey | Move a circular striker in two dimensions; score through a narrow goal. |
| 8 | Penalty Shootout | Flick shots while the opposing player actively drags the keeper. Roles alternate. |
| 9 | Basket Shots | Time taps to align a moving basketball with the hoop. |
| 10 | Mini Golf | Pull back and release to putt; use wall bounces and controlled speed. |
| 11 | Sumo Ring | Push the rival outside a fixed ring while keeping your body inside. |
| 12 | Tank Battle | Move and fire traveling projectiles to land five hits. |
| 13 | Snake Duel | Steer a growing trail around food, walls and the opponent. |
| 14 | Bomber Arena | Place delayed area blasts; escape both your own and your rival's bombs. |
| 15 | Gap Jumpers | Jump over scrolling gaps, land before jumping again, and outlast the rival. |
| 16 | Sliding Puzzle | Move numbered tiles into a single empty space to restore their order. |
| 17 | Reversi | Bracket discs in any direction to capture territory; legal-move and pass rules apply. |
| 18 | Maze Race | Navigate adjacent grid cells around walls toward the opposite corner. |
| 19 | Connect Four | Drop discs under gravity to create a line of four. |
| 20 | Tic Tac Toe | Claim free squares to create a line of three. |
| 21 | Picture Pairs | Remember hidden artwork, reveal pairs, and retain the turn on a match. |
| 22 | Spot the Difference | Compare two illustrated scenes; tap the changed tile. |
| 23 | Hidden Objects | Search a crowded 25-object collection for the single target illustration. |
| 24 | Simon Echo | Watch and reproduce the complete flashing-pad sequence; pattern lengths increase. |
| 25 | Follow the Cup | Visually track an object through animated cup swaps. |
| 26 | Riddle Duel | Solve wordplay and logic clues. |
| 27 | Math Sprint | Solve generated arithmetic expressions. |
| 28 | Reaction Duel | Tap after a random signal; premature taps award the opponent a point. |
| 29 | Word Scramble | Assemble the word from individual selectable letter tiles. |
| 30 | Rock Paper Scissors | Make secret cyclic hand choices and reveal the winning matchup. |
| 31 | Crossword Duel | Fill Across/Down clues on a genuine intersecting grid; confirmed letters lock into crossings. |
| 32 | Word Search | Drag straight lines across an eight-direction letter grid, including backwards words. |
| 33 | Dots and Boxes | Join neighboring dots, close squares and earn extra turns. |
| 34 | Battleship Duel | Fire at coordinates on a hidden fleet grid; sink all enemy hull cells. |
| 35 | Code Breaker | Use exact/misplaced peg feedback to deduce a repeating-color secret. |
| 36 | Minesweeper Duel | Use neighbor counts, flood reveals and flags to find safe cells; two mine hits eliminate a player. |

Sharing a renderer or scoreboard does not select rules: `game_factory.dart` explicitly routes each concept to its engine. Crossword, word search, Reversi, fleet placement, mine reveals, code feedback, tower trimming, traffic collisions and box closure have independent state/rule implementations. The superseded football/pushing reskins are no longer catalog entries.

## Card flipping

Picture Pairs uses a 440 ms perspective rotation with separate front/back faces, patterned beveled backs, illustrated fronts and matched-card highlights. The cards never show a mirrored front. Input locks while the second pair is being resolved; unmatched faces remain visible for 1.1 seconds before flipping back. Reduced-motion system settings remove the flip duration.

## Sound effects

Fifteen original synthesized arcade cues are bundled for offline play: taps, flips, correct/missed moves, impacts, jumps, shots, countdown/start cues, win/draw fanfares and four Simon Echo tones. Use the speaker button in the lobby or match toolbar to mute instantly. Settings also provide a volume slider; both preferences persist locally.

The sound service throttles repeated contacts and serializes native resource changes. Result music replaces pending gameplay cues. Muting, leaving a match or backgrounding stops playback. Effects mix with other apps and use Android media/game volume and iOS playback audio. An original 20-second background-music loop starts with the app, continues between screens, and has its own mute/volume controls in Settings. It pauses when the app backgrounds and resumes on return. Browsers may require the first user interaction before allowing music playback.

`assets/audio/README.md` documents the cues; `python tool/build_sound_effects.py` regenerates them without third-party sound files. `lib/sound.dart` contains playback, preference and lifecycle handling, and `test/sound_test.dart` checks the audio files and service behavior. After pulling this update, stop any running debug app and launch it again so the new native audio plugin is registered.

## Structure and artwork

- `lib/catalog.dart`, `lib/game_factory.dart`: catalog, instructions and explicit engine routing.
- `lib/players.dart`, `lib/party_league.dart`: group-turn compatibility, unique-pair fixtures and league standings.
- `lib/music.dart`, `lib/splash.dart`: app-opening music and animated entry.
- `lib/party_data.dart`, `party_screens.dart`: saved library/history/options, party playlists and awards.
- `lib/practice_ai.dart`, `tutorial.dart`: legal computer moves and the 36 first-play guides.
- `lib/result_share.dart`: local PNG scorecards, native share sheets and browser downloads.
- `tool/build_background_music.py`: regenerates the original music track with the Python standard library.
- `lib/games/action.dart`: racing, parking, paddle sports, golf, sumo, tanks, snake and bombs.
- `lib/games/arcade.dart`, `arcade_models.dart`: traffic scheduling, tower trimming, flick/keeper shootouts and jumping.
- `lib/games/puzzle.dart`, `flip_card.dart`: sliding tiles, maze, line games and animated picture matching.
- `lib/games/strategy.dart`, `strategy_models.dart`: auctions, Reversi, dots/boxes, fleets, code deduction and mines.
- `lib/games/words.dart`, `word_models.dart`: four crossword packs, generated word search and letter assembly.
- `lib/games/observation.dart`: scene comparison, object search and full-sequence Simon playback.
- `lib/games/brain.dart`: riddles, arithmetic, cup tracking, reaction and secret hand choices.
- `lib/games/sprites.dart`: resolution-independent gameplay artwork.
- `assets/art/`: bundled atlases and master app icon. Generation prompts and layout details are in its README.

## Validation

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --no-tree-shake-icons
```

Tests cover rule outcomes, valid crossword crossings, generated search paths, duplicate-color deduction, safe first mine reveals, perspective animation, simultaneous touch, lifecycle pause and opening/disposal of all 36 games at phone size. GitHub Actions runs formatting, analysis, tests and a web build. The web build retains the full icon font to avoid an SDK const-finder error encountered with icon tree shaking.

## Scope

This is a playable collection requiring device testing and balancing before store release. Menus, clues and questions are English. Crossword packs, riddles and scramble vocabulary are finite. The illustrated memory game uses artwork rather than photographs. No AI opponents, online/LAN multiplayer, ads, accounts, paid content or release signing is configured.

Use **Settings → Test sound** to check playback. This shows plugin or asset errors instead of silently hiding them. If enabling sound after setting volume to zero, JOY restores a 60% app volume. Device media volume and connected audio outputs still apply.
