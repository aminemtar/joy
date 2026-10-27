import 'dart:math';
import 'package:flutter/material.dart';
import 'game_stage.dart';
import 'word_models.dart';

class WordsGame extends StatefulWidget {
  final int id;
  final List<String> names;
  final ValueChanged<int> onFinish;
  const WordsGame({
    super.key,
    required this.id,
    required this.names,
    required this.onFinish,
  });
  @override
  State<WordsGame> createState() => _WordsGameState();
}

class _WordsGameState extends State<WordsGame> {
  final random = Random(), scores = [0, 0];
  int turn = 0, selected = 0, cursor = 0;
  bool done = false;
  String message = '';
  late final CrosswordBoard crossword;
  late final WordSearchBoard search;
  final entry = <int, String>{}, found = <String>{}, marked = <int>{};
  int? start;
  List<int> selection = [];
  String word = '';
  List<String> letters = [];
  final picked = <int>[];
  static const bank = [
    'PLANET',
    'ROCKET',
    'PUZZLE',
    'FRIEND',
    'MUSIC',
    'OCEAN',
    'BRIDGE',
    'SILVER',
    'CASTLE',
    'ORANGE',
    'CANDLE',
    'JUNGLE',
    'WINTER',
    'BOTTLE',
    'PENCIL',
    'CLOUD',
  ];
  @override
  void initState() {
    super.initState();
    crossword = CrosswordBoard(
      crosswordPacks[random.nextInt(crosswordPacks.length)],
    );
    search = WordSearchBoard(random);
    newWord();
  }

  void newWord() {
    word = bank[random.nextInt(bank.length)];
    letters = word.split('')..shuffle(random);
    if (letters.join() == word) {
      letters = letters.reversed.toList();
    }
    picked.clear();
  }

  void end() {
    if (done) return;
    done = true;
    widget.onFinish(
      scores[0] == scores[1]
          ? -1
          : scores[0] > scores[1]
          ? 0
          : 1,
    );
  }

  void chooseClue(int index) {
    if (done || crossword.solved.contains(index)) return;
    setState(() {
      selected = index;
      entry.clear();
      cursor = 0;
      skipConfirmed();
      message = '';
    });
  }

  void skipConfirmed() {
    final cells = crossword.clues[selected].cells;
    while (cursor < cells.length &&
        crossword.confirmed.containsKey(cells[cursor])) {
      cursor++;
    }
  }

  void letter(String value) {
    if (done) return;
    final cells = crossword.clues[selected].cells;
    if (cursor >= cells.length) return;
    setState(() {
      entry[cells[cursor]] = value;
      cursor++;
      skipConfirmed();
    });
  }

  void checkCrossword() {
    if (done || crossword.solved.contains(selected)) return;
    setState(() {
      if (crossword.check(selected, entry)) {
        crossword.confirm(selected);
        scores[turn] += crossword.clues[selected].word.length;
        message = 'Correct — crossing letters are now locked.';
      } else {
        message = 'Not quite. Turn passes; crossing letters stay.';
      }
      entry.clear();
      turn = 1 - turn;
      if (crossword.solved.length == crossword.clues.length) {
        end();
        return;
      }
      selected = List.generate(
        crossword.clues.length,
        (i) => i,
      ).firstWhere((i) => !crossword.solved.contains(i));
      cursor = 0;
      skipConfirmed();
    });
  }

  void checkScramble() {
    if (picked.length != letters.length || done) return;
    setState(() {
      if (picked.map((i) => letters[i]).join() == word) {
        scores[turn]++;
        message = 'Correct!';
      } else {
        message = 'The word was $word.';
      }
      if (scores[turn] >= 5) {
        end();
        return;
      }
      turn = 1 - turn;
      newWord();
    });
  }

  int cellAt(Offset point, double size) =>
      ((point.dy / size * 8).floor().clamp(0, 7)) * 8 +
      (point.dx / size * 8).floor().clamp(0, 7);
  void finishSearch() {
    if (done || selection.isEmpty) return;
    setState(() {
      final match = search.match(selection, found);
      if (match != null) {
        found.add(match);
        marked.addAll(selection);
        scores[turn] += match.length;
        message = 'Found $match!';
      } else {
        message = 'No new word on that line.';
      }
      selection = [];
      start = null;
      turn = 1 - turn;
      if (found.length == WordSearchBoard.words.length) end();
    });
  }

