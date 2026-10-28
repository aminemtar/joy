import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joy/main.dart';
import 'package:joy/players.dart';
import 'package:joy/party_league.dart';
import 'package:joy/splash.dart';
import 'package:joy/game_factory.dart';
import 'package:joy/games/action.dart';
import 'package:joy/games/game_stage.dart';

void main() {
  test('Three- and four-player leagues schedule every unique pair', () {
    for (final n in [3, 4]) {
      final league = PartyLeague(n);
      expect(league.fixtures.length, n == 3 ? 3 : 6);
      final pairs =
          league.fixtures.map((f) => '${f.first}:${f.second}').toSet();
      expect(pairs.length, league.fixtures.length);
      for (var i = 0; i < league.fixtures.length; i++) {
        league.record(i, 0);
      }
      expect(league.winner, 0);
      expect(league.points[0], 3 * (n - 1));
      expect(() => league.record(0, 0), throwsStateError);
    }
  });
  test('League draws and multi-way ties are handled', () {
    final league = PartyLeague(4);
    for (var i = 0; i < 6; i++) {
      league.record(i, -1);
    }
    expect(league.points, [3, 3, 3, 3]);
    expect(league.winner, -1);
    expect(leadingPlayer([0, 1, 2, 2]), -1);
    expect(leadingPlayer([0, 1, 2, 3]), 3);
  });
  testWidgets('Splash completes once, including an early skip', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(home: JoySplash(onFinished: () => finished++)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Let’s play'));
    await tester.pump(const Duration(seconds: 2));
    expect(finished, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Selected player count persists and duel games open a party league',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const JoyApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('3 players'));
      await tester.tap(find.text('3 players'));
      await tester.pumpAndSettle();
      expect((await SharedPreferences.getInstance()).getInt('playerCount'), 3);
      await tester.scrollUntilVisible(
        find.text('Neon Rally'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Neon Rally'));
      await tester.pumpAndSettle();
      expect(find.text('3-player league'), findsOneWidget);
      expect(find.text('Start next match'), findsOneWidget);
      expect(find.text('Amber'), findsOneWidget);
    },
  );
  testWidgets('Round-robin UI records results and includes every player', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PartyLeagueScreen(
          gameId: 5,
          names: const ['A', 'B', 'C'],
          duelBuilder:
              (pair) => Builder(
                builder:
                    (c) => Scaffold(
                      body: FilledButton(
                        onPressed: () => Navigator.pop(c, 0),
                        child: Text('Winner ${pair[0]}'),
                      ),
                    ),
              ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Start next match'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Winner '));
      await tester.pumpAndSettle();
    }
    expect(find.text('A wins the league!'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
  testWidgets(
    'Ping-pong paddles stay fixed vertically and do not drift under a held finger',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionGame(id: 5, haptics: false, onFinish: (_) {}),
          ),
        ),
      );
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      final arena = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is ArenaPainter,
      );
      ArenaPainter painter() =>
          tester.widget<CustomPaint>(arena).painter! as ArenaPainter;
      final rect = tester.getRect(arena);
      final lower = await tester.startGesture(
        Offset(rect.center.dx, rect.top + rect.height * .8),
        pointer: 1,
      );
      await lower.moveBy(const Offset(50, -60));
      await tester.pump(const Duration(milliseconds: 33));
      final position = painter().players[0];
      expect(position.dy, .87);
      for (var i = 0; i < 45; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      expect(painter().players[0], position);
      final upper = await tester.startGesture(
        Offset(rect.center.dx, rect.top + rect.height * .2),
        pointer: 2,
      );
      await upper.moveBy(const Offset(-45, 80));
      await tester.pump(const Duration(milliseconds: 33));
      expect(painter().players[0], position);
      expect(painter().players[1].dy, .13);
      await lower.up();
      await upper.up();
      expect(tester.takeException(), isNull);
    },
  );
  for (final n in [3, 4]) {
    for (final id in groupTurnGames) {
      testWidgets(
        '$n-player shared turns render a fixed viewport for game $id',
        (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: buildGame(
                  id: id,
                  names: ['A', 'B', 'C', 'D'].take(n).toList(),
                  onFinish: (_) {},
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byType(SingleChildScrollView), findsNothing);
          final stage = tester.widget<GameStage>(find.byType(GameStage));
          expect(stage.names.length, n);
          expect(stage.scores.length, n);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 5));
        },
      );
    }
  }
  testWidgets('Crossword turns rotate through all four players', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildGame(
            id: 30,
            names: const ['A', 'B', 'C', 'D'],
            onFinish: (_) {},
          ),
        ),
      ),
    );
    for (final expected in [1, 2, 3, 0]) {
      await tester.tap(find.text('Check word'));
      await tester.pump();
      expect(tester.widget<GameStage>(find.byType(GameStage)).turn, expected);
    }
  });
  testWidgets('Fourth reaction pad scores for the fourth player', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildGame(
            id: 27,
            names: const ['A', 'B', 'C', 'D'],
            onFinish: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.widgetWithText(FilledButton, 'D'));
    await tester.pump();
    expect(tester.widget<GameStage>(find.byType(GameStage)).scores, [
      0,
      0,
      0,
      1,
    ]);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
