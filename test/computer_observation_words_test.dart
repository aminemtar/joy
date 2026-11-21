import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/games/observation.dart';
import 'package:joy/games/words.dart';
import 'package:joy/party_data.dart';

const names = ['You', 'Computer'];

Future<void> open(WidgetTester tester, Widget game) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MatchOptions(
          computer: true,
          difficulty: Difficulty.hard,
          child: game,
        ),
      ),
    ),
  );
  await tester.pump();
}

bool get botPlaying => find.text('Computer is playing').evaluate().isNotEmpty;

Future<bool> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxMs = 30000,
}) async {
  var elapsed = 0;
  while (!condition() && elapsed < maxMs) {
    await tester.pump(const Duration(milliseconds: 100));
    elapsed += 100;
  }
  return condition();
}

/// Waits for the computer's turn to start, then for it to act and hand the
/// turn back. If the computer did nothing, its turn would never end.
Future<void> expectBotPlaysATurn(WidgetTester tester) async {
  expect(await pumpUntil(tester, () => botPlaying), isTrue, reason: 'bot turn');
  expect(
    await pumpUntil(tester, () => !botPlaying),
    isTrue,
    reason: 'the computer acted and passed the turn back',
  );
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('Spot the Difference: the computer answers its turn', (
    tester,
  ) async {
    await open(
      tester,
      ObservationGame(id: 21, names: names, onFinish: (_) {}),
    );
    await tester.tap(find.byType(InkWell).at(16), warnIfMissed: false);
    await tester.pump();
    await expectBotPlaysATurn(tester);
  });

  testWidgets('Hidden Objects: the computer finds an object', (tester) async {
    await open(
      tester,
      ObservationGame(id: 22, names: names, onFinish: (_) {}),
    );
    await tester.tap(find.byType(InkWell).first, warnIfMissed: false);
    await tester.pump();
    await expectBotPlaysATurn(tester);
  });

  testWidgets('Simon Echo: the computer repeats the pattern', (tester) async {
    await open(
      tester,
      ObservationGame(id: 23, names: names, onFinish: (_) {}),
    );
    expect(
      await pumpUntil(
        tester,
        () => find.textContaining('Repeat all').evaluate().isNotEmpty,
      ),
      isTrue,
    );
    for (var i = 0; i < 6 && !botPlaying; i++) {
      final resolved =
          find.text('Correct!').evaluate().isNotEmpty ||
          find.textContaining('Miss').evaluate().isNotEmpty;
      if (resolved) break;
      await tester.tap(find.byType(InkWell).first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 250));
    }
    await expectBotPlaysATurn(tester);
  });

  testWidgets('Word Scramble: the computer builds a word', (tester) async {
    await open(tester, WordsGame(id: 28, names: names, onFinish: (_) {}));
    final submit = find.widgetWithText(FilledButton, 'Submit word');
    for (var i = 0; i < 10; i++) {
      if (tester.widget<FilledButton>(submit).onPressed != null) break;
      await tester.tap(find.byType(FilledButton).at(i), warnIfMissed: false);
      await tester.pump();
    }
    await tester.tap(submit, warnIfMissed: false);
    await tester.pump();
    await expectBotPlaysATurn(tester);
  });

  testWidgets('Crossword Duel: the computer fills in a word', (tester) async {
    await open(tester, WordsGame(id: 30, names: names, onFinish: (_) {}));
    await tester.tap(find.text('Check word'), warnIfMissed: false);
    await tester.pump();
    await expectBotPlaysATurn(tester);
  });

  testWidgets('Word Search: the computer drags across a line', (tester) async {
    await open(tester, WordsGame(id: 31, names: names, onFinish: (_) {}));
    final board = tester.getRect(find.byType(AspectRatio).first);
    await tester.dragFrom(
      board.topLeft + const Offset(20, 20),
      const Offset(80, 0),
    );
    await tester.pump();
    await expectBotPlaysATurn(tester);
  });

  testWidgets('Against a person there is no computer pill', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ObservationGame(id: 21, names: names, onFinish: (_) {}),
        ),
      ),
    );
    await tester.tap(find.byType(InkWell).at(16), warnIfMissed: false);
    await tester.pump(const Duration(seconds: 2));
    expect(botPlaying, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
