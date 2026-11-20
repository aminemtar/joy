import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/games/action.dart';
import 'package:joy/games/arrow_pad.dart';

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

/// Starts a game and waits out the three-second countdown.
Future<void> start(WidgetTester tester, int id) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ActionGame(id: id, haptics: false, onFinish: (_) {}),
      ),
    ),
  );
  await frames(tester, 105);
}

void main() {
  testWidgets('ArrowPad reports a press and a release for each button', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArrowPad(
            player: 0,
            color: Colors.blue,
            onPress: (d) => log.add('down ${d.x},${d.y}'),
            onRelease: (d) => log.add('up ${d.x},${d.y}'),
          ),
        ),
      ),
    );
    final finger = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('pad-0-left'))),
    );
    expect(log, ['down -1,0']);
    await finger.up();
    expect(log, ['down -1,0', 'up -1,0']);
    await tester.tap(find.byKey(const ValueKey('pad-0-down')));
    expect(log.sublist(2), ['down 0,1', 'up 0,1']);
  });

  testWidgets('Sumo: the bottom player moves with the arrow keys', (
    tester,
  ) async {
    await start(tester, 10);
    final players = painter(tester).players;
    expect(players[0].dx, closeTo(.5, .001));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await frames(tester, 15);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    expect(players[0].dx, lessThan(.42));
    expect(players[1].dx, closeTo(.5, .001), reason: 'the rival stays put');
    await frames(tester, 30);
    final stopped = players[0].dx;
    await frames(tester, 10);
    expect(players[0].dx, closeTo(stopped, .01), reason: 'it glides to a stop');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Sumo: the top player uses WASD, in screen directions', (
    tester,
  ) async {
    await start(tester, 10);
    final players = painter(tester).players;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
    await frames(tester, 15);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    expect(players[1].dx, greaterThan(.58));
    expect(players[0].dx, closeTo(.5, .001));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Sumo: the top pad is rotated, so its left arrow moves right', (
    tester,
  ) async {
    await start(tester, 10);
    final players = painter(tester).players;
    final finger = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('pad-1-left'))),
    );
    await frames(tester, 15);
    await finger.up();
    expect(players[1].dx, greaterThan(.58));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Sumo: dragging on the ring no longer moves a wrestler', (
    tester,
  ) async {
    await start(tester, 10);
    final players = painter(tester).players;
    final rect = tester.getRect(arena);
    final finger = await tester.startGesture(
      Offset(rect.center.dx, rect.top + rect.height * .8),
    );
    await finger.moveBy(const Offset(-120, 0));
    await frames(tester, 15);
    await finger.up();
    expect(players[0].dx, closeTo(.5, .001));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Sumo: both wrestlers leaving together is a draw', (
    tester,
  ) async {
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionGame(id: 10, haptics: false, onFinish: (p) => result = p),
        ),
      ),
    );
    await frames(tester, 105);
    final players = painter(tester).players;
    players[0] = const Offset(.5, .96);
    players[1] = const Offset(.5, .04);
    await frames(tester, 2);
    expect(result, -1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Snake: the top pad turns the snake the way its arrow points', (
    tester,
  ) async {
    await start(tester, 12);
    final snakes = painter(tester).snakes;
    final startY = snakes[1].first.y;
    // The top pad is rotated, so its "up" arrow points down the screen.
    await tester.tap(find.byKey(const ValueKey('pad-1-up')));
    await frames(tester, 12);
    expect(snakes[1].first.y, greaterThan(startY));
    await tester.pumpWidget(const SizedBox());
  });
}
