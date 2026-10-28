import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joy/catalog.dart';
import 'package:joy/main.dart';
import 'package:joy/games/puzzle.dart';
import 'package:joy/game_factory.dart';
import 'package:joy/games/action.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Bundled artwork contains thirty equal square tiles', () async {
    final bytes = await rootBundle.load('assets/art/game_atlas.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    expect(image.width % 5, 0);
    expect(image.height % 6, 0);
    expect(image.width ~/ 5, image.height ~/ 6);
    image.dispose();
    codec.dispose();
  });
  test('Expansion illustrations contain eight square tiles', () async {
    final bytes = await rootBundle.load('assets/art/strategy_atlas.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    expect(image.width / 4, image.height / 2);
    image.dispose();
    codec.dispose();
  });
  test('36 games route to the intended concept engines', () {
    expect(games.length, 36);
    expect(games.map((g) => g.name).toSet().length, 36);
    expect(games.where((g) => g.family == Family.action).length, 10);
  });
  testWidgets('Lobby opens game instructions before gameplay', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JoyApp());
    await tester.pumpAndSettle();
    expect(find.text('JOY'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Neon Rally'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Neon Rally'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neon Rally'));
    await tester.pumpAndSettle();
    expect(find.text('Let’s play'), findsOneWidget);
  });
  testWidgets('Tic tac toe awards a line to player one', (tester) async {
    int? winner;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleGame(
            id: 19,
            names: const ['A', 'B'],
            onFinish: (p) => winner = p,
          ),
        ),
      ),
    );
    final tiles = find.byType(InkWell);
    for (final i in [0, 3, 1, 4, 2]) {
      await tester.tap(tiles.at(i));
      await tester.pump();
    }
    expect(winner, 0);
  });
  testWidgets('Connect four detects a horizontal win', (tester) async {
    int? winner;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleGame(
            id: 18,
            names: const ['A', 'B'],
            onFinish: (p) => winner = p,
          ),
        ),
      ),
    );
    final tiles = find.byType(InkWell);
    for (final i in [0, 6, 1, 6, 2, 5, 3]) {
      await tester.tap(tiles.at(i));
      await tester.pump();
    }
    expect(winner, 0);
  });
  testWidgets('Two simultaneous paddle touches and background pause', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionGame(id: 5, onFinish: (_) {}, haptics: false),
        ),
      ),
    );
    for (var frame = 0; frame < 100; frame++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    final arena = find.byType(Listener).last;
    final bounds = tester.getRect(arena);
    final lower = await tester.startGesture(
      Offset(bounds.center.dx, bounds.top + bounds.height * .82),
      pointer: 1,
    );
    final upper = await tester.startGesture(
      Offset(bounds.center.dx, bounds.top + bounds.height * .18),
      pointer: 2,
    );
    await lower.moveBy(const Offset(80, 0));
    await upper.moveBy(const Offset(-80, 0));
    await tester.pump(const Duration(milliseconds: 33));
    await lower.up();
    await upper.up();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(find.text('Resume'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (var id = 0; id < games.length; id++) {
    testWidgets('Game $id renders and disposes cleanly', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
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
      for (var frame = 0; frame < 140; frame++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    });
  }
}
