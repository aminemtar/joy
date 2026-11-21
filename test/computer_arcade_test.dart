import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/games/arcade.dart';
import 'package:joy/party_data.dart';

Widget host(int id, ValueChanged<int> onFinish, {Difficulty? level}) =>
    MaterialApp(
      home: Scaffold(
        body: MatchOptions(
          computer: true,
          difficulty: level ?? Difficulty.normal,
          child: ArcadeGame(
            id: id,
            names: const ['You', 'Computer'],
            onFinish: onFinish,
          ),
        ),
      ),
    );

Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 33));
  }
}

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Traffic Control: the computer switches its own lights', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(host(3, (_) {}));
    await frames(tester, 100);
    expect(find.text('Computer'), findsWidgets);
    final seen = <String>{};
    for (var i = 0; i < 900; i++) {
      await tester.pump(const Duration(milliseconds: 33));
      final label = tester.widgetList<Text>(find.textContaining('open •'));
      if (label.isNotEmpty) seen.add(label.first.data ?? '');
    }
    expect(seen.length, 2, reason: 'the top intersection changed phase');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Traffic Control: the computer cannot be switched by touch', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(host(3, (_) {}));
    await frames(tester, 100);
    final buttons = tester.widgetList<FilledButton>(
      find.bySubtype<FilledButton>(),
    );
    expect(buttons.first.onPressed, isNull);
    expect(buttons.last.onPressed, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Stack Tower: the computer drops its block on its turn', (
    tester,
  ) async {
    tall(tester);
    int? result;
    await tester.pumpWidget(host(4, (p) => result = p));
    await frames(tester, 100);
    expect(find.text('You — drop block'), findsOneWidget);
    await tester.tap(find.text('You — drop block'));
    await tester.pump();
    expect(find.text('Computer — drop block'), findsOneWidget);
    final computerButton = tester.widget<FilledButton>(
      find.bySubtype<FilledButton>(),
    );
    expect(computerButton.onPressed, isNull);
    await frames(tester, 400);
    final handedBack = find.text('You — drop block').evaluate().isNotEmpty;
    expect(handedBack || result != null, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Penalty: the computer takes its shot after the human', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(host(7, (_) {}));
    await frames(tester, 100);
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
    final shooter = await tester.startGesture(
      Offset(rect.left + rect.width * .5, rect.top + rect.height * .85),
    );
    await shooter.moveTo(
      Offset(rect.left + rect.width * .8, rect.top + rect.height * .1),
    );
    await shooter.up();
    await frames(tester, 400);
    expect(find.textContaining('Shot 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Gap Jumpers: the computer clears a gap the idle human falls in', (
    tester,
  ) async {
    tall(tester);
    int? result;
    await tester.pumpWidget(host(14, (p) => result = p, level: Difficulty.hard));
    await frames(tester, 100);
    expect(find.text('Computer'), findsWidgets);
    await frames(tester, 200);
    expect(result, 1, reason: 'the human never jumped, the computer did');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
