import 'dart:math';
import 'package:flutter/material.dart';
import 'catalog.dart';
import 'joy_theme.dart';
import 'games/sprites.dart';

// Control demonstrations are deliberately explicit: a drag, a tap or a turn.
const tutorialSteps = <List<String>>[
  [
    'Hold your half of the road.',
    'Steer left or right around traffic.',
    'Follow the gold line to reach 10 checkpoints.',
  ],
  [
    'Choose a secret bid from 0 to 4.',
    'Pass the phone so nobody sees your bid.',
    'The highest bid buys gems. Save coins for later rounds.',
  ],
  [
    'Touch your car in your half.',
    'Drag into the highlighted parking bay.',
    'Reach five successful parks first.',
  ],
  [
    'Watch cars approaching your junction.',
    'Tap to change the traffic phase once the crossing clears.',
    'Deliver 12 cars without a collision.',
  ],
  [
    'Watch the block sliding across the tower.',
    'Tap when it aligns with the block below.',
    'Overhang disappears. A complete miss loses.',
  ],
  [
    'Your paddle is along your baseline.',
    'Drag left and right to meet the ball.',
    'Send the ball past the other paddle. First to five.',
  ],
  [
    'Keep your striker in your half.',
    'Drag toward the puck to strike it.',
    'Aim for the narrow opposing goal. First to five.',
  ],
  [
    'The shooter flicks toward goal.',
    'The keeper drags to block the shot.',
    'Swap roles each shot. Score the most after five each.',
  ],
  [
    'Watch the moving basketball.',
    'Tap your half when it aligns with the hoop.',
    'Time five successful shots to win.',
  ],
  [
    'Touch near your golf ball.',
    'Pull back and release to putt.',
    'Use gentle shots and wall bounces to reach the cup.',
  ],
  [
    'Touch your sumo wrestler.',
    'Drag to push your opponent.',
    'Stay inside the ring while pushing them outside.',
  ],
  [
    'Drag your tank to move.',
    'Tap FIRE to launch a projectile.',
    'Land five hits while avoiding incoming shots.',
  ],
  [
    'Use your four direction buttons.',
    'Collect food and leave space for your growing trail.',
    'Avoid walls and both snakes.',
  ],
  [
    'Drag to move through the arena.',
    'Drop a bomb, then move away before it explodes.',
    'Catch your rival in the blast without trapping yourself.',
  ],
  [
    'Wait until your runner is on the ground.',
    'Tap to jump over the next gap.',
    'Land before jumping again and outlast your rival.',
  ],
  [
    'Find the empty space.',
    'Tap a neighboring tile to slide it.',
    'Take turns to restore the numbers to their order.',
  ],
  [
    'Look for a legal square beside rival discs.',
    'Bracket rival discs with your own to capture them.',
    'Finish with the most discs. Pass only when no move exists.',
  ],
  [
    'Find your player marker.',
    'Tap an adjacent open path tile.',
    'Reach the opposite corner before your rival.',
  ],
  [
    'Choose a column.',
    'Tap to drop your disc into the lowest free cell.',
    'Connect four horizontally, vertically or diagonally.',
  ],
  [
    'Choose an empty square.',
    'Tap to place your cross or circle.',
    'Make a line of three and block your rival.',
  ],
  [
    'Tap one card to reveal its picture.',
    'Tap a second card and remember both.',
    'Matching pairs score and keep your turn.',
  ],
  [
    'Compare the two illustrated scenes.',
    'Find the tile with a different picture.',
    'Tap the changed tile to score.',
  ],
  [
    'Look at the target picture.',
    'Scan the collection for the identical object.',
    'Tap the matching object to score.',
  ],
  [
    'Watch every flashing pad in order.',
    'Wait until the sequence finishes.',
    'Repeat the entire pattern. It grows each round.',
  ],
  [
    'Remember the cup hiding the diamond.',
    'Follow that cup through the swaps.',
    'Tap the cup when the shuffling stops.',
  ],
  [
    'Read the riddle.',
    'Compare all four answers before choosing.',
    'Tap the best answer. First to five points.',
  ],
  [
    'Read the arithmetic expression.',
    'Calculate the answer.',
    'Tap the correct number. First to five points.',
  ],
  [
    'Place a finger near your own pad.',
    'Wait for NOW. Tapping early has a penalty.',
    'Tap your own pad first after the signal.',
  ],
  [
    'Read the scrambled letters.',
    'Tap letters in the order of the word.',
    'Undo a mistake, then submit your answer.',
  ],
  [
    'Choose rock, paper or scissors secretly.',
    'Pass the phone for the other choice.',
    'Rock beats scissors, scissors beats paper, paper beats rock.',
  ],
  [
    'Choose a clue from the selector.',
    'Tap letters on the keyboard to fill the word.',
    'Check the answer and use crossings to solve other clues.',
  ],
  [
    'Read the target word.',
    'Select the letter cells along its straight path.',
    'Find each word in the grid to score.',
  ],
  [
    'Choose an unclaimed edge between dots.',
    'Tap to draw your line.',
    'Close a box to claim it and keep your turn.',
  ],
  [
    'Choose a square on the opposing grid.',
    'Tap to fire and use hit or miss feedback.',
    'Find and sink all ships before your rival.',
  ],
  [
    'Build a four-color guess.',
    'Submit and read the exact and misplaced counts.',
    'Use the clues to solve the secret code.',
  ],
  [
    'Reveal a safe tile.',
    'Read numbers to infer neighboring mines.',
    'Collect safe tiles and avoid losing all your lives.',
  ],
];