  Widget crosswordView() {
    final clue = crossword.clues[selected], cells = clue.cells;
    final numbers = <int, int>{};
    for (var i = 0; i < crossword.clues.length; i++) {
      numbers[crossword.clues[i].cells.first] = i + 1;
    }
    return Column(
      children: [
        boardGrid(49, 7, (i) {
          if (!crossword.solution.containsKey(i)) return const SizedBox();
          final confirmed = crossword.confirmed[i];
          return gameTile(
            selected: cells.contains(i),
            color:
                confirmed != null
                    ? const Color(0xFF2D416C)
                    : cells.contains(i)
                    ? const Color(0xFF28365C)
                    : const Color(0xFF1C294A),
            onTap: () {
              if (cells.contains(i) && confirmed == null) {
                setState(() => cursor = cells.indexOf(i));
              } else {
                for (var n = 0; n < crossword.clues.length; n++) {
                  if (crossword.clues[n].cells.contains(i) &&
                      !crossword.solved.contains(n)) {
                    chooseClue(n);
                    break;
                  }
                }
              }
            },
            child: Stack(
              children: [
                if (numbers.containsKey(i))
                  Positioned(
                    left: 3,
                    top: 1,
                    child: Text(
                      '${numbers[i]}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                Center(
                  child: Text(
                    confirmed ?? entry[i] ?? '',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (cursor < cells.length && cells[cursor] == i)
                  const Positioned(
                    bottom: 4,
                    left: 8,
                    right: 8,
                    child: ColoredBox(
                      color: Colors.amber,
                      child: SizedBox(height: 2),
                    ),
                  ),
              ],
            ),
          );
        }, spacing: 3),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          children: [
            for (var i = 0; i < crossword.clues.length; i++)
              ChoiceChip(
                label: Text(
                  '${i + 1} ${crossword.clues[i].across ? 'Across' : 'Down'}${crossword.solved.contains(i) ? ' ✓' : ''}',
                ),
                selected: selected == i,
                onSelected:
                    crossword.solved.contains(i) ? null : (_) => chooseClue(i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${selected + 1}. ${clue.clue} (${clue.word.length})',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder:
              (c, box) => Wrap(
                alignment: WrapAlignment.center,
                spacing: 3,
                runSpacing: 4,
                children: [
                  for (final key in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
                    SizedBox(
                      width: (box.maxWidth - 27) / 10,
                      height: 40,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        onPressed: () => letter(key),
                        child: Text(key),
                      ),
                    ),
                ],
              ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  final editable =
                      cells
                          .where((i) => !crossword.confirmed.containsKey(i))
                          .toList();
                  final filled = editable.where(entry.containsKey).toList();
                  if (filled.isNotEmpty) {
                    final last = filled.last;
                    entry.remove(last);
                    cursor = cells.indexOf(last);
                  }
                });
              },
              child: const Text('Erase'),
            ),
            FilledButton(
              onPressed: () => checkCrossword(),
              child: const Text('Check word'),
            ),
          ],
        ),
      ],
    );
  }

  Widget searchView() => Column(
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          for (final word in WordSearchBoard.words)
            Text(
              word,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: found.contains(word) ? Colors.amber : Colors.white70,
                decoration:
                    found.contains(word) ? TextDecoration.lineThrough : null,
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder:
              (c, box) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) {
                  if (done) return;
                  setState(() {
                    start = cellAt(d.localPosition, box.maxWidth);
                    selection = [start!];
                  });
                },
                onPanUpdate: (d) {
                  if (start != null && !done) {
                    setState(
                      () =>
                          selection = search.line(
                            start!,
                            cellAt(d.localPosition, box.maxWidth),
                          ),
                    );
                  }
                },
                onPanEnd: (_) => finishSearch(),
                onPanCancel:
                    () => setState(() {
                      selection = [];
                      start = null;
                    }),
                child: IgnorePointer(
                  child: boardGrid(
                    64,
                    8,
                    (i) => gameTile(
                      selected: selection.contains(i),
                      color:
                          marked.contains(i)
                              ? const Color(0xFF4C426B)
                              : const Color(0xFF1C294A),
                      child: Text(
                        search.letters[i],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                    ),
                    spacing: 3,
                  ),
                ),
              ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Drag across a straight line: horizontal, vertical or diagonal. Words may run backwards.',
        textAlign: TextAlign.center,
      ),
    ],
  );
  Widget scrambleView() => Column(
    children: [
      const Icon(
        Icons.sort_by_alpha_rounded,
        color: Color(0xFF709AFF),
        size: 70,
      ),
      const SizedBox(height: 20),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < word.length; i++)
            Container(
              width: 38,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF24355B),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                i < picked.length ? letters[picked[i]] : '',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 26),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < letters.length; i++)
            SizedBox(
              width: 48,
              height: 52,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                onPressed:
                    picked.contains(i)
                        ? null
                        : () => setState(() => picked.add(i)),
                child: Text(letters[i], style: const TextStyle(fontSize: 23)),
              ),
            ),
        ],
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 12,
        children: [
          TextButton(
            onPressed:
                picked.isEmpty
                    ? null
                    : () => setState(() => picked.removeLast()),
            child: const Text('Undo'),
          ),
          FilledButton(
            onPressed: picked.length == word.length ? checkScramble : null,
            child: const Text('Submit word'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const Text(
        'Build the word from the loose letters. First to 5 words wins.',
        textAlign: TextAlign.center,
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => GameStage(
    names: widget.names,
    scores: scores,
    turn: turn,
    message: message.isEmpty ? '${widget.names[turn]}’s turn' : message,
    child:
        widget.id == 30
            ? crosswordView()
            : widget.id == 31
            ? searchView()
            : scrambleView(),
  );
}
