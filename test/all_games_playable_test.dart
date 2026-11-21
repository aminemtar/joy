import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/catalog.dart';
import 'package:joy/game_factory.dart';
import 'package:joy/party_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every one of the 36 games must build, keep running, accept touches and
/// never throw, both between two people and against the computer.
void main() {
  for (final computer in [false, true]) {
    for (var id = 0; id < games.length; id++) {
      testWidgets(
        '${games[id].name} (#$id) is playable${computer ? ' vs computer' : ''}',
        (tester) async {
          tester.view.physicalSize = const Size(400, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({});
          final finished = <int>[];
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MatchOptions(
                  computer: computer,
                  difficulty: Difficulty.normal,
                  child: buildGame(
                    id: id,
                    names: const ['Ana', 'Bo'],
                    onFinish: finished.add,
                  ),
                ),
              ),
            ),
          );
          for (var i = 0; i < 100; i++) {
            await tester.pump(const Duration(milliseconds: 33));
          }
          expect(tester.takeException(), isNull);
          // Touch the screen in a grid of places, as a player would.
          for (final y in [.25, .5, .75]) {
            for (final x in [.2, .5, .8]) {
              await tester.tapAt(Offset(400 * x, 900 * y));
              await tester.pump(const Duration(milliseconds: 120));
            }
          }
          await tester.dragFrom(
            const Offset(200, 700),
            const Offset(60, -120),
          );
          for (var i = 0; i < 60; i++) {
            await tester.pump(const Duration(milliseconds: 33));
          }
          expect(tester.takeException(), isNull);
          expect(find.byType(Scaffold), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
