import 'dart:math';

import 'bot_skill.dart';
import 'strategy_models.dart';

/// Secret bid for the computer in Treasure Auction.
///
/// It values a treasure at roughly 40% of its gems, spreads its coins over
/// the auctions that are left, and sometimes bids at random when it is not
/// "paying attention" (more often on Easy).
int botBid({
  required int value,
  required int coins,
  required int round,
  required Random random,
  required BotSkill skill,
}) {
  final cap = min(4, coins);
  if (cap <= 0) return 0;
  if (!skill.succeeds(random)) return random.nextInt(cap + 1);
  final left = max(1, 7 - round);
  final budget = coins / left * 1.8 + (value >= 8 ? 1 : 0);
  final wish = value / 2.4 + (random.nextDouble() - .5) * 1.6;
  return min(wish, budget).round().clamp(0, cap);
}

const _xSquares = {7, 10, 25, 28};

/// Picks a Reversi move for [player]: corners first, edges next, and it
/// avoids the squares beside a corner. On a failed accuracy roll it plays any
/// legal move. Returns null when there is no legal move.
int? reversiBotMove(
  ReversiBoard board,
  int player,
  Random random,
  BotSkill skill,
) {
  final moves = board.legal(player);
  if (moves.isEmpty) return null;
  if (!skill.succeeds(random)) return moves[random.nextInt(moves.length)];
  int? best;
  var bestScore = -1e9;
  for (final cell in moves) {
    final r = cell ~/ 6, c = cell % 6;
    final edgeRow = r == 0 || r == 5, edgeCol = c == 0 || c == 5;
    var score = board.captures(cell, player).length.toDouble();
    if (edgeRow && edgeCol) {
      score += 12;
    } else if (_xSquares.contains(cell)) {
      score -= 6;
    } else if (edgeRow || edgeCol) {
      score += 2;
    }
    score += random.nextDouble() * .5;
    if (score > bestScore) {
      bestScore = score;
      best = cell;
    }
  }
  return best;
}

/// The boxes touching an edge of the 3x3 Dots and Boxes board.
List<int> boxesOfEdge(int edge) {
  if (edge < 12) {
    final x = edge % 3, y = edge ~/ 3;
    return [if (y > 0) (y - 1) * 3 + x, if (y < 3) y * 3 + x];
  }
  final index = edge - 12, x = index % 4, y = index ~/ 4;
  return [if (x > 0) y * 3 + x - 1, if (x < 3) y * 3 + x];
}

/// Picks a Dots and Boxes edge: close a box when it can, otherwise draw an
/// edge that does not hand the rival a box (a third side), otherwise give
/// away as little as possible.
int dotsBotMove(DotsBoard board, Random random, BotSkill skill) {
  final free = [
    for (var i = 0; i < board.edges.length; i++)
      if (board.edges[i] == 0) i,
  ];
  int sides(int box) =>
      board.boundaries(box).where((e) => board.edges[e] != 0).length;
  if (skill.succeeds(random)) {
    final closing = [
      for (final e in free)
        if (boxesOfEdge(e).any((b) => board.owners[b] == 0 && sides(b) == 3)) e,
    ];
    if (closing.isNotEmpty) return closing[random.nextInt(closing.length)];
  }
  if (skill.succeeds(random)) {
    final safe = [
      for (final e in free)
        if (boxesOfEdge(e).every((b) => sides(b) < 2)) e,
    ];
    if (safe.isNotEmpty) return safe[random.nextInt(safe.length)];
    final cost = <int, int>{
      for (final e in free)
        e: boxesOfEdge(e).where((b) => sides(b) == 2).length,
    };
    final least = cost.values.reduce(min);
    final cheap = [
      for (final e in free)
        if (cost[e] == least) e,
    ];
    return cheap[random.nextInt(cheap.length)];
  }
  return free[random.nextInt(free.length)];
}

/// Picks a cell to shoot at on [enemy]'s 6x6 board: neighbours of earlier
/// hits first, then a checkerboard sweep (every ship is at least two cells
/// long, so half the board is enough to find them).
int fleetBotShot(FleetBoard enemy, Random random, BotSkill skill) {
  final shots = enemy.shots;
  final free = [
    for (var i = 0; i < 36; i++)
      if (!shots.contains(i)) i,
  ];
  if (skill.succeeds(random)) {
    final targets = <int>{};
    for (final hit in shots.where(enemy.ships.contains)) {
      final r = hit ~/ 6, c = hit % 6;
      for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final nr = r + dr, nc = c + dc;
        if (nr < 0 || nr > 5 || nc < 0 || nc > 5) continue;
        final n = nr * 6 + nc;
        if (!shots.contains(n)) targets.add(n);
      }
    }
    if (targets.isNotEmpty) {
      final list = targets.toList();
      return list[random.nextInt(list.length)];
    }
    final parity = [
      for (final i in free)
        if ((i ~/ 6 + i % 6).isEven) i,
    ];
    if (parity.isNotEmpty) return parity[random.nextInt(parity.length)];
  }
  return free[random.nextInt(free.length)];
}

