import '../sound.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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
  final score = [0, 0];
  int turn = 0, answer = 0, round = 0;
  String prompt = '', feedback = '';
  List<String> options = [];
  bool hidden = false, ready = false, locked = false, finished = false;
  int? secret;
  Timer? timer;
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
    next();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void next() {
    timer?.cancel();
    round++;
    hidden = false;
    locked = false;
    ready = false;
    feedback = '';
    final id = widget.id;
    if (id == 27) {
      prompt = 'WAIT…';
      options = [];
      timer = Timer(Duration(milliseconds: 1600 + rng.nextInt(2800)), () {
        if (mounted) {
          setState(() {
            ready = true;
            prompt = 'NOW!';
          });
        }
      });
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
      final a = 2 + rng.nextInt(18), b = 2 + rng.nextInt(12);
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
        timer = Timer.periodic(const Duration(milliseconds: 700), (t) {
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
              return;
            }
            final a = rng.nextInt(3), b = (a + 1 + rng.nextInt(2)) % 3;
            final v = cups[a];
            cups[a] = cups[b];
            cups[b] = v;
            cupStep++;
          });
        });
      });
    }
  }

  void winPoint(int p, {bool playCue = true}) {
    if (playCue) JoySounds.instance.play(SoundEffect.correct);
    score[p]++;
    if (score[p] >= 5) {
      finished = true;
      widget.onFinish(p);
    }
  }

  void choose(int i) async {
    if (locked || finished) return;
    if (widget.id == 29) {
      if (secret == null) {
        JoySounds.instance.play(SoundEffect.tap);
        secret = i;
        turn = 1;
        setState(() => prompt = 'Pass the phone to ${widget.names[1]}');
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
      turn = 1 - turn;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted && !finished) setState(next);
  }

  void react(int p) async {
    if (locked || finished) return;
    locked = true;
    timer?.cancel();
    final winner = ready ? p : 1 - p;
    if (!ready) JoySounds.instance.play(SoundEffect.wrong);
    winPoint(winner, playCue: ready);
    setState(
      () =>
          prompt =
              ready
                  ? '${widget.names[winner]} was faster!'
                  : 'Too early! Point to ${widget.names[winner]}',
    );
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted && !finished) setState(next);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Text(
          '${widget.names[0]}  ${score[0]} : ${score[1]}  ${widget.names[1]}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.id != 27)
          Text(
            '${widget.names[turn]}’s turn',
            style: const TextStyle(color: Colors.white60),
          ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                      height: 100,
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
                  const SizedBox(height: 20),
                  Text(
                    feedback,
                    style: const TextStyle(color: Colors.amber, fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.id == 27)
          Row(
            children: [
              for (var p = 0; p < 2; p++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            p == 0
                                ? const Color(0xFF507CFF)
                                : const Color(0xFFFF6F83),
                        minimumSize: const Size(0, 120),
                      ),
                      onPressed: () => react(p),
                      child: Text(widget.names[p]),
                    ),
                  ),
                ),
            ],
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < options.length; i++)
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 52) / 2,
                  child: FilledButton.tonal(
                    onPressed: locked ? null : () => choose(i),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 70),
                    ),
                    child: Text(
                      options[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
