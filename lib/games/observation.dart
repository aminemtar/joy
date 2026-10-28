import '../sound.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../game_art.dart';
import 'game_stage.dart';
import '../players.dart' show leadingPlayer;

class ObservationGame extends StatefulWidget {
  final int id;
  final List<String> names;
  final ValueChanged<int> onFinish;
  const ObservationGame({
    super.key,
    required this.id,
    required this.names,
    required this.onFinish,
  });
  @override
  State<ObservationGame> createState() => _ObservationGameState();
}

class _ObservationGameState extends State<ObservationGame> {
  final random = Random();
  late final List<int> score;
  int turn = 0,
      target = 0,
      difference = 0,
      round = 0,
      lit = -1,
      sequenceIndex = 0,
      input = 0;
  bool watching = false, locked = false, done = false;
  Timer? timer;
  List<int> left = [], right = [], sequence = [];
  String message = '';
  static const art = [0, 5, 8, 11, 12, 19, 22, 29];
  static const colors = [
    Color(0xFF507CFF),
    Color(0xFFFF6F83),
    Color(0xFFFFC16D),
    Color(0xFFA08AFF),
  ];
  @override
  void initState() {
    super.initState();
    score = List.filled(widget.names.length, 0);
    newRound();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void newRound() {
    timer?.cancel();
    locked = false;
    input = 0;
    lit = -1;
    message = '';
    if (widget.id == 21) {
      left = List.generate(16, (_) => random.nextInt(art.length));
      right = List.of(left);
      difference = random.nextInt(16);
      right[difference] =
          (right[difference] + 1 + random.nextInt(art.length - 1)) % art.length;
    } else if (widget.id == 22) {
      target = random.nextInt(art.length);
      left = List.generate(
        25,
        (_) => (target + 1 + random.nextInt(art.length - 1)) % art.length,
      );
      difference = random.nextInt(25);
      left[difference] = target;
    } else {
      sequence = List.generate(
        3 + round ~/ widget.names.length,
        (_) => random.nextInt(4),
      );
      sequenceIndex = 0;
      watching = true;
      message = 'Watch the whole sequence';
      timer = Timer(const Duration(milliseconds: 700), flash);
    }
  }

  void flash() {
    if (!mounted || done) return;
    if (sequenceIndex >= sequence.length) {
      setState(() {
        watching = false;
        lit = -1;
        message = 'Repeat all ${sequence.length} colors in order';
      });
      return;
    }
    JoySounds.instance.play(
      [
        SoundEffect.noteBlue,
        SoundEffect.noteCoral,
        SoundEffect.noteGold,
        SoundEffect.notePurple,
      ][sequence[sequenceIndex]],
    );
    setState(() => lit = sequence[sequenceIndex]);
    timer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => lit = -1);
      sequenceIndex++;
      timer = Timer(const Duration(milliseconds: 200), flash);
    });
  }

  void end() {
    done = true;
    widget.onFinish(leadingPlayer(score));
  }

  void resolve(bool correct) {
    locked = true;
    JoySounds.instance.play(correct ? SoundEffect.correct : SoundEffect.wrong);
    if (correct) score[turn] += widget.id == 23 ? sequence.length : 1;
    message = correct ? 'Correct!' : 'Miss — turn passes';
    if (widget.id != 23 && score[turn] >= 5) {
      end();
      return;
    }
    round++;
    if (widget.id == 23 && round == widget.names.length * 4) {
      end();
      return;
    }
    timer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || done) return;
      setState(() {
        turn = (turn + 1) % widget.names.length;
        newRound();
      });
    });
  }

  void tap(int i) {
    if (done || locked || watching) return;
    setState(() {
      if (widget.id == 23) {
        if (i != sequence[input]) {
          resolve(false);
          return;
        }
        JoySounds.instance.play(
          [
            SoundEffect.noteBlue,
            SoundEffect.noteCoral,
            SoundEffect.noteGold,
            SoundEffect.notePurple,
          ][i],
        );
        input++;
        lit = i;
        message = '$input / ${sequence.length}';
        if (input == sequence.length) {
          resolve(true);
        } else {
          timer?.cancel();
          timer = Timer(const Duration(milliseconds: 180), () {
            if (mounted) setState(() => lit = -1);
          });
        }
      } else {
        resolve(i == difference);
      }
    });
  }

  Widget pictures(List<int> items, bool active) => boardGrid(
    items.length,
    widget.id == 22 ? 5 : 4,
    (i) => gameTile(
      onTap: active ? () => tap(i) : null,
      selected: locked && i == difference,
      child: GameArt(id: art[items[i]], size: 90),
    ),
    spacing: 5,
  );
  @override
  Widget build(BuildContext context) {
    Widget content;
    if (widget.id == 21) {
      content = Column(
        children: [
          const Text(
            'ORIGINAL',
            style: TextStyle(letterSpacing: 3, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          pictures(left, false),
          const SizedBox(height: 20),
          const Text(
            'FIND THE DIFFERENCE',
            style: TextStyle(letterSpacing: 2, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          pictures(right, true),
        ],
      );
    } else if (widget.id == 22) {
      content = Column(
        children: [
          const Text('Find this object in the collection'),
          GameArt(id: art[target], size: 100),
          pictures(left, true),
        ],
      );
    } else {
      content = Column(
        children: [
          Text(
            'Memory round ${round + 1} / ${widget.names.length * 4}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          boardGrid(
            4,
            2,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color:
                    lit == i
                        ? Color.lerp(colors[i], Colors.white, .65)
                        : colors[i].withValues(alpha: .3),
                border: Border.all(
                  color: lit == i ? Colors.white : colors[i],
                  width: 3,
                ),
                boxShadow:
                    lit == i
                        ? [
                          BoxShadow(
                            color: colors[i].withValues(alpha: .5),
                            blurRadius: 22,
                          ),
                        ]
                        : [],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => tap(i),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            watching
                ? 'Watch — controls unlock after playback'
                : 'Repeat the complete pattern. Each correct sequence scores its length.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return GameStage(
      names: widget.names,
      scores: score,
      turn: turn,
      message:
          message.isEmpty
              ? '${widget.names[turn]}: ${widget.id == 21
                  ? 'tap the changed tile in the second scene'
                  : widget.id == 22
                  ? 'find the one matching object'
                  : 'watch and repeat the complete pattern'}'
              : message,
      child: content,
    );
  }
}
