import '../sound.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'bot_skill.dart';
import 'game_stage.dart';
import '../players.dart' show leadingPlayer;
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
  final random = Random();
  late final List<int> scores;
  int turn = 0, selected = 0, cursor = 0;
  bool done = false;
  String message = '';
  late final CrosswordBoard crossword;
  late final WordSearchBoard search;
  final entry = <int, String>{}, found = <String>{}, marked = <int>{};
  int? start;
  Timer? botTimer;
  int botWrongCell = -1;
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
    scores = List.filled(widget.names.length, 0);
    crossword = CrosswordBoard(
      crosswordPacks[random.nextInt(crosswordPacks.length)],
    );
    search = WordSearchBoard(random);
    newWord();
  }

  @override
  void dispose() {
    botTimer?.cancel();
    super.dispose();
  }

  /// Whether the match is against the computer, which plays as player 2.
  bool get vsComputer => BotSkill.isComputer(context);

  /// Whether the computer is the one playing right now.
  bool get botTurn => vsComputer && turn == 1 && !done;

  /// Plans the computer's turn. Nothing is scheduled once the match is over.
  void scheduleBot() {
    botTimer?.cancel();
    if (!botTurn) return;
    final skill = BotSkill.of(context);
    switch (widget.id) {
      case 28:
        botTimer = Timer(skill.think(random, seconds: 4), planScramble);
      case 30:
        botTimer = Timer(skill.think(random, seconds: 2.5), startCrossword);
      case 31:
        botTimer = Timer(skill.think(random, seconds: 3.5), startSearch);
    }
  }

  /// Delay between two letters or cells, so the move can be followed.
  Duration get botStep => BotSkill.of(context).think(random, seconds: .35);

  void planScramble() {
    if (!mounted || !botTurn) return;
    final skill = BotSkill.of(context);
    final answer = word.split('');
    if (!skill.succeeds(random) && answer.length > 1) {
      // A believable slip: two neighbouring letters swapped.
      final i = random.nextInt(answer.length - 1);
      final swap = answer[i];
      answer[i] = answer[i + 1];
      answer[i + 1] = swap;
    }
    final used = <int>{};
    final plan = <int>[];
    for (final ch in answer) {
      final index = [
        for (var i = 0; i < letters.length; i++)
          if (letters[i] == ch && !used.contains(i)) i,
      ];
      if (index.isEmpty) continue;
      used.add(index.first);
      plan.add(index.first);
    }
    pickScramble(plan, 0);
  }

  void pickScramble(List<int> plan, int step) {
    if (!mounted || !botTurn) return;
    if (step < plan.length) {
      JoySounds.instance.play(SoundEffect.tap);
      setState(() => picked.add(plan[step]));
      botTimer = Timer(botStep, () => pickScramble(plan, step + 1));
      return;
    }
    botTimer = Timer(const Duration(milliseconds: 500), checkScramble);
  }

  void startCrossword() {
    if (!mounted || !botTurn) return;
    final open = [
      for (var i = 0; i < crossword.clues.length; i++)
        if (!crossword.solved.contains(i)) i,
    ];
    if (open.isEmpty) return;
    chooseClue(open[random.nextInt(open.length)]);
    final editable = [
      for (final cell in crossword.clues[selected].cells)
        if (!crossword.confirmed.containsKey(cell)) cell,
    ];
    botWrongCell =
        editable.isEmpty || BotSkill.of(context).succeeds(random)
            ? -1
            : editable[random.nextInt(editable.length)];
    botTimer = Timer(botStep, typeCrossword);
  }

  void typeCrossword() {
    if (!mounted || !botTurn) return;
    final cells = crossword.clues[selected].cells;
    if (cursor >= cells.length) {
      checkCrossword();
      return;
    }
    final cell = cells[cursor];
    var ch = crossword.solution[cell]!;
    if (cell == botWrongCell) ch = ch == 'A' ? 'E' : 'A';
    letter(ch);
    botTimer = Timer(botStep, typeCrossword);
  }

  void startSearch() {
    if (!mounted || !botTurn) return;
    final open = [
      for (final w in WordSearchBoard.words)
        if (!found.contains(w)) w,
    ];
    if (open.isEmpty) return;
    List<int> cells;
    if (BotSkill.of(context).succeeds(random)) {
      cells = search.placements[open[random.nextInt(open.length)]]!;
    } else {
      final from = random.nextInt(64);
      cells = search.line(from, random.nextInt(64));
      if (cells.length < 2) cells = [from];
    }
    start = cells.first;
    dragSearch(cells, 1);
  }

  void dragSearch(List<int> cells, int count) {
    if (!mounted || !botTurn) return;
    setState(() => selection = cells.sublist(0, count));
    if (count < cells.length) {
      botTimer = Timer(botStep, () => dragSearch(cells, count + 1));
    } else {
      botTimer = Timer(const Duration(milliseconds: 450), finishSearch);
    }
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
    widget.onFinish(leadingPlayer(scores));
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
      JoySounds.instance.play(SoundEffect.tap);
      entry[cells[cursor]] = value;
      cursor++;
      skipConfirmed();
    });
  }

  void checkCrossword() {
    if (done || crossword.solved.contains(selected)) return;
    setState(() {
      if (crossword.check(selected, entry)) {
        JoySounds.instance.play(SoundEffect.correct);
        crossword.confirm(selected);
        scores[turn] += crossword.clues[selected].word.length;
        message = 'Correct — crossing letters are now locked.';
      } else {
        JoySounds.instance.play(SoundEffect.wrong);
        message = 'Not quite. Turn passes; crossing letters stay.';
      }
      entry.clear();
      turn = (turn + 1) % widget.names.length;
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
    scheduleBot();
  }

  void checkScramble() {
    if (picked.length != letters.length || done) return;
    setState(() {
      if (picked.map((i) => letters[i]).join() == word) {
        JoySounds.instance.play(SoundEffect.correct);
        scores[turn]++;
        message = 'Correct!';
      } else {
        JoySounds.instance.play(SoundEffect.wrong);
        message = 'The word was $word.';
      }
      if (scores[turn] >= 5) {
        end();
        return;
      }
      turn = (turn + 1) % widget.names.length;
      newWord();
    });
    scheduleBot();
  }

  int cellAt(Offset point, double size) =>
      ((point.dy / size * 8).floor().clamp(0, 7)) * 8 +
      (point.dx / size * 8).floor().clamp(0, 7);
  void finishSearch() {
    if (done || selection.isEmpty) return;
    setState(() {
      final match = search.match(selection, found);
      if (match != null) {
        JoySounds.instance.play(SoundEffect.correct);
        found.add(match);
        marked.addAll(selection);
        scores[turn] += match.length;
        message = 'Found $match!';
      } else {
        JoySounds.instance.play(SoundEffect.wrong);
        message = 'No new word on that line.';
      }
      selection = [];
      start = null;
      turn = (turn + 1) % widget.names.length;
      if (found.length == WordSearchBoard.words.length) end();
    });
    scheduleBot();
  }

  Widget crosswordView() {
    final clue = crossword.clues[selected], cells = clue.cells;
    final numbers = <int, int>{};
    for (var i = 0; i < crossword.clues.length; i++) {
      numbers[crossword.clues[i].cells.first] = i + 1;
    }
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 230,
            child: boardGrid(49, 7, (i) {
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
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: selected,
          key: ValueKey(selected),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Choose a clue',
            isDense: true,
          ),
          items: [
            for (var i = 0; i < crossword.clues.length; i++)
              DropdownMenuItem(
                value: i,
                enabled: !crossword.solved.contains(i),
                child: Text(
                  '${i + 1} ${crossword.clues[i].across ? 'Across' : 'Down'}${crossword.solved.contains(i) ? ' ✓' : ''}',
                ),
              ),
          ],
          onChanged: (i) {
            if (i != null) chooseClue(i);
          },
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
                      width: (box.maxWidth - 18) / 7,
                      height: 34,
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
        const SizedBox(height: 16),
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
                        : () {
                          JoySounds.instance.play(SoundEffect.tap);
                          setState(() => picked.add(i));
                        },
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
    child: IgnorePointer(
      ignoring: botTurn,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (botTurn) const _ComputerPill(),
          widget.id == 30
              ? crosswordView()
              : widget.id == 31
              ? searchView()
              : scrambleView(),
        ],
      ),
    ),
  );
}

/// Shows that the computer, not a person, is playing this turn.
class _ComputerPill extends StatelessWidget {
  const _ComputerPill();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.smart_toy_rounded, size: 16),
        SizedBox(width: 6),
        Text('Computer is playing'),
      ],
    ),
  );
}
