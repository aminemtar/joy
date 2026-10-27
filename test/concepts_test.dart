import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/catalog.dart';
import 'package:joy/games/arcade_models.dart';
import 'package:joy/games/strategy_models.dart';
import 'package:joy/games/word_models.dart';
import 'package:joy/games/flip_card.dart';
import 'package:joy/games/puzzle.dart';
import 'package:joy/games/words.dart';
import 'package:joy/games/arcade.dart';
import 'package:joy/games/game_stage.dart';

void main() {
  test('Former reskins no longer use the same action engine', () {
    for (final id in [1, 3, 4, 7, 14, 16]) {
      expect(games[id].family, isNot(Family.action));
    }
    expect(games[30].name, 'Crossword Duel');
    expect(games[31].family, Family.words);
    for (final id in [32, 33, 34, 35]) {
      expect(games[id].family, Family.strategy);
    }
  });
  test('Crosswords have consistent crossings and solved letters persist', () {
    for (final pack in crosswordPacks) {
      final b = CrosswordBoard(pack);
      expect(b.solution.isNotEmpty, true);
      for (var i = 0; i < pack.length; i++) {
        expect(
          b.check(i, {
            for (final cell in pack[i].cells) cell: b.solution[cell]!,
          }),
          true,
        );
      }
      b.confirm(0);
      expect(b.confirmed.length, 7);
      expect(b.confirmed[3 * 7 + 2], pack.first.word[2]);
      expect(b.solved, {0});
    }
  });
  test(
    'Every word-search placement is straight and reproducible across seeds',
    () {
      for (var seed = 0; seed < 50; seed++) {
        final b = WordSearchBoard(Random(seed));
        expect(b.placements.length, 6);
        for (final e in b.placements.entries) {
          expect(b.match(e.value, {}), e.key);
          expect(b.line(e.value.first, e.value.last), e.value);
          expect(b.match(e.value.reversed.toList(), {}), e.key);
          expect(b.match(e.value, {e.key}), isNull);
        }
        expect(b.line(0, 10), isEmpty);
      }
    },
  );
  test('Reversi requires bracketing and flips opposing discs', () {
    final b = ReversiBoard();
    expect(b.legal(1), [9, 16, 19, 26]);
    expect(b.play(0, 1), false);
    expect(b.play(9, 1), true);
    expect(b.cells[15], 1);
    expect(b.cells.where((v) => v == 1).length, 4);
    expect(b.captures(9, 2), isEmpty);
  });
  test('Dots and boxes grants a point only when all four edges close', () {
    final b = DotsBoard();
    final edges = b.boundaries(0);
    for (final e in edges.take(3)) {
      expect(b.play(e, 1), 0);
    }
    expect(b.play(edges.last, 2), 1);
    expect(b.owners[0], 2);
    expect(b.play(edges.last, 1), -1);
  });
  test('Battleship places seven hull cells and sinks only after every hit', () {
    for (var seed = 0; seed < 50; seed++) {
      final b = FleetBoard(Random(seed));
      expect(b.ships.length, 7);
      expect(b.sunk, false);
      for (final cell in b.ships) {
        expect(b.fire(cell), true);
      }
      expect(b.sunk, true);
    }
  });
  test('Code feedback does not overcount duplicate colors', () {
    final f = evaluateCode([1, 1, 2, 3], [1, 2, 1, 1]);
    expect(f.exact, 1);
    expect(f.misplaced, 2);
    final repeated = evaluateCode([1, 1, 2, 3], [1, 1, 1, 1]);
    expect(repeated.exact, 2);
    expect(repeated.misplaced, 0);
    expect(evaluateCode([0, 1, 2, 3], [0, 1, 2, 3]).exact, 4);
  });
  test(
    'Minesweeper protects the first reveal and computes adjacent counts',
    () {
      for (var seed = 0; seed < 30; seed++) {
        final b = MineBoard(Random(seed));
        final first = b.mines.first;
        expect(b.reveal(first), greaterThan(0));
        expect(b.mines.contains(first), false);
        expect(b.mines.length, 6);
        for (var i = 0; i < 36; i++) {
          expect(b.clue(i), b.neighbors(i).where(b.mines.contains).length);
        }
        final bomb = b.mines.first;
        expect(b.reveal(bomb), -1);
      }
    },
  );
  test('Tower trims overhang and rejects disconnected blocks', () {
    final b = TowerBoard();
    expect(b.drop(.09, 0), 100);
    expect(b.drop(.2, 1), greaterThan(0));
    expect(b.layers.last.width, lessThan(.82));
    expect(b.drop(.99, 0), 0);
  });
  test(
    'Traffic collision requires perpendicular cars in the same intersection',
    () {
      expect(
        trafficCollision([TrafficCar(0, 0, .5), TrafficCar(0, 1, .5)], 0),
        true,
      );
      expect(
        trafficCollision([TrafficCar(0, 0, .5), TrafficCar(1, 1, .5)], 0),
        false,
      );
      expect(
        trafficCollision([TrafficCar(0, 0, .5), TrafficCar(0, 1, .3)], 0),
        false,
      );
    },
  );
  testWidgets('Memory card rotates through a real perspective flip', (
    tester,
  ) async {
    var face = false;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (c, set) {
                update = set;
                return SizedBox.square(
                  dimension: 100,
                  child: FlipMatchCard(
                    faceUp: face,
                    matched: false,
                    enabled: true,
                    artId: 0,
                    index: 0,
                    onTap: () => update(() => face = !face),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FlipMatchCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    final transform = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(FlipMatchCard),
            matching: find.byType(Transform),
          ),
        )
        .firstWhere((t) => t.transform.entry(3, 2) != 0);
    expect(transform.transform.entry(0, 0), allOf(greaterThan(0), lessThan(1)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Crossword letter entry awards a solved clue and changes turns', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordsGame(id: 30, names: const ['A', 'B'], onFinish: (_) {}),
        ),
      ),
    );
    final pack = crosswordPacks.firstWhere(
      (p) => find.text('1. ${p.first.clue} (7)').evaluate().isNotEmpty,
    );
    for (final letter in pack.first.word.split('')) {
      final key = find.widgetWithText(FilledButton, letter);
      await tester.ensureVisible(key);
      await tester.pumpAndSettle();
      await tester.tap(key);
      await tester.pump();
    }
    await tester.ensureVisible(find.text('Check word'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check word'));
    await tester.pump();
    final stage = tester.widget<GameStage>(find.byType(GameStage));
    expect(stage.scores, [7, 0]);
    expect(stage.turn, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Picture Pairs locks extra taps until mismatched flips finish', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleGame(id: 20, names: const ['A', 'B'], onFinish: (_) {}),
        ),
      ),
    );
    final cards = find.byType(FlipMatchCard);
    await tester.tap(cards.at(0));
    await tester.pump();
    await tester.tap(cards.at(1));
    await tester.pump();
    expect(
      tester.widgetList<FlipMatchCard>(cards).every((c) => !c.enabled),
      true,
    );
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(tester.widgetList<FlipMatchCard>(cards).any((c) => c.enabled), true);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Penalty shootout accepts a flick while the rival moves the keeper',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArcadeGame(id: 7, names: const ['A', 'B'], onFinish: (_) {}),
          ),
        ),
      );
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      final field =
          find
              .byWidgetPredicate(
                (w) =>
                    w is Listener &&
                    w.onPointerDown != null &&
                    w.onPointerMove != null,
              )
              .last;
      final rect = tester.getRect(field);
      final keeper = await tester.startGesture(
        Offset(rect.left + rect.width * .2, rect.top + rect.height * .16),
        pointer: 1,
      );
      final shooter = await tester.startGesture(
        Offset(rect.left + rect.width * .5, rect.top + rect.height * .85),
        pointer: 2,
      );
      await shooter.moveTo(
        Offset(rect.left + rect.width * .8, rect.top + rect.height * .1),
      );
      await shooter.up();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      await keeper.up();
      expect(tester.widget<GameStage>(find.byType(GameStage)).scores, [1, 0]);
      expect(tester.takeException(), isNull);
    },
  );
}
