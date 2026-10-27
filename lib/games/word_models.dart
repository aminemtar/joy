import 'dart:math';

class CrosswordClue {
  final String word, clue;
  final int row, col;
  final bool across;
  const CrosswordClue(this.word, this.clue, this.row, this.col, this.across);
  List<int> get cells => List.generate(
    word.length,
    (i) => (row + (across ? 0 : i)) * 7 + col + (across ? i : 0),
  );
}

const crosswordPacks = <List<CrosswordClue>>[
  [
    CrosswordClue('PLANETS', 'Worlds orbiting a star', 3, 0, true),
    CrosswordClue('APPLE', 'Fruit that can be red or gold', 1, 0, false),
    CrosswordClue('CAN', 'Metal container for a drink', 2, 2, false),
    CrosswordClue('TREE', 'A tall plant with a trunk', 1, 4, false),
    CrosswordClue('STAR', 'A point of light in the night sky', 3, 6, false),
  ],
  [
    CrosswordClue('FLOWERS', 'Colorful blooms in a garden', 3, 0, true),
    CrosswordClue('SURF', 'Ride ocean waves', 0, 0, false),
    CrosswordClue('MOON', 'Earth’s natural satellite', 2, 2, false),
    CrosswordClue('TREE', 'A plant with branches', 1, 4, false),
    CrosswordClue('STAR', 'Our Sun is one', 3, 6, false),
  ],
  [
    CrosswordClue('ROCKETS', 'Vehicles launched into space', 3, 0, true),
    CrosswordClue('STAR', 'A shining ball of hot gas', 0, 0, false),
    CrosswordClue('ICE', 'Frozen water', 2, 2, false),
    CrosswordClue('TREE', 'It has roots and leaves', 1, 4, false),
    CrosswordClue('SUN', 'The star at the center of our system', 3, 6, false),
  ],
  [
    CrosswordClue('GARDENS', 'Places where flowers are grown', 3, 0, true),
    CrosswordClue('DOG', 'An animal that barks', 1, 0, false),
    CrosswordClue('BIRD', 'An animal with feathers', 1, 2, false),
    CrosswordClue('BEE', 'An insect that makes honey', 1, 4, false),
    CrosswordClue('SUN', 'It gives Earth daylight', 3, 6, false),
  ],
];

class CrosswordBoard {
  final List<CrosswordClue> clues;
  final solution = <int, String>{}, confirmed = <int, String>{};
  final solved = <int>{};
  CrosswordBoard(this.clues) {
    for (final clue in clues) {
      for (var i = 0; i < clue.word.length; i++) {
        final cell = clue.cells[i], letter = clue.word[i];
        if (solution.containsKey(cell) && solution[cell] != letter) {
          throw ArgumentError('Invalid crossword crossing');
        }
        solution[cell] = letter;
      }
    }
  }
  bool check(int clue, Map<int, String> entry) => clues[clue].cells.every(
    (cell) => (confirmed[cell] ?? entry[cell]) == solution[cell],
  );
  void confirm(int clue) {
    solved.add(clue);
    for (final cell in clues[clue].cells) {
      confirmed[cell] = solution[cell]!;
    }
  }
}

class WordSearchBoard {
  static const words = ['STAR', 'MOON', 'BALL', 'CODE', 'JOY', 'CAR'];
  final letters = List.filled(64, '');
  final placements = <String, List<int>>{};
  WordSearchBoard(Random random) {
    for (final word in words) {
      var placed = false;
      for (var attempt = 0; attempt < 1000 && !placed; attempt++) {
        final directions = [
          [-1, -1],
          [-1, 0],
          [-1, 1],
          [0, -1],
          [0, 1],
          [1, -1],
          [1, 0],
          [1, 1],
        ];
        final d = directions[random.nextInt(8)],
            r = random.nextInt(8),
            c = random.nextInt(8);
        final er = r + d[0] * (word.length - 1),
            ec = c + d[1] * (word.length - 1);
        if (er < 0 || er >= 8 || ec < 0 || ec >= 8) continue;
        final cells = [
          for (var i = 0; i < word.length; i++)
            (r + d[0] * i) * 8 + c + d[1] * i,
        ];
        if (List.generate(
          word.length,
          (i) => letters[cells[i]].isEmpty || letters[cells[i]] == word[i],
        ).every((b) => b)) {
          for (var i = 0; i < word.length; i++) {
            letters[cells[i]] = word[i];
          }
          placements[word] = cells;
          placed = true;
        }
      }
      if (!placed) throw StateError('Could not place word');
    }
    for (var i = 0; i < 64; i++) {
      if (letters[i].isEmpty) {
        letters[i] = String.fromCharCode(65 + random.nextInt(26));
      }
    }
  }
  List<int> line(int start, int end) {
    final dr = end ~/ 8 - start ~/ 8, dc = end % 8 - start % 8;
    if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return [];
    final n = max(dr.abs(), dc.abs());
    return [
      for (var i = 0; i <= n; i++)
        (start ~/ 8 + dr.sign * i) * 8 + start % 8 + dc.sign * i,
    ];
  }

  String? match(List<int> cells, Set<String> found) {
    final text = cells.map((i) => letters[i]).join(),
        reverse = text.split('').reversed.join();
    for (final word in words) {
      if (!found.contains(word) && (text == word || reverse == word)) {
        return word;
      }
    }
    return null;
  }
}
