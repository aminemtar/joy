import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joy/catalog.dart';
import 'package:joy/main.dart';
import 'package:joy/party_data.dart';
import 'package:joy/party_screens.dart';
import 'package:joy/practice_ai.dart';
import 'package:joy/result_share.dart';
import 'package:joy/tutorial.dart';
import 'package:joy/games/action.dart';
import 'package:joy/games/puzzle.dart';
import 'package:joy/games/brain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Party playlists respect categories, have no repeats and cap short pools',
    () {
      final playlist = partyPlaylist(
        {'Words', 'Sports'},
        12,
        random: Random(4),
      );
      expect(playlist.toSet().length, playlist.length);
      expect(
        playlist.every((i) => {'Words', 'Sports'}.contains(games[i].category)),
        isTrue,
      );
      expect(partyPlaylist({}, 5), isEmpty);
      expect(
        partyPlaylist({'Words'}, 12).length,
        games.where((g) => g.category == 'Words').length,
      );
    },
  );
  test(
    'Saved library, avatars, options and results survive a new store',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = PartyData();
      await store.initialize();
      await store.toggleFavorite(19);
      await store.opened(19);
      await store.opened(5);
      await store.opened(19);
      await store.tutorialSeen(19);
      store.avatars[0] = 7;
      store.reducedMotion = true;
      store.largeText = true;
      store.colorSymbols = true;
      store.roundSeconds = 120;
      store.difficulty = Difficulty.hard;
      await store.saveOptions();
      await store.record(
        MatchRecord(
          game: 19,
          names: ['A', 'B'],
          winner: 0,
          seconds: 12,
          date: DateTime(2026),
        ),
      );
      final restored = PartyData();
      await restored.initialize();
      expect(restored.favorites, {19});
      expect(restored.recent, [19, 5]);
      expect(restored.seen, {19});
      expect(restored.avatars.first, 7);
      expect(
        restored.reducedMotion && restored.largeText && restored.colorSymbols,
        isTrue,
      );
      expect(restored.roundSeconds, 120);
      expect(restored.difficulty, Difficulty.hard);
      expect(restored.history.single.names, ['A', 'B']);
      await restored.toggleFavorite(19);
      expect(restored.favorites, isEmpty);
    },
  );
  test('Malformed history and invalid saved IDs are ignored', () async {
    SharedPreferences.setMockInitialValues({
      'favorites': ['19', '-1', '999', 'a'],
      'matchHistory': ['no JSON', '{}'],
      'difficulty': 99,
      'roundSeconds': 9,
    });
    final store = PartyData();
    await store.initialize();
    expect(store.favorites, {19});
    expect(store.history, isEmpty);
    expect(store.roundSeconds, 0);
    expect(store.difficulty, Difficulty.hard);
  });
  test('Recent games and match history have bounded size', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PartyData();
    await store.initialize();
    for (var i = 0; i < 36; i++) {
      await store.opened(i);
    }
    expect(store.recent.length, 8);
    expect(store.recent.first, 35);
    for (var i = 0; i < 105; i++) {
      await store.record(
        MatchRecord(
          game: 19,
          names: ['A', 'B'],
          winner: -1,
          seconds: i,
          date: DateTime(2026),
        ),
      );
    }
    expect(store.history.length, 100);
    expect(store.history.first.seconds, 104);
  });
  test('Awards reflect actual wins, including duplicate nicknames', () {
    final records = [
      MatchRecord(
        game: 27,
        names: ['Sam', 'Sam'],
        winner: 1,
        seconds: 12,
        date: DateTime(2026),
      ),
    ];
    final awards = partyAwards(records, ['Sam', 'Sam']);
    expect(awards[1], 'Party champion');
    expect(awards[0], 'Rematch ready');
    expect(partyAwards([], ['A', 'B']), isEmpty);
  });
  test('Computer takes wins and blocks threats', () {
    expect(
      computerMove(
        [2, 2, 0, 1, 0, 0, 1, 0, 0],
        3,
        Difficulty.normal,
        Random(1),
      ),
      2,
    );
    expect(
      computerMove(
        [1, 1, 0, 0, 2, 0, 0, 0, 0],
        3,
        Difficulty.normal,
        Random(1),
      ),
      2,
    );
    final board =
        List.filled(42, 0)
          ..[35] = 2
          ..[36] = 2
          ..[37] = 2;
    expect(computerMove(board, 7, Difficulty.hard, Random(1)), 38);
  });
  test('Hard Tic Tac Toe cannot lose against any legal human continuation', () {
    void explore(List<int> board) {
      for (var i = 0; i < 9; i++) {
        if (board[i] != 0) continue;
        final next = List<int>.of(board)..[i] = 1;
        expect(lineWin(next, 3, 3, 1), isFalse);
        if (!next.contains(0)) continue;
        final move = computerMove(next, 3, Difficulty.hard, Random(7))!;
        next[move] = 2;
        if (lineWin(next, 3, 3, 2) || !next.contains(0)) continue;
        explore(next);
      }
    }

    explore(List.filled(9, 0));
  });
  test('Every game has three nonempty tutorial steps', () {
    expect(tutorialSteps.length, games.length);
    for (final steps in tutorialSteps) {
      expect(steps.length, 3);
      expect(steps.every((s) => s.length > 10), isTrue);
    }
  });
  testWidgets(
    'Solo Tic Tac Toe makes a legal computer turn and ignores a human bot-side tap',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchOptions(
              computer: true,
              difficulty: Difficulty.hard,
              child: PuzzleGame(
                id: 19,
                names: const ['You', 'Computer'],
                onFinish: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).at(0));
      await tester.pump();
      await tester.tap(find.byType(InkWell).at(1));
      await tester.pump();
      expect(find.text('✕'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('○'), findsOneWidget);
      expect(find.text('✕'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Computer paddle moves toward ball while human cannot control it',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchOptions(
              computer: true,
              child: ActionGame(id: 5, haptics: false, onFinish: (_) {}),
            ),
          ),
        ),
      );
      final finder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is ArenaPainter,
      );
      for (var i = 0; i < 130; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      final painter =
          tester.widget<CustomPaint>(finder).painter! as ArenaPainter;
      expect(painter.players[1].dy, .13);
      expect(painter.players[1].dx, isNot(.5));
      final rect = tester.getRect(finder);
      final before = painter.players[1].dx;
      final finger = await tester.startGesture(
        Offset(rect.center.dx, rect.top + rect.height * .13),
      );
      await finger.moveBy(const Offset(-100, 0));
      await finger.up();
      final after =
          (tester.widget<CustomPaint>(finder).painter! as ArenaPainter)
              .players[1]
              .dx;
      expect(after, before);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Party builder disables empty categories and returns selected setup',
    (tester) async {
      PartyPlan? plan;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: FilledButton(
                    onPressed: () async {
                      plan = await Navigator.push<PartyPlan>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PartyBuilder(players: 2),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4 players'));
      await tester.tap(find.text('3 rounds'));
      for (final category in games.map((g) => g.category).toSet()) {
        await tester.ensureVisible(find.text(category));
        await tester.tap(find.text(category));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Start party'));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Start party'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Words'));
      await tester.tap(find.text('Words'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start party'));
      await tester.tap(find.text('Start party'));
      await tester.pumpAndSettle();
      expect(plan!.players, 4);
      expect(plan!.rounds, 3);
      expect(plan!.categories, {'Words'});
    },
  );
  Future<void> openMatch(
    WidgetTester tester,
    int id, {
    Future<void> Function(MatchRecord)? onResult,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await PartyData.instance.initialize();
    PartyData.instance.seen.add(id);
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          id: id,
          names: const ['A', 'B'],
          haptics: false,
          onResult: onResult,
        ),
      ),
    );
    await tester.ensureVisible(find.text('Let’s play'));
    await tester.tap(find.text('Let’s play'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Rematch resets the board and records each completed match exactly once',
    (tester) async {
      final results = <MatchRecord>[];
      await openMatch(
        tester,
        19,
        onResult: (r) async {
          results.add(r);
        },
      );
      final game = tester.widget<PuzzleGame>(find.byType(PuzzleGame));
      game.onFinish(0);
      game.onFinish(0);
      await tester.pumpAndSettle();
      expect(results.length, 1);
      expect(find.text('A wins!'), findsOneWidget);
      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleGame), findsOneWidget);
      expect(find.text('✕'), findsNothing);
      tester.widget<PuzzleGame>(find.byType(PuzzleGame)).onFinish(1);
      await tester.pumpAndSettle();
      expect(results.map((r) => r.winner), [0, 1]);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Timed challenges pause in background and resolve using live scores',
    (tester) async {
      await PartyData.instance.initialize();
      PartyData.instance.roundSeconds = 60;
      final results = <MatchRecord>[];
      await openMatch(
        tester,
        26,
        onResult: (r) async {
          results.add(r);
        },
      );
      (tester.state(find.byType(MatchScreen)) as dynamic)
          .didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      expect(results, isEmpty);
      (tester.state(find.byType(MatchScreen)) as dynamic)
          .didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      expect(results.single.winner, -1);
      expect(results.single.seconds, 60);
      await tester.pumpWidget(const SizedBox());
      PartyData.instance.roundSeconds = 0;
    },
  );
  testWidgets('Tutorial is accessible with reduced motion and can be skipped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const GameTutorial(id: 5),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    await tester.tap(find.text('Next step'));
    await tester.pumpAndSettle();
    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Shareable scorecard is a valid PNG for four players', (
    tester,
  ) async {
    final bytes = await tester.runAsync(
      () => scorecardImage(
        'Party results',
        ['A', 'B', 'C', 'D'],
        [3, 2, 1, 0],
        awards: {0: 'Party champion'},
      ),
    );
    expect(bytes!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 900);
      expect(frame.image.height, 710);
      frame.image.dispose();
      codec.dispose();
    });
  });
  testWidgets(
    'First play opens the tutorial and skipping starts the real game',
    (tester) async {
      await PartyData.instance.initialize();
      PartyData.instance.seen.remove(19);
      await tester.pumpWidget(
        MaterialApp(
          home: MatchScreen(id: 19, names: const ['A', 'B'], haptics: false),
        ),
      );
      await tester.ensureVisible(find.text('Let’s play'));
      await tester.tap(find.text('Let’s play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GameTutorial), findsOneWidget);
      await tester.ensureVisible(find.text('Skip tutorial'));
      await tester.tap(find.text('Skip tutorial'));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleGame), findsOneWidget);
      expect(PartyData.instance.seen.contains(19), isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Favorites, recent games and search expose the intended library',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await PartyData.instance.initialize();
      PartyData.instance.favorites.clear();
      await PartyData.instance.toggleFavorite(19);
      await PartyData.instance.opened(5);
      await tester.pumpWidget(const JoyApp());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Favorites'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Favorites'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tic Tac Toe'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tic Tac Toe'), findsOneWidget);
      expect(find.text('Neon Rally'), findsNothing);
      await tester.ensureVisible(find.text('Recent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Ping Pong'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ping Pong'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'does not exist');
      await tester.pumpAndSettle();
      expect(find.textContaining('No games here yet'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Rock Paper Scissors computer chooses without a second human', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchOptions(
            computer: true,
            child: BrainGame(
              id: 29,
              names: const ['You', 'Computer'],
              onFinish: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('✊ Rock'));
    await tester.pump();
    expect(find.text('Computer is choosing…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750));
    expect(
      find.textContaining('wins this hand').evaluate().isNotEmpty ||
          find.text('Draw').evaluate().isNotEmpty,
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpWidget(const SizedBox());
  });
}
