import '../sound.dart';
import 'dart:async';
import '../party_data.dart';
import '../practice_ai.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'flip_card.dart';
import 'game_stage.dart';
import '../players.dart' show leadingPlayer;

class PuzzleGame extends StatefulWidget {
  final int id;
  final List<String> names;
  final ValueChanged<int> onFinish;
  const PuzzleGame({
    super.key,
    required this.id,
    required this.names,
    required this.onFinish,
  });
  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  Timer? botTimer;
  final botRandom = Random();
  late List<int> board;
  int turn = 0;
  late final List<int> score;
  final open = <int>[];
  final matched = <int>{};
  bool locked = false, over = false;
  late int width;
  final pos = [0, 35];
  final walls = <int>{};
  @override
  void initState() {
    super.initState();
    score = List.filled(widget.names.length, 0);
    width =
        widget.id == 18
            ? 7
            : widget.id == 20
            ? 4
            : widget.id == 17
            ? 6
            : 3;
    board = List.filled(widget.id == 18 ? 42 : width * width, 0);
    if (widget.id == 15) {
      board = List.generate(9, (i) => (i + 1) % 9);
      var gap = 8, previous = -1;
      final r = Random();
      for (var i = 0; i < 90; i++) {
        final choices = [
          for (var j = 0; j < 9; j++)
            if (_adj(gap, j, 3) && j != previous) j,
        ];
        final n = choices[r.nextInt(choices.length)];
        board[gap] = board[n];
        board[n] = 0;
        previous = gap;
        gap = n;
      }
      if (_solved()) {
        board[8] = 8;
        board[7] = 0;
      }
    }
    if (widget.id == 20) {
      board = [
        for (var i = 0; i < 8; i++) ...[i + 1, i + 1],
      ]..shuffle();
    }
    if (widget.id == 17) {
      walls.addAll([8, 10, 14, 16, 19, 22, 25, 27]);
    }
  }

  @override
  void dispose() {
    botTimer?.cancel();
    super.dispose();
  }

  void scheduleComputer() {
    final options = MatchOptions.read(context);
    if (options?.computer != true ||
        turn != 1 ||
        over ||
        ![18, 19].contains(widget.id)) {
      return;
    }
    botTimer?.cancel();
    botTimer = Timer(
      Duration(
        milliseconds: options!.difficulty == Difficulty.easy ? 1000 : 650,
      ),
      () {
        if (!mounted || over || turn != 1) return;
        final move = computerMove(board, width, options.difficulty, botRandom);
        if (move != null) play(move, bot: true);
      },
    );
  }

  bool _adj(int a, int b, int w) =>
      (a ~/ w - b ~/ w).abs() + (a % w - b % w).abs() == 1;
  bool _solved() => List.generate(
    9,
    (i) => (i + 1) % 9,
  ).asMap().entries.every((e) => board[e.key] == e.value);
  void end(int p) {
    if (over) return;
    over = true;
    widget.onFinish(p);
  }

