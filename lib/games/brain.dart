import '../sound.dart';
import '../party_data.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'bot_skill.dart';
import 'game_stage.dart';

class BrainGame extends StatefulWidget {
  final int id;
  final List<String> names;
  final ValueChanged<int> onFinish;
  const BrainGame({
    super.key,
    required this.id,
    required this.names,
    required this.onFinish,
  });
  @override
  State<BrainGame> createState() => _BrainGameState();
}

class _BrainGameState extends State<BrainGame> {
  final rng = Random();
  late final List<int> score;
  int turn = 0, answer = 0, round = 0;
  String prompt = '', feedback = '';
  List<String> options = [];
  bool hidden = false, ready = false, locked = false, finished = false;
  int? secret;
  Timer? timer;
  Timer? botTimer;
  final cups = [0, 1, 2];
  int cupStep = 0;
  bool cupRevealed = true;
  static const riddles = [
    ['What has keys but cannot open locks?', 'Piano', 'Clock', 'River', 'Tree'],
    ['What gets wetter as it dries?', 'Towel', 'Cloud', 'Sand', 'Fire'],
    ['What has hands but cannot clap?', 'Clock', 'Chair', 'Bird', 'Shoe'],
    ['What has a neck but no head?', 'Bottle', 'Horse', 'River', 'Book'],
    ['What has many teeth but cannot bite?', 'Comb', 'Fish', 'Fork', 'Lion'],
    ['What follows you in sunlight?', 'Shadow', 'Moon', 'Wind', 'Rain'],
    ['What has cities but no houses?', 'Map', 'Book', 'Forest', 'Sky'],
    ['What has words but never speaks?', 'Book', 'Radio', 'Phone', 'Parrot'],
    ['What can you catch but never throw?', 'Cold', 'Ball', 'Stone', 'Hat'],
    ['What goes up but never comes down?', 'Age', 'Balloon', 'Rain', 'Smoke'],
  ];
  @override
  void initState() {
    super.initState();
    score = List.filled(widget.names.length, 0);
    next();
  }

  @override
  void dispose() {
    timer?.cancel();
    botTimer?.cancel();
    super.dispose();
  }

  /// Whether this match is played against the computer.
  bool get vsComputer => MatchOptions.read(context)?.computer == true;

  /// Whether it is the computer's turn to answer (not the reaction duel).
  bool get botTurn => vsComputer && turn == 1 && widget.id != 27;

  /// Riddle, Math and Follow the Cup: the computer answers after a pause,
  /// and is right with a probability that depends on the difficulty.
  void scheduleBot() {
    if (!vsComputer || finished || turn != 1) return;
    if (![24, 25, 26].contains(widget.id)) return;
    final skill = BotSkill.of(context);
    botTimer?.cancel();
    botTimer = Timer(
      skill.think(rng, seconds: widget.id == 24 ? 1.0 : 2.3),
      () {
        if (!mounted || finished || locked || turn != 1) return;
        var pick = answer;
        if (!skill.succeeds(rng)) {
          final wrong = [
            for (var i = 0; i < options.length; i++)
              if (i != answer) i,
          ];
          pick = wrong[rng.nextInt(wrong.length)];
        }
        choose(pick, bot: true);
      },
    );
  }

  /// Reaction Duel: presses a human-like moment after the signal.
  void botReact() {
    if (!vsComputer) return;
    botTimer?.cancel();
    botTimer = Timer(BotSkill.of(context).think(rng, seconds: .55), () {
      if (mounted && !finished && !locked && ready) react(1, bot: true);
    });
  }

  /// On Easy the computer sometimes jumps the gun before the signal.
  void botFalseStart(int wait) {
    if (!vsComputer) return;
    final skill = BotSkill.of(context);
    if (skill.level != Difficulty.easy || rng.nextDouble() >= .12) return;
    botTimer?.cancel();
    botTimer = Timer(Duration(milliseconds: 500 + rng.nextInt(wait - 900)), () {
      if (mounted && !finished && !locked && !ready) react(1, bot: true);
    });
  }

