import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/games/brain.dart';
import 'package:joy/games/flip_card.dart';
import 'package:joy/games/puzzle.dart';
import 'package:joy/party_data.dart';

const names = ['Ana', 'Computer'];

Widget host(Widget game, {Difficulty level = Difficulty.hard}) => MaterialApp(
  home: Scaffold(
    body: MatchOptions(computer: true, difficulty: level, child: game),
  ),
);

Widget puzzle(int id) => PuzzleGame(id: id, names: names, onFinish: (_) {});
Widget brain(int id) => BrainGame(id: id, names: names, onFinish: (_) {});

/// Pumps in small steps until [done] is true, failing after [limit].
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration limit = const Duration(seconds: 12),
}) async {
  var waited = Duration.zero;
  while (!done()) {
    if (waited >= limit) fail('The computer did not act within $limit');
    await tester.pump(const Duration(milliseconds: 100));
    waited += const Duration(milliseconds: 100);
  }
}

Future<void> leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 4));
}

bool shown(String text) => find.text(text).evaluate().isNotEmpty;

void main() {
  testWidgets('Sliding Puzzle: the computer slides a tile on its turn', (
    tester,
  ) async {
    await tester.pumpWidget(host(puzzle(15)));
    for (final tile in '12345678'.split('')) {
      await tester.tap(find.text(tile));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Computer is thinking'), findsOneWidget);
    await pumpUntil(tester, () => shown('Ana’s turn'));
    expect(tester.takeException(), isNull);
    await leave(tester);
  });

  testWidgets('Maze Race: the computer steps toward its goal', (tester) async {
    await tester.pumpWidget(host(puzzle(17)));
    final before = tester.getCenter(find.text('🔴'));
    await tester.tap(find.byType(InkWell).at(1));
    await tester.pump(const Duration(milliseconds: 100));
    await pumpUntil(tester, () => shown('Ana’s turn'));
    expect(tester.getCenter(find.text('🔴')), isNot(before));
    expect(tester.takeException(), isNull);
    await leave(tester);
  });

  testWidgets('Picture Pairs: the computer flips cards after a miss', (
    tester,
  ) async {
    await tester.pumpWidget(host(puzzle(20)));
    List<FlipMatchCard> cards() =>
        tester.widgetList<FlipMatchCard>(find.byType(FlipMatchCard)).toList();
    final all = cards();
    final other = all.indexWhere((c) => c.artId != all[0].artId);
    await tester.tap(find.byKey(const ValueKey('memory-0')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(ValueKey('memory-$other')));
    // The human missed, so the cards turn back and it is the computer's turn.
    await tester.pump(const Duration(milliseconds: 1700));
    expect(cards().where((c) => c.faceUp), isEmpty);
    expect(find.textContaining('Computer is thinking'), findsOneWidget);
    await pumpUntil(tester, () => cards().any((c) => c.faceUp));
    await pumpUntil(tester, () => cards().where((c) => c.faceUp).length >= 2);
    expect(tester.takeException(), isNull);
    await leave(tester);
  });

  testWidgets('Follow the Cup: the computer guesses after its shuffle', (
    tester,
  ) async {
    await tester.pumpWidget(host(brain(24)));
    await pumpUntil(tester, () => shown('Where is the diamond?'));
    await tester.tap(find.text('Cup 1'));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(shown('Computer’s turn'), isTrue);
    final cup = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Cup 1'),
    );
    expect(cup.onPressed, isNull, reason: 'the human cannot press for it');
    await pumpUntil(tester, () => shown('Ana’s turn'));
    expect(tester.takeException(), isNull);
    await leave(tester);
  });

  for (final id in [25, 26]) {
    testWidgets('Game $id: the computer answers on its turn', (tester) async {
      await tester.pumpWidget(host(brain(id)));
      await tester.tap(find.byType(FilledButton).first);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(shown('Computer’s turn'), isTrue);
      final first = tester.widget<FilledButton>(
        find.byType(FilledButton).first,
      );
      expect(first.onPressed, isNull, reason: 'the human cannot press for it');
      await pumpUntil(tester, () => shown('Ana’s turn'));
      expect(tester.takeException(), isNull);
      await leave(tester);
    });
  }

  testWidgets('Reaction Duel: the computer presses after the signal', (
    tester,
  ) async {
    await tester.pumpWidget(host(brain(27)));
    final pad = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Computer'),
    );
    expect(pad.onPressed, isNull, reason: 'the computer pad is not tappable');
    await pumpUntil(tester, () => shown('Computer was faster!'));
    expect(tester.takeException(), isNull);
    await leave(tester);
  });

  testWidgets('Reaction Duel: the human pad still works', (tester) async {
    await tester.pumpWidget(host(brain(27)));
    await tester.tap(find.widgetWithText(FilledButton, 'Ana'));
    await tester.pump();
    expect(find.textContaining('Too early'), findsOneWidget);
    await leave(tester);
  });
}
