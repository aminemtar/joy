import 'dart:math';
import 'party_data.dart';

bool lineWin(List<int> board, int width, int needed, int player) {
  for (var i = 0; i < board.length; i++) {
    if (board[i] != player) continue;
    for (final d in [(0, 1), (1, 0), (1, 1), (1, -1)]) {
      var count = 1;
      for (var n = 1; n < needed; n++) {
        final r = i ~/ width + d.$1 * n, c = i % width + d.$2 * n;
        if (r < 0 ||
            c < 0 ||
            r >= board.length ~/ width ||
            c >= width ||
            board[r * width + c] != player) {
          break;
        }
        count++;
      }
      if (count >= needed) return true;
    }
  }
  return false;
}

int? computerMove(
  List<int> board,
  int width,
  Difficulty difficulty,
  Random random,
) {
  final connect = width == 7;
  final legal = <int>[];
  if (connect) {
    for (var c = 0; c < 7; c++) {
      for (var r = 5; r >= 0; r--) {
        if (board[r * 7 + c] == 0) {
          legal.add(r * 7 + c);
          break;
        }
      }
    }
  } else {
    for (var i = 0; i < board.length; i++) {
      if (board[i] == 0) legal.add(i);
    }
  }
  if (legal.isEmpty) return null;
  if (difficulty == Difficulty.easy) return legal[random.nextInt(legal.length)];
  final needed = connect ? 4 : 3;
  for (final player in [2, 1]) {
    for (final i in legal) {
      final next = List<int>.of(board)..[i] = player;
      if (lineWin(next, width, needed, player)) return i;
    }
  }
  if (!connect && difficulty == Difficulty.hard) {
    int minimax(List<int> b, bool bot) {
      if (lineWin(b, 3, 3, 2)) return 10;
      if (lineWin(b, 3, 3, 1)) return -10;
      final empty = [
        for (var i = 0; i < 9; i++)
          if (b[i] == 0) i,
      ];
      if (empty.isEmpty) return 0;
      final values = [
        for (final i in empty)
          minimax(List<int>.of(b)..[i] = bot ? 2 : 1, !bot),
      ];
      return bot ? values.reduce(max) : values.reduce(min);
    }

    legal.shuffle(random);
    legal.sort(
      (a, b) => minimax(
        List<int>.of(board)..[b] = 2,
        false,
      ).compareTo(minimax(List<int>.of(board)..[a] = 2, false)),
    );
    return legal.first;
  }
  if (connect && difficulty == Difficulty.hard) {
    // Prefer safe central columns; avoid giving the human an immediate win.
    final safe =
        legal.where((i) {
          final b = List<int>.of(board)..[i] = 2;
          for (var c = 0; c < 7; c++) {
            for (var r = 5; r >= 0; r--) {
              if (b[r * 7 + c] == 0) {
                if (lineWin(List<int>.of(b)..[r * 7 + c] = 1, 7, 4, 1)) {
                  return false;
                }
                break;
              }
            }
          }
          return true;
        }).toList();
    if (safe.isNotEmpty) {
      safe.sort((a, b) => (a % 7 - 3).abs().compareTo((b % 7 - 3).abs()));
      return safe.first;
    }
  }
  if (legal.contains(4) && !connect) return 4;
  return legal[random.nextInt(legal.length)];
}
