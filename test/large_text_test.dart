import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/main.dart';
import 'package:joy/party_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> phone(WidgetTester tester, {double scale = 2}) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({});
    await PartyData.instance.initialize();
  }

  testWidgets('Lobby has no overflow at double text size', (tester) async {
    await phone(tester);
    await tester.pumpWidget(const JoyApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final id in [5, 19, 33]) {
    testWidgets('Game $id intro and board fit at double text size', (
      tester,
    ) async {
      await phone(tester);
      PartyData.instance.seen.add(id);
      await tester.pumpWidget(
        MaterialApp(
          home: MatchScreen(id: id, names: const ['Ana', 'Bo'], haptics: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Let’s play'));
      await tester.tap(find.text('Let’s play'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