  void play(int index, {bool bot = false}) async {
    if (locked ||
        over ||
        (MatchOptions.read(context)?.computer == true && turn == 1 && !bot)) {
      return;
    }
    if (widget.id == 20) {
      if (matched.contains(index) || open.contains(index)) return;
      JoySounds.instance.play(SoundEffect.flip);
      setState(() => open.add(index));
      if (open.length == 2) {
        locked = true;
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        if (!mounted) return;
        setState(() {
          if (board[open[0]] == board[open[1]]) {
            matched.addAll(open);
            JoySounds.instance.play(SoundEffect.correct);
            score[turn]++;
          } else {
            JoySounds.instance.play(SoundEffect.wrong);
            turn = (turn + 1) % widget.names.length;
          }
          open.clear();
        });
        await Future<void>.delayed(const Duration(milliseconds: 440));
        if (!mounted) return;
        setState(() => locked = false);
        if (matched.length == 16) {
          end(leadingPlayer(score));
        }
      }
      return;
    }
    setState(() {
      if (widget.id == 15) {
        final gap = board.indexOf(0);
        if (!_adj(gap, index, 3)) return;
        JoySounds.instance.play(SoundEffect.tap);
        board[gap] = board[index];
        board[index] = 0;
        if (_solved()) {
          end(turn);
          return;
        }
        turn = (turn + 1) % widget.names.length;
        return;
      }
      if (widget.id == 17) {
        if (walls.contains(index) ||
            index == pos[1 - turn] ||
            !_adj(pos[turn], index, 6)) {
          return;
        }
        JoySounds.instance.play(SoundEffect.tap);
        pos[turn] = index;
        if (index == (turn == 0 ? 35 : 0)) {
          end(turn);
          return;
        }
        turn = (turn + 1) % widget.names.length;
        return;
      }
      var target = index;
      if (widget.id == 18) {
        final col = index % 7;
        target = -1;
        for (var row = 5; row >= 0; row--) {
          if (board[row * 7 + col] == 0) {
            target = row * 7 + col;
            break;
          }
        }
        if (target < 0) return;
      }
      if (board[target] != 0) return;
      JoySounds.instance.play(SoundEffect.tap);
      board[target] = turn + 1;
      final w = width, needed = widget.id == 18 ? 4 : 3;
      for (final d in [
        [0, 1],
        [1, 0],
        [1, 1],
        [1, -1],
      ]) {
        var count = 1;
        for (final sign in [-1, 1]) {
          for (var step = 1; step < needed; step++) {
            final r = target ~/ w + d[0] * step * sign,
                c = target % w + d[1] * step * sign;
            if (r < 0 ||
                r >= board.length ~/ w ||
                c < 0 ||
                c >= w ||
                board[r * w + c] != turn + 1) {
              break;
            }
            count++;
          }
        }
        if (count >= needed) {
          end(turn);
          return;
        }
      }
      if (!board.contains(0)) {
        end(-1);
        return;
      }
      turn = (turn + 1) % widget.names.length;
    });
    scheduleComputer();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id == 20) {
      return GameStage(
        names: widget.names,
        scores: score,
        turn: turn,
        message:
            locked
                ? 'Remember the revealed pair…'
                : 'Find a matching pair • ${matched.length ~/ 2} / 8',
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: matched.length / 16,
                minHeight: 6,
                color: Colors.amber,
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(height: 22),
            boardGrid(
              16,
              4,
              (i) => FlipMatchCard(
                key: ValueKey('memory-$i'),
                index: i,
                faceUp: matched.contains(i) || open.contains(i),
                matched: matched.contains(i),
                enabled:
                    !locked &&
                    !over &&
                    !open.contains(i) &&
                    !matched.contains(i),
                artId: const [0, 5, 8, 11, 12, 19, 22, 29][board[i] - 1],
                onTap: () => play(i),
              ),
              spacing: 12,
            ),
            const SizedBox(height: 24),
            const Text(
              'Match a pair to keep your turn.\nUnmatched cards turn back over.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }
    return GameStage(
      names: widget.names,
      scores: score,
      turn: turn,
      message: '${widget.names[turn]}’s turn',
      child: Column(
        children: [
          boardGrid(board.length, width, (i) {
            String label = '';
            Color color = const Color(0xFF1C294A);
            if (widget.id == 15) {
              label = board[i] == 0 ? '' : '${board[i]}';
            } else if (widget.id == 20) {
              label = '?';
              if (matched.contains(i)) color = const Color(0xFF334C79);
            } else if (widget.id == 17) {
              label =
                  walls.contains(i)
                      ? '▪'
                      : i == pos[0]
                      ? '🔵'
                      : i == pos[1]
                      ? '🔴'
                      : i == 0 || i == 35
                      ? '🏁'
                      : '';
              if (walls.contains(i)) color = Colors.black;
            } else {
              label =
                  board[i] == 0
                      ? ''
                      : widget.id == 19
                      ? (board[i] == 1 ? '✕' : '○')
                      : PartyData.instance.colorSymbols
                      ? (board[i] == 1 ? '▲' : '■')
                      : '●';
              if (board[i] != 0) {
                color =
                    board[i] == 1
                        ? const Color(0xFF507CFF)
                        : const Color(0xFFFF6F83);
              }
            }
            return Material(
              color: color,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => play(i),
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text(
            'Take turns on the same board',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
