import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/games/game_stage.dart';

Widget stage(List<int> scores) => MaterialApp(
  home: Scaffold(
    body: GameStage(
      names: const ['A', 'B'],
      scores: scores,
      turn: 0,
      message: 'go',
      child: const SizedBox(width: 100, height: 100),
    ),
  ),
);

void main() {
  testWidgets('A score going up shows +N, then settles', (tester) async {
    await tester.pumpWidget(stage([0, 0]));
    expect(find.text('+1'), findsNothing);
    await tester.pumpWidget(stage([1, 0]));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('+1'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('+1'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