class GameTutorial extends StatefulWidget {
  final int id;
  const GameTutorial({super.key, required this.id});
  @override
  State<GameTutorial> createState() => _GameTutorialState();
}

class _GameTutorialState extends State<GameTutorial>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  int step = 0;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
      controller.value = .6;
    } else {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drag = {0, 2, 5, 6, 7, 9, 10, 11, 13}.contains(widget.id);
    return Scaffold(
      appBar: AppBar(title: Text('${games[widget.id].name} tutorial')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'STEP ${step + 1} OF 3',
              style: const TextStyle(color: JoyTheme.muted, letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: AnimatedBuilder(
                animation: controller,
                builder:
                    (context, _) => CustomPaint(
                      painter: _DemoPainter(controller.value, widget.id, drag),
                    ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tutorialSteps[widget.id][step],
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              drag
                  ? 'Demonstration: drag the highlighted control.'
                  : 'Demonstration: tap a highlighted target when it is your turn.',
              style: const TextStyle(color: JoyTheme.muted),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: i == step ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == step ? JoyTheme.accent : JoyTheme.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed:
                  () =>
                      step == 2
                          ? Navigator.pop(context, true)
                          : setState(() => step++),
              child: Text(step == 2 ? 'Got it, let’s play' : 'Next step'),
            ),
            if (step > 0)
              TextButton(
                onPressed: () => setState(() => step--),
                child: const Text('Previous step'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip tutorial'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoPainter extends CustomPainter {
  final double t;
  final int id;
  final bool drag;
  _DemoPainter(this.t, this.id, this.drag);
  @override
  void paint(Canvas c, Size s) {
    final paint = Paint();
    final rect = Offset.zero & s;
    c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      paint..color = JoyTheme.surface,
    );
    if (id == 5 || id == 6) {
      c.drawLine(
        Offset(20, s.height / 2),
        Offset(s.width - 20, s.height / 2),
        paint
          ..color = JoyTheme.border
          ..strokeWidth = 2,
      );
      final x = s.width * (.5 + sin(t * pi * 2) * .25);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, s.height * .8),
            width: 64,
            height: 12,
          ),
          const Radius.circular(8),
        ),
        paint..color = JoyTheme.accent,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s.width - x, s.height * .2),
            width: 64,
            height: 12,
          ),
          const Radius.circular(8),
        ),
        paint..color = const Color(0xFFFF6F83),
      );
      c.drawCircle(
        Offset(x, s.height * (.5 + sin(t * pi * 2) * .22)),
        7,
        paint..color = Colors.white,
      );
    } else if ({0, 2, 3}.contains(id)) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.width * .2, 10, s.width * .6, 200),
          const Radius.circular(20),
        ),
        paint..color = JoyTheme.background,
      );
      for (var i = 0; i < 4; i++) {
        c.drawRect(
          Rect.fromLTWH(s.width * .49, (i * 60 + t * 60) % 210, 3, 25),
          paint..color = JoyTheme.border,
        );
      }
      GameSprites.car(
        c,
        Offset(s.width * (.5 + sin(t * pi * 2) * .2), 145),
        22,
        JoyTheme.accent,
      );
      if (id == 2) {
        c.drawRect(
          Rect.fromLTWH(s.width * .65, 35, 40, 65),
          paint..color = const Color(0xFFFFC16D).withValues(alpha: .3),
        );
      } else {
        GameSprites.car(
          c,
          Offset(s.width * .6, 45 + t * 60),
          18,
          const Color(0xFFFF6F83),
        );
      }
    } else if (id == 4) {
      for (var i = 0; i < 4; i++) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              s.width * .25 + i * 3,
              160 - i * 30,
              s.width * .45,
              26,
            ),
            const Radius.circular(5),
          ),
          paint
            ..color =
                Color.lerp(JoyTheme.accent, const Color(0xFFFFC16D), i / 4)!,
        );
      }
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.width * (.1 + t * .4), 35, s.width * .4, 26),
          const Radius.circular(5),
        ),
        paint..color = const Color(0xFFFF6F83),
      );
    } else if ({20, 23, 24}.contains(id)) {
      for (var i = 0; i < (id == 24 ? 3 : 4); i++) {
        final x = s.width * (.2 + (i % 2) * .5), y = 40.0 + (i ~/ 2) * 95;
        final lit = (t * 4).floor() == i;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 15, y, 65, 65),
            Radius.circular(id == 24 ? 24 : 12),
          ),
          paint..color = lit ? const Color(0xFFFFC16D) : JoyTheme.raised,
        );
        if (id == 20 && lit) {
          GameSprites.orb(c, Offset(x + 18, y + 32), 13, JoyTheme.accent);
        }
      }
    } else if ({25, 26, 27, 29}.contains(id)) {
      void word(String text, Offset at, double size) {
        final p = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: JoyTheme.ink,
              fontSize: size,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        p.paint(c, at);
      }

      word(
        id == 26
            ? '2 + 3 = ?'
            : id == 27
            ? (t > .6 ? 'NOW!' : 'WAIT…')
            : id == 29
            ? 'ROCK  PAPER  SCISSORS'
            : 'Solve the riddle',
        Offset(25, 35),
        20,
      );
      for (var i = 0; i < 3; i++) {
        final r = Rect.fromLTWH(
          22 + i * (s.width - 44) / 3,
          105,
          (s.width - 60) / 3,
          55,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(12)),
          paint
            ..color = (t * 3).floor() == i ? JoyTheme.accent : JoyTheme.raised,
        );
        if (id == 26) word('${i + 4}', r.topLeft + const Offset(15, 12), 22);
      }
    } else if ({28, 30, 31, 34}.contains(id)) {
      for (var i = 0; i < 9; i++) {
        final r = Rect.fromLTWH(
          s.width * .2 + (i % 3) * s.width * .2,
          25 + (i ~/ 3) * 52,
          s.width * .17,
          44,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(9)),
          paint
            ..color =
                (i < ((t * 9).floor())) ? JoyTheme.accent : JoyTheme.raised,
        );
        final letter = id == 34 ? '●' : 'CROSSWORD'[i];
        final p = TextPainter(
          text: TextSpan(
            text: letter,
            style: const TextStyle(
              color: JoyTheme.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        p.paint(c, r.center - Offset(p.width / 2, p.height / 2));
      }
    } else {
      for (var i = 0; i < 9; i++) {
        final r = Rect.fromLTWH(
          s.width * .22 + (i % 3) * s.width * .19,
          25 + (i ~/ 3) * 52,
          s.width * .16,
          42,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(9)),
          paint
            ..color =
                (i == (t * 9).floor() ? JoyTheme.accent : JoyTheme.raised),
        );
        if (id == 19 && i == 4) {
          final p = TextPainter(
            text: const TextSpan(
              text: '×',
              style: TextStyle(color: Colors.white, fontSize: 28),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          p.paint(c, r.center - Offset(p.width / 2, p.height / 2));
        }
      }
    }
    final x = s.width * (drag ? .5 + sin(t * pi * 2) * .25 : .5);
    final pos = Offset(x, s.height * .78);
    c.drawCircle(
      pos,
      15 + sin(t * pi) * 8,
      paint..color = const Color(0xFFFFC16D).withValues(alpha: .25),
    );
    c.drawCircle(pos, 9, paint..color = const Color(0xFFFFC16D));
  }

  @override
  bool shouldRepaint(_DemoPainter old) => t != old.t || id != old.id;
}
