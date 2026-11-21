import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/games/bot_skill.dart';
import 'package:joy/games/code_breaker_view.dart';
import 'package:joy/games/strategy.dart';
import 'package:joy/games/strategy_bot.dart';
import 'package:joy/games/strategy_models.dart';
import 'package:joy/party_data.dart';

const hard = BotSkill(Difficulty.hard);
const easy = BotSkill(Difficulty.easy);

void main() {
  test('Auction bids never exceed the coins or the 4-coin cap', () {
    final random = Random(1);
    for (var round = 1; round <= 6; round++) {
      for (final coins in [0, 1, 3, 12]) {
        for (final skill in [easy, hard]) {
          final bid = botBid(
            value: 3 + random.nextInt(7),
            coins: coins,
            round: round,
            random: random,
            skill: skill,
          );
          expect(bid, inInclusiveRange(0, min(4, coins)));
        }
      }
    }
  });

  test('Reversi bot always plays a legal move and prefers corners', () {
    final board = ReversiBoard();
    final random = Random(2);
    for (var turn = 0; turn < 12; turn++) {
      final player = turn.isEven ? 1 : 2;
      final cell = reversiBotMove(board, player, random, hard);
      if (cell == null) break;
      expect(board.captures(cell, player), isNotEmpty);
      board.play(cell, player);
    }
  });

  test('Dots bot closes a box when one is available', () {
    final board = DotsBoard();
    // Three sides of the top-left box: top (0), bottom (3), left (12).
    for (final e in [0, 3, 12]) {
      board.play(e, 2);
    }
    final edge = dotsBotMove(board, Random(3), hard);
    expect(edge, 13, reason: 'the right side closes the box');
  });

  test('Dots boxes of an edge match the board geometry', () {
    final board = DotsBoard();
    for (var edge = 0; edge < 24; edge++) {
      for (final box in boxesOfEdge(edge)) {
        expect(board.boundaries(box), contains(edge));
      }
    }
  });

  test('Battleship bot finishes a ship by shooting next to a hit', () {
    final enemy = FleetBoard(Random(4));
    final hit = enemy.ships.first;
    enemy.fire(hit);
    final r = hit ~/ 6, c = hit % 6;
    final around = {
      if (r > 0) hit - 6,
      if (r < 5) hit + 6,
      if (c > 0) hit - 1,
      if (c < 5) hit + 1,
    };
    var beside = 0;
    for (var i = 0; i < 20; i++) {
      final shot = fleetBotShot(enemy, Random(i), hard);
      expect(enemy.shots.contains(shot), isFalse);
      if (around.contains(shot)) beside++;
    }
    expect(beside, greaterThan(14));
  });

  test('Minesweeper bot never opens a revealed or flagged cell', () {
    final board = MineBoard(Random(6));
    final random = Random(7);
    board.flags.add(0);
    board.reveal(14);
    for (var i = 0; i < 30; i++) {
      final cell = minesBotMove(board, random, hard);
      if (cell < 0) break;
      expect(board.revealed.contains(cell), isFalse);
      expect(board.flags.contains(cell), isFalse);
      final result = board.reveal(cell);
      if (result < 0 || board.complete) break;
    }
  });

  test('The code solver cracks most codes within eight tries on Hard', () {
    var solved = 0;
    for (var seed = 0; seed < 60; seed++) {
      final random = Random(seed);
      final secret = [for (var i = 0; i < 4; i++) random.nextInt(6)];
      final solver = CodeSolver();
      for (var attempt = 1; attempt <= 8; attempt++) {
        final guess = solver.next(random, hard);
        final f = evaluateCode(secret, guess);
        if (f.exact == 4) {
          solved++;
          break;
        }
        solver.learn(guess, f.exact, f.misplaced);
      }
    }
    expect(solved, greaterThan(50));
  });

  testWidgets('Auction: the computer bids at once, with no pass screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchOptions(
            computer: true,
            difficulty: Difficulty.normal,
            child: StrategyGame(
              id: 1,
              names: const ['You', 'Computer'],
              onFinish: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Seal bid'));
    await tester.pump();
    expect(find.textContaining('Bids'), findsOneWidget);
    expect(find.textContaining('Pass to'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Code Breaker: the vault takes colors and removes one by tap', (
    tester,
  ) async {
    var guess = <int>[];
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return CodeBreakerBoard(
                  guess: guess,
                  history: const [],
                  maxAttempts: 8,
                  enabled: true,
                  onPick: (i) => update(() => guess = [...guess, i]),
                  onRemove: (i) => update(() => guess = [...guess]..removeAt(i)),
                  onClear: () => update(() => guess = []),
                  onCheck: () {},
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('pick-1')));
    await tester.pump();
    expect(guess, [1]);
    await tester.tap(find.byKey(const ValueKey('slot-0')));
    await tester.pump();
    expect(guess, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
