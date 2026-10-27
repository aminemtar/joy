import 'dart:math';

class ReversiBoard {
  final cells = List.filled(36, 0);
  ReversiBoard() {
    cells[14] = 1;
    cells[21] = 1;
    cells[15] = 2;
    cells[20] = 2;
  }
  List<int> captures(int cell, int player) {
    if (cells[cell] != 0) return [];
    final result = <int>[];
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        var r = cell ~/ 6 + dr, c = cell % 6 + dc;
        final line = <int>[];
        while (r >= 0 &&
            r < 6 &&
            c >= 0 &&
            c < 6 &&
            cells[r * 6 + c] == 3 - player) {
          line.add(r * 6 + c);
          r += dr;
          c += dc;
        }
        if (r >= 0 && r < 6 && c >= 0 && c < 6 && cells[r * 6 + c] == player) {
          result.addAll(line);
        }
      }
    }
    return result;
  }

  List<int> legal(int player) => [
    for (var i = 0; i < 36; i++)
      if (captures(i, player).isNotEmpty) i,
  ];
  bool play(int cell, int player) {
    final flip = captures(cell, player);
    if (flip.isEmpty) return false;
    cells[cell] = player;
    for (final i in flip) {
      cells[i] = player;
    }
    return true;
  }
}

class DotsBoard {
  final edges = List.filled(24, 0), owners = List.filled(9, 0);
  List<int> boundaries(int box) {
    final r = box ~/ 3, c = box % 3;
    return [r * 3 + c, (r + 1) * 3 + c, 12 + r * 4 + c, 12 + r * 4 + c + 1];
  }

  int play(int edge, int player) {
    if (edges[edge] != 0) return -1;
    edges[edge] = player;
    var gained = 0;
    for (var b = 0; b < 9; b++) {
      if (owners[b] == 0 && boundaries(b).every((e) => edges[e] != 0)) {
        owners[b] = player;
        gained++;
      }
    }
    return gained;
  }
}

class FleetBoard {
  final ships = <int>{}, shots = <int>{};
  FleetBoard(Random random) {
    for (final length in [3, 2, 2]) {
      for (var attempt = 0; attempt < 1000; attempt++) {
        final horizontal = random.nextBool(),
            r = random.nextInt(6),
            c = random.nextInt(6);
        if ((horizontal ? c : r) + length > 6) continue;
        final proposed = [
          for (var i = 0; i < length; i++)
            (r + (horizontal ? 0 : i)) * 6 + c + (horizontal ? i : 0),
        ];
        if (proposed.any(ships.contains)) continue;
        ships.addAll(proposed);
        break;
      }
    }
  }
  bool fire(int cell) {
    shots.add(cell);
    return ships.contains(cell);
  }

  bool get sunk => ships.every(shots.contains);
}

class CodeFeedback {
  final int exact, misplaced;
  const CodeFeedback(this.exact, this.misplaced);
}

CodeFeedback evaluateCode(List<int> secret, List<int> guess) {
  var exact = 0;
  final a = <int, int>{}, b = <int, int>{};
  for (var i = 0; i < secret.length; i++) {
    if (secret[i] == guess[i]) {
      exact++;
    } else {
      a.update(secret[i], (v) => v + 1, ifAbsent: () => 1);
      b.update(guess[i], (v) => v + 1, ifAbsent: () => 1);
    }
  }
  var misplaced = 0;
  for (final k in a.keys) {
    misplaced += min(a[k]!, b[k] ?? 0);
  }
  return CodeFeedback(exact, misplaced);
}

class MineBoard {
  final mines = <int>{}, revealed = <int>{}, flags = <int>{};
  final Random random;
  bool first = true;
  MineBoard(this.random) {
    while (mines.length < 6) {
      mines.add(random.nextInt(36));
    }
  }
  Iterable<int> neighbors(int cell) sync* {
    final r = cell ~/ 6, c = cell % 6;
    for (var y = max(0, r - 1); y <= min(5, r + 1); y++) {
      for (var x = max(0, c - 1); x <= min(5, c + 1); x++) {
        if (y * 6 + x != cell) yield y * 6 + x;
      }
    }
  }

  int clue(int cell) => neighbors(cell).where(mines.contains).length;
  int reveal(int cell) {
    if (revealed.contains(cell) || flags.contains(cell)) return 0;
    if (first) {
      first = false;
      if (mines.remove(cell)) {
        final free = [
          for (var i = 0; i < 36; i++)
            if (i != cell && !mines.contains(i)) i,
        ];
        mines.add(free[random.nextInt(free.length)]);
      }
    }
    if (mines.contains(cell)) {
      revealed.add(cell);
      return -1;
    }
    final before = revealed.length, queue = [cell];
    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      if (revealed.contains(i) || mines.contains(i) || flags.contains(i)) {
        continue;
      }
      revealed.add(i);
      if (clue(i) == 0) queue.addAll(neighbors(i));
    }
    return revealed.length - before;
  }

  bool get complete => revealed.where((i) => !mines.contains(i)).length == 30;
}