/// Picks a Minesweeper cell using only what a player can see.
///
/// It reveals a cell it can prove safe from the numbers; otherwise it takes
/// the least risky guess. It never picks an open or flagged cell. Returns -1
/// when every closed cell is flagged.
int minesBotMove(MineBoard board, Random random, BotSkill skill) {
  final closed = [
    for (var i = 0; i < 36; i++)
      if (!board.revealed.contains(i) && !board.flags.contains(i)) i,
  ];
  if (closed.isEmpty) return -1;
  if (board.first || !skill.succeeds(random)) {
    return closed[random.nextInt(closed.length)];
  }
  final known = <int>{};
  final safe = <int>{};
  for (var pass = 0; pass < 3; pass++) {
    for (final cell in board.revealed) {
      if (board.mines.contains(cell)) continue;
      final clue = board.clue(cell);
      final hidden = [
        for (final n in board.neighbors(cell))
          if (!board.revealed.contains(n)) n,
      ];
      if (hidden.isEmpty) continue;
      final mined = hidden.where(known.contains).length;
      final unknown = hidden.where((n) => !known.contains(n)).toList();
      if (unknown.isNotEmpty && unknown.length == clue - mined) {
        known.addAll(unknown);
      } else if (clue == mined) {
        safe.addAll(unknown);
      }
    }
  }
  final sure = [
    for (final c in closed)
      if (safe.contains(c) && !known.contains(c)) c,
  ];
  if (sure.isNotEmpty) return sure[random.nextInt(sure.length)];
  // No certain move: estimate the risk of each cell.
  final risk = <int, double>{};
  final remaining = max(1, 6 - known.length);
  final unseen = closed.where((c) => !known.contains(c)).length;
  final density = remaining / max(1, unseen);
  for (final cell in board.revealed) {
    if (board.mines.contains(cell)) continue;
    final clue = board.clue(cell);
    final hidden = [
      for (final n in board.neighbors(cell))
        if (!board.revealed.contains(n)) n,
    ];
    final mined = hidden.where(known.contains).length;
    final unknown = hidden.where((n) => !known.contains(n)).toList();
    if (unknown.isEmpty) continue;
    final p = ((clue - mined) / unknown.length).clamp(0.0, 1.0);
    for (final n in unknown) {
      risk[n] = max(risk[n] ?? 0, p);
    }
  }
  var bestRisk = 2.0;
  final best = <int>[];
  for (final c in closed) {
    if (known.contains(c)) continue;
    final r = risk[c] ?? density;
    if (r < bestRisk - 1e-9) {
      bestRisk = r;
      best
        ..clear()
        ..add(c);
    } else if ((r - bestRisk).abs() <= 1e-9) {
      best.add(c);
    }
  }
  if (best.isEmpty) return closed[random.nextInt(closed.length)];
  return best[random.nextInt(best.length)];
}

/// A Mastermind solver for Code Breaker.
///
/// It keeps every code that is consistent with the feedback so far and
/// guesses one of them, which cracks a 4-of-6 code in about five tries. On a
/// failed accuracy roll it guesses at random instead.
class CodeSolver {
  List<List<int>> _candidates = [
    for (var a = 0; a < 6; a++)
      for (var b = 0; b < 6; b++)
        for (var c = 0; c < 6; c++)
          for (var d = 0; d < 6; d++) [a, b, c, d],
  ];

  /// How many codes are still possible.
  int get remaining => _candidates.length;

  /// The next guess to try.
  List<int> next(Random random, BotSkill skill) {
    if (_candidates.isEmpty || !skill.succeeds(random)) {
      return [for (var i = 0; i < 4; i++) random.nextInt(6)];
    }
    return List<int>.of(_candidates[random.nextInt(_candidates.length)]);
  }

  /// Records the feedback for [guess] and drops the codes it rules out.
  void learn(List<int> guess, int exact, int misplaced) {
    _candidates =
        _candidates.where((code) {
          final f = evaluateCode(code, guess);
          return f.exact == exact && f.misplaced == misplaced;
        }).toList();
  }
}