  void next() {
    timer?.cancel();
    botTimer?.cancel();
    round++;
    hidden = false;
    locked = false;
    ready = false;
    feedback = '';
    final id = widget.id;
    if (id == 27) {
      prompt = 'WAIT…';
      options = [];
      final wait = 1600 + rng.nextInt(2800);
      timer = Timer(Duration(milliseconds: wait), () {
        if (mounted) {
          setState(() {
            ready = true;
            prompt = 'NOW!';
          });
          botReact();
        }
      });
      botFalseStart(wait);
      return;
    }
    if (id == 29) {
      prompt = '${widget.names[turn]}, choose secretly';
      options = ['✊ Rock', '✋ Paper', '✌️ Scissors'];
      return;
    }
    answer = rng.nextInt(4);
    if (id == 25) {
      final q = riddles[rng.nextInt(riddles.length)];
      prompt = q[0];
      options = q.sublist(1)..shuffle(rng);
      answer = options.indexOf(q[1]);
    }
    if (id == 26) {
      final level = MatchOptions.read(context)?.difficulty ?? Difficulty.normal;
      final a =
              2 +
              rng.nextInt(
                level == Difficulty.easy
                    ? 8
                    : level == Difficulty.hard
                    ? 38
                    : 18,
              ),
          b =
              2 +
              rng.nextInt(
                level == Difficulty.easy
                    ? 5
                    : level == Difficulty.hard
                    ? 18
                    : 12,
              );
      final multiply = rng.nextBool();
      final result = multiply ? a * b : a + b;
      prompt = '$a ${multiply ? '×' : '+'} $b = ?';
      options = List.generate(
        4,
        (i) => '${result + (i - answer) * (1 + rng.nextInt(3))}',
      );
      options[answer] = '$result';
      while (options.toSet().length < 4) {
        options = List.generate(4, (i) => '${result + (i - answer) * 2}');
      }
    }
    if (id == 24) {
      cups.setAll(0, [0, 1, 2]);
      cupStep = 0;
      cupRevealed = true;
      prompt = 'Track the diamond cup';
      options = ['Cup 1', 'Cup 2', 'Cup 3'];
      locked = true;
      timer = Timer(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        setState(() => cupRevealed = false);
        timer = Timer.periodic(
          Duration(
            milliseconds:
                (MatchOptions.read(context)?.difficulty == Difficulty.easy
                    ? 1000
                    : MatchOptions.read(context)?.difficulty == Difficulty.hard
                    ? 450
                    : 700),
          ),
          (t) {
            if (!mounted) {
              t.cancel();
              return;
            }
            setState(() {
              if (cupStep == 5) {
                t.cancel();
                answer = cups.indexOf(0);
                locked = false;
                prompt = 'Where is the diamond?';
                scheduleBot();
                return;
              }
              final a = rng.nextInt(3), b = (a + 1 + rng.nextInt(2)) % 3;
              final v = cups[a];
              cups[a] = cups[b];
              cups[b] = v;
              cupStep++;
            });
          },
        );
      });
    }
    if (id == 25 || id == 26) scheduleBot();
  }

  void winPoint(int p, {bool playCue = true}) {
    if (playCue) JoySounds.instance.play(SoundEffect.correct);
    score[p]++;
    if (score[p] >= 5) {
      finished = true;
      widget.onFinish(p);
    }
  }

  void choose(int i, {bool bot = false}) async {
    if (locked ||
        finished ||
        (MatchOptions.read(context)?.computer == true && turn == 1 && !bot)) {
      return;
    }
    if (widget.id == 29) {
      if (secret == null) {
        JoySounds.instance.play(SoundEffect.tap);
        secret = i;
        turn = 1;
        setState(
          () =>
              prompt =
                  MatchOptions.read(context)?.computer == true
                      ? 'Computer is choosing…'
                      : 'Pass the phone to ${widget.names[1]}',
        );
        if (MatchOptions.read(context)?.computer == true) {
          timer = Timer(const Duration(milliseconds: 700), () {
            if (mounted && !finished) choose(rng.nextInt(3), bot: true);
          });
        }
        return;
      }
      locked = true;
      final a = secret!;
      secret = null;
      final winner =
          a == i
              ? -1
              : (a - i + 3) % 3 == 1
              ? 0
              : 1;
      if (winner >= 0) {
        winPoint(winner);
      } else {
        JoySounds.instance.play(SoundEffect.tap);
      }
      setState(
        () =>
            feedback =
                winner < 0 ? 'Draw' : '${widget.names[winner]} wins this hand',
      );
      turn = 0;
    } else {
      locked = true;
      final correct = i == answer;
      if (correct) {
        winPoint(turn);
      } else {
        JoySounds.instance.play(SoundEffect.wrong);
      }
      setState(
        () => feedback = correct ? 'Correct!' : 'Answer: ${options[answer]}',
      );
      turn = (turn + 1) % widget.names.length;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted && !finished) setState(next);
  }

  void react(int p, {bool bot = false}) async {
    if (locked || finished || (vsComputer && p == 1 && !bot)) return;
    locked = true;
    timer?.cancel();
    botTimer?.cancel();
    if (ready) {
      winPoint(p);
      setState(() => prompt = '${widget.names[p]} was faster!');
    } else if (widget.names.length == 2) {
      final winner = 1 - p;
      JoySounds.instance.play(SoundEffect.wrong);
      winPoint(winner, playCue: false);
      setState(() => prompt = 'Too early! Point to ${widget.names[winner]}');
    } else {
      JoySounds.instance.play(SoundEffect.wrong);
      score[p]--;
      setState(() => prompt = 'Too early, ${widget.names[p]}! One point lost.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted && !finished) setState(next);
  }

  @override
  Widget build(BuildContext context) => GameStage(
    id: widget.id,
    names: widget.names,
    scores: score,
    turn: widget.id == 27 ? -1 : turn,
    message:
        widget.id == 27
            ? 'Wait for the signal'
            : '${widget.names[turn]}’s turn',
    child: Column(
      children: [
        const SizedBox(height: 12),
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: widget.id == 27 ? 38 : 25,
            fontWeight: FontWeight.w700,
            color: ready ? Colors.amber : Colors.white,
          ),
        ),
        if (widget.id == 24)
          SizedBox(
            height: 120,
            child: LayoutBuilder(
              builder:
                  (c, size) => Stack(
                    children: [
                      for (var i = 0; i < 3; i++)
                        AnimatedPositioned(
                          key: ValueKey(i),
                          duration: const Duration(milliseconds: 450),
                          left: cups.indexOf(i) * size.maxWidth / 3,
                          top: 20,
                          width: size.maxWidth / 3,
                          child: Text(
                            cupRevealed && i == 0 ? '💎' : '🥤',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                    ],
                  ),
            ),
          ),
        const SizedBox(height: 22),
        Text(
          feedback.isEmpty && botTurn && !locked
              ? '🤖 Computer is thinking…'
              : feedback,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.amber, fontSize: 20),
        ),
        const SizedBox(height: 22),
        if (widget.id == 27)
          boardGrid(
            widget.names.length,
            2,
            (p) => FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: playerColors[p],
                disabledBackgroundColor: playerColors[p].withValues(alpha: .35),
              ),
              onPressed: vsComputer && p == 1 ? null : () => react(p),
              child: Text(widget.names[p], textAlign: TextAlign.center),
            ),
          )
        else
          LayoutBuilder(
            builder:
                (c, box) => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < options.length; i++)
                      SizedBox(
                        width: (box.maxWidth - 10) / 2,
                        height: 76,
                        child: FilledButton.tonal(
                          onPressed: locked || botTurn ? null : () => choose(i),
                          child: Text(
                            options[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 19),
                          ),
                        ),
                      ),
                  ],
                ),
          ),
      ],
    ),
  );
}
