import 'dart:math';

import 'package:flutter/material.dart';

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
  late List<int> board;
  int turn = 0;
  final score = [0, 0];
  final open = <int>[];
  final matched = <int>{};
  bool locked = false, over = false;
  late int width;
  final pos = [0, 35];
  final walls = <int>{};
  @override
  void initState() {
    super.initState();
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

  void play(int index) async {
    if (locked || over) return;
    if (widget.id == 20) {
      if (matched.contains(index) || open.contains(index)) return;
      setState(() => open.add(index));
      if (open.length == 2) {
        locked = true;
        await Future<void>.delayed(const Duration(milliseconds: 750));
        if (!mounted) return;
        setState(() {
          if (board[open[0]] == board[open[1]]) {
            matched.addAll(open);
            score[turn]++;
          } else {
            turn = 1 - turn;
          }
          open.clear();
          locked = false;
        });
        if (matched.length == 16) {
          end(
            score[0] == score[1]
                ? -1
                : score[0] > score[1]
                ? 0
                : 1,
          );
        }
      }
      return;
    }
    setState(() {
      if (widget.id == 15) {
        final gap = board.indexOf(0);
        if (!_adj(gap, index, 3)) return;
        board[gap] = board[index];
        board[index] = 0;
        if (_solved()) {
          end(turn);
          return;
        }
        turn = 1 - turn;
        return;
      }
      if (widget.id == 17) {
        if (walls.contains(index) ||
            index == pos[1 - turn] ||
            !_adj(pos[turn], index, 6)) {
          return;
        }
        pos[turn] = index;
        if (index == (turn == 0 ? 35 : 0)) {
          end(turn);
          return;
        }
        turn = 1 - turn;
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
      board[target] = turn + 1;
      if (widget.id == 16) {
        final r = target ~/ 3, c = target % 3;
        bool row = true, col = true;
        for (var k = 0; k < 3; k++) {
          row &= board[r * 3 + k] != 0;
          col &= board[k * 3 + c] != 0;
        }
        score[turn] += (row ? 1 : 0) + (col ? 1 : 0);
      } else {
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
      }
      if (!board.contains(0)) {
        end(
          widget.id == 16
              ? (score[0] == score[1]
                  ? -1
                  : score[0] > score[1]
                  ? 0
                  : 1)
              : -1,
        );
        return;
      }
      turn = 1 - turn;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${widget.names[turn]}’s turn   •   ${score[0]} : ${score[1]}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      Expanded(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: board.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (c, i) {
                String label = '';
                Color color = const Color(0xFF1C294A);
                if (widget.id == 15) {
                  label = board[i] == 0 ? '' : '${board[i]}';
                } else if (widget.id == 20) {
                  label =
                      matched.contains(i) || open.contains(i)
                          ? [
                            '',
                            '🍒',
                            '🐳',
                            '🍋',
                            '🚀',
                            '🎸',
                            '🦊',
                            '🌙',
                            '💎',
                          ][board[i]]
                          : '?';
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
              },
            ),
          ),
        ),
      ),
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Pass-and-play • Take turns on the same board',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    ],
  );
}
