import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/joy_theme.dart';
import 'package:joy/result_dialog.dart';

Widget host({
  required int winner,
  required List<ResultAction> actions,
  List<String> names = const ['Ana', 'Bo'],
  String? status,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: JoyTheme.dark,
  home: Builder(
    builder:
        (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: Scaffold(
            body: MatchResultDialog(
              gameName: 'Ping Pong',
              names: names,
              winner: winner,
              seconds: 42,
              actions: actions,
              status: status,
            ),
          ),
        ),
  ),
);

void main() {
  testWidgets('Winner dialog settles: confetti and entrance are finite', (
    tester,
  ) async {
    var tapped = '';
    await tester.pumpWidget(
      host(
        winner: 1,
        actions: [
          ResultAction(
            label: 'Share',
            icon: Icons.ios_share_rounded,
            onPressed: () => tapped = 'share',
          ),
          ResultAction(
            label: 'Play again',
            icon: Icons.replay_rounded,
            primary: true,
            onPressed: () => tapped = 'again',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bo wins!'), findsOneWidget);
    expect(find.text('Ping Pong • 42s'), findsOneWidget);
    expect(find.byType(ConfettiBurst), findsOneWidget);
    await tester.tap(find.text('Play again'));
    expect(tapped, 'again');
    await tester.tap(find.text('Share'));
    expect(tapped, 'share');
  });

  testWidgets('A draw shows no confetti and no winner', (tester) async {
    await tester.pumpWidget(host(winner: -1, actions: const []));
    await tester.pumpAndSettle();
    expect(find.text('Match tied!'), findsOneWidget);
    expect(find.textContaining('wins!'), findsNothing);
    expect(find.byType(ConfettiBurst), findsNothing);
  });

  testWidgets('Reduced motion skips the confetti', (tester) async {
    await tester.pumpWidget(
      host(winner: 0, actions: const [], reduceMotion: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana wins!'), findsOneWidget);
    expect(find.byType(ConfettiBurst), findsNothing);
  });

  testWidgets('The primary action is listed first and an odd one fills a row', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        winner: 0,
        actions: [
          ResultAction(
            label: 'Share',
            icon: Icons.ios_share_rounded,
            onPressed: () {},
          ),
          ResultAction(
            label: 'Back to lobby',
            icon: Icons.home_rounded,
            onPressed: () {},
          ),
          ResultAction(
            label: 'Continue',
            icon: Icons.check_circle_outline_rounded,
            primary: true,
            onPressed: () {},
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final continueTop = tester.getTopLeft(find.text('Continue')).dy;
    expect(continueTop, lessThan(tester.getTopLeft(find.text('Share')).dy));
    final outlined = find.bySubtype<OutlinedButton>();
    final shareWidth = tester.getSize(outlined.first).width;
    final lastRow = tester.getSize(outlined.last).width;
    expect(shareWidth, lessThan(lastRow));
  });

  testWidgets('Narrow screens and large text stack buttons without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: JoyTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.6),
          ),
          child: Scaffold(
            body: MatchResultDialog(
              gameName: 'Reversi',
              names: const ['A very long player name', 'B', 'C', 'D'],
              winner: 2,
              seconds: 9,
              status: 'Scorecard copied.',
              actions: [
                ResultAction(
                  label: 'Play again',
                  icon: Icons.replay_rounded,
                  primary: true,
                  onPressed: () {},
                ),
                ResultAction(
                  label: 'Back to lobby',
                  icon: Icons.home_rounded,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Scorecard copied.'), findsOneWidget);
    final first = tester.getTopLeft(find.bySubtype<FilledButton>()).dy;
    final second = tester.getTopLeft(find.bySubtype<OutlinedButton>()).dy;
    expect(second, greaterThan(first));
  });
}
