import 'package:flutter/material.dart';
import 'catalog.dart';
import 'joy_theme.dart';
import 'tutorial_scenes.dart';

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
    'Your ball sweeps side to side, the hoop slides.',
    'Tap to shoot and lead the hoop: the ball takes a moment to fly.',
    'Swish 3, basket 2, three in a row is on fire. First to 11 wins.',
  ],
  [
    'Touch near your golf ball.',
    'Pull back and release to putt.',
    'Use gentle shots and wall bounces to reach the cup.',
  ],
  [
    'Your wrestler starts on your line of the ring.',
    'Hold the arrow buttons to charge. On a keyboard use the arrow keys or WASD.',
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
                      painter: _DemoPainter(controller.value, widget.id),
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
              tutorialHint(widget.id),
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
  _DemoPainter(this.t, this.id);
  @override
  void paint(Canvas c, Size s) => paintTutorialScene(c, s, t, id);

  @override
  bool shouldRepaint(_DemoPainter old) => t != old.t || id != old.id;
}
