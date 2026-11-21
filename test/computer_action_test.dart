import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/games/action.dart';
import 'package:joy/party_data.dart';

Finder get arena => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is ArenaPainter,
);

ArenaPainter painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(arena).painter! as ArenaPainter;

Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 33));
  }
}

Future<void> startVsComputer(WidgetTester tester, int id) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MatchOptions(
          computer: true,
          difficulty: Difficulty.hard,
          child: ActionGame(id: id, haptics: false, onFinish: (_) {}),
        ),
      ),
    ),
  );
}

void main() {
  // Games where the computer's piece moves on its own.
  for (final id in [0, 2, 6, 10, 11, 13]) {
    testWidgets('Game $id: the computer moves its own piece', (tester) async {
      await startVsComputer(tester, id);
      await frames(tester, 105);
      final start = painter(tester).players[1];
      await frames(tester, 300);
      expect(painter(tester).players[1], isNot(start));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  // Games where it acts without a piece to move (shots, snake, strokes).
  for (final id in [8, 9, 12]) {
    testWidgets('Game $id: a match against the computer runs cleanly', (
      tester,
    ) async {
      await startVsComputer(tester, id);
      await frames(tester, 600);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Sumo: the top arrow pad is not offered against the computer', (
    tester,
  ) async {
    await startVsComputer(tester, 10);
    await frames(tester, 105);
    expect(find.byKey(const ValueKey('pad-0-left')), findsOneWidget);
    expect(find.byKey(const ValueKey('pad-1-left')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
