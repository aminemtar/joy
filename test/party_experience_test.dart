import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joy/main.dart';
import 'package:joy/players.dart';
import 'package:joy/splash.dart';
import 'package:joy/game_factory.dart';
import 'package:joy/games/action.dart';
import 'package:joy/games/game_stage.dart';

void main() {
  test('leadingPlayer picks a clear leader and reports ties as -1', () {
    expect(leadingPlayer([0, 1]), 1);
    expect(leadingPlayer([2, 2]), -1);
    expect(leadingPlayer([3, 1]), 0);
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
  testWidgets('The lobby is strictly two players', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JoyApp());
    await tester.pumpAndSettle();
    expect(find.text('2 players'), findsOneWidget);
    expect(find.text('3 players'), findsNothing);
    expect(find.text('4 players'), findsNothing);
    expect(find.text('VS'), findsOneWidget);
    expect(find.text('Blue'), findsWidgets);
    expect(find.text('Coral'), findsWidgets);
    expect(find.text('Amber'), findsNothing);
    expect(playerCount, 2);
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
  for (final id in [30, 27, 20, 31]) {
    testWidgets('Game $id renders a fixed two-player viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildGame(id: id, names: const ['A', 'B'], onFinish: (_) {}),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final stage = tester.widget<GameStage>(find.byType(GameStage));
      expect(stage.names.length, 2);
      expect(stage.scores.length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
  testWidgets('Crossword turns alternate between the two players', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildGame(
            id: 30,
            names: const ['A', 'B'],
            onFinish: (_) {},
          ),
        ),
      ),
    );
    for (final expected in [1, 0, 1]) {
      await tester.tap(find.text('Check word'));
      await tester.pump();
      expect(tester.widget<GameStage>(find.byType(GameStage)).turn, expected);
    }
  });
  testWidgets('The second reaction pad scores for the second player', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildGame(id: 27, names: const ['A', 'B'], onFinish: (_) {}),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.widgetWithText(FilledButton, 'B'));
    await tester.pump();
    expect(tester.widget<GameStage>(find.byType(GameStage)).scores, [0, 1]);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
