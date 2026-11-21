import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/games/puzzle.dart';
import 'package:joy/main.dart';
import 'package:joy/party_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Best of 3 records only the finished series', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await PartyData.instance.initialize();
    PartyData.instance.seen.add(19);
    final results = <MatchRecord>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          id: 19,
          names: const ['A', 'B'],
          haptics: false,
          onResult: (r) async => results.add(r),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Best of 3'));
    await tester.tap(find.text('Best of 3'));
    await tester.pump();
    await tester.ensureVisible(find.text('Let’s play'));
    await tester.tap(find.text('Let’s play'));
    await tester.pumpAndSettle();

    tester.widget<PuzzleGame>(find.byType(PuzzleGame)).onFinish(0);
    await tester.pumpAndSettle();
    expect(find.text('A takes the round'), findsOneWidget);
    expect(results, isEmpty);
    await tester.tap(find.text('Next round'));
    await tester.pumpAndSettle();

    tester.widget<PuzzleGame>(find.byType(PuzzleGame)).onFinish(0);
    await tester.pumpAndSettle();
    expect(results, hasLength(1));
    expect(results.single.winner, 0);
    expect(find.text('A wins the series 2 – 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
