import '../sound.dart';
import '../joy_theme.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'game_stage.dart';
import '../players.dart' show leadingPlayer;
import 'strategy_models.dart';

class _CodeAttempt {
  final List<int> pegs;
  final int exact, misplaced;
  const _CodeAttempt(this.pegs, this.exact, this.misplaced);
}

class StrategyGame extends StatefulWidget {
  final int id;
  final List<String> names;
  final ValueChanged<int> onFinish;
  const StrategyGame({
    super.key,
    required this.id,
    required this.names,
    required this.onFinish,
  });
  @override
  State<StrategyGame> createState() => _StrategyGameState();
}

class _StrategyGameState extends State<StrategyGame> {
  final random = Random();
  late final List<int> score, coins, lives, attempts;
  final sealedBids = <int>[];
  int turn = 0, round = 1, bid = 0, value = 5;
  bool done = false, pass = false, flagMode = false;
  String notice = '';
  final reversi = ReversiBoard(), dots = DotsBoard();
  late final List<FleetBoard> fleets;
  late final MineBoard mines;
  late final List<List<int>> secrets;
  final guess = <int>[];
  late final List<List<_CodeAttempt>> history;
  static const colors = [
    Color(0xFF507CFF),
    Color(0xFFFF6F83),
    Color(0xFFFFC16D),
    Color(0xFFA08AFF),
    Color(0xFF63D7F1),
    Color(0xFFFF9366),
  ];
  @override
  void initState() {
    super.initState();
    score = List.filled(widget.names.length, 0);
    coins = List.filled(widget.names.length, 12);
    lives = List.filled(widget.names.length, 2);
    attempts = List.filled(widget.names.length, 0);
    history = List.generate(widget.names.length, (_) => <String>[]);
    fleets = [FleetBoard(random), FleetBoard(random)];
    mines = MineBoard(random);
    secrets = List.generate(
      widget.names.length,
      (_) => List.generate(4, (_) => random.nextInt(6)),
    );
    value = 3 + random.nextInt(7);
  }

  void end([int? winner]) {
    if (done) return;
    done = true;
    widget.onFinish(
      winner ??
          leadingPlayer(
            score,
            eligible:
                widget.id == 35
                    ? [
                      for (var i = 0; i < lives.length; i++)
                        if (lives[i] > 0) i,
                    ]
                    : null,
          ),
    );
  }

  void nextTurn() {
    do {
      turn = (turn + 1) % widget.names.length;
    } while (widget.id == 35 && lives[turn] <= 0);
    pass = widget.id == 33 || widget.id == 34;
  }

  void auction() {
    if (done || pass) return;
    setState(() {
      sealedBids.add(bid);
      bid = 0;
      if (sealedBids.length < widget.names.length) {
        turn++;
        pass = true;
        JoySounds.instance.play(SoundEffect.tap);
        return;
      }
      final winner = leadingPlayer(sealedBids);
      JoySounds.instance.play(
        winner < 0 ? SoundEffect.tap : SoundEffect.correct,
      );
      if (winner >= 0) {
        score[winner] += value;
        coins[winner] -= sealedBids[winner];
      }
      notice =
          'Bids ${sealedBids.join(' / ')}. ${winner < 0 ? 'Tie — treasure unclaimed' : '${widget.names[winner]} takes $value gems'}.';
      sealedBids.clear();
      turn = 0;
      if (round == 6) {
        end();
      } else {
        round++;
        value = 3 + random.nextInt(7);
      }
    });
  }

  void move(int cell) {
    if (done || pass) return;
    setState(() {
      switch (widget.id) {
        case 16:
          if (!reversi.play(cell, turn + 1)) return;
          JoySounds.instance.play(SoundEffect.flip);
          score[0] = reversi.cells.where((v) => v == 1).length;
          score[1] = reversi.cells.where((v) => v == 2).length;
          turn = 1 - turn;
          if (reversi.legal(turn + 1).isEmpty) {
            turn = 1 - turn;
            notice = 'No legal move for the other player — turn passed.';
            if (reversi.legal(turn + 1).isEmpty) end();
          }
          break;
        case 32:
          final gained = dots.play(cell, turn + 1);
          if (gained < 0) return;
          JoySounds.instance.play(
            gained > 0 ? SoundEffect.correct : SoundEffect.tap,
          );
          score[turn] += gained;
          if (!dots.owners.contains(0)) {
            end();
          } else if (gained == 0) {
            nextTurn();
          }
          break;
        case 33:
          final enemy = fleets[1 - turn];
          if (enemy.shots.contains(cell)) return;
          final hit = enemy.fire(cell);
          JoySounds.instance.play(hit ? SoundEffect.hit : SoundEffect.tap);
          if (hit) score[turn]++;
          notice = hit ? 'Hit!' : 'Splash — missed.';
          if (enemy.sunk) {
            end(turn);
          } else {
            nextTurn();
          }
          break;
        case 35:
          if (flagMode) {
            if (mines.revealed.contains(cell)) return;
            if (mines.flags.contains(cell)) {
              mines.flags.remove(cell);
            } else {
              mines.flags.add(cell);
            }
            return;
          }
          if (mines.revealed.contains(cell) || mines.flags.contains(cell)) {
            return;
          }
          final result = mines.reveal(cell);
          JoySounds.instance.play(
            result < 0 ? SoundEffect.wrong : SoundEffect.tap,
          );
          if (result < 0) {
            lives[turn]--;
            notice = 'Mine! ${lives[turn]} shields remain.';
            if (lives[turn] == 0) {
              final alive = [
                for (var i = 0; i < lives.length; i++)
                  if (lives[i] > 0) i,
              ];
              if (alive.length == 1) {
                end(alive.single);
                return;
              }
              notice = '${widget.names[turn]} is eliminated.';
            }
          } else {
            score[turn] += result;
            notice = '$result safe cells revealed.';
          }
          if (mines.complete) {
            end();
          } else {
            nextTurn();
          }
          break;
      }
    });
  }

  void checkCode() {
    if (guess.length != 4 || done) return;
    setState(() {
      final feedback = evaluateCode(secrets[turn], guess);
      JoySounds.instance.play(
        feedback.exact == 4 ? SoundEffect.correct : SoundEffect.tap,
      );
      attempts[turn]++;
      history[turn].add(
        _CodeAttempt(List<int>.of(guess), feedback.exact, feedback.misplaced),
      );
      score[turn] = max(score[turn], feedback.exact);
      if (feedback.exact == 4) {
        end(turn);
      } else {
        guess.clear();
        nextTurn();
        if (attempts.every((n) => n >= 8)) end();
      }
    });
  }

  Widget auctionView() => Column(
    children: [
      const Icon(Icons.diamond_rounded, size: 90, color: Color(0xFFFFC16D)),
      Text(
        '$value GEM TREASURE',
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
      ),
      Text('Auction $round of 6 • Coins: ${coins.join(' / ')}'),
      const SizedBox(height: 24),
      Text('${widget.names[turn]}, place a secret bid'),
      Wrap(
        spacing: 10,
        children: [
          for (var i = 0; i <= min(4, coins[turn]); i++)
            ChoiceChip(
              label: Text('$i coins'),
              selected: bid == i,
              onSelected: (_) => setState(() => bid = i),
            ),
        ],
      ),
      const SizedBox(height: 20),
      FilledButton(onPressed: auction, child: const Text('Seal bid')),
      const SizedBox(height: 16),
      Text(notice, textAlign: TextAlign.center),
    ],
  );
  Widget dotsView() => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (c, box) {
        final unit = box.maxWidth / 3.5, origin = unit * .25;
        return Stack(
          children: [
            for (var i = 0; i < 9; i++)
              Positioned(
                left: origin + i % 3 * unit,
                top: origin + i ~/ 3 * unit,
                width: unit,
                height: unit,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: unit * .8,
                    height: unit * .8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color:
                          dots.owners[i] == 0
                              ? Colors.white.withValues(alpha: .025)
                              : playerColors[dots.owners[i] - 1].withValues(
                                alpha: .5,
                              ),
                    ),
                  ),
                ),
              ),
            for (var i = 0; i < 24; i++)
              Builder(
                builder: (_) {
                  final horizontal = i < 12, index = horizontal ? i : i - 12;
                  final x = horizontal ? index % 3 : index % 4,
                      y = horizontal ? index ~/ 3 : index ~/ 4;
                  return Positioned(
                    left: origin + x * unit - (horizontal ? 0 : 13),
                    top: origin + y * unit - (horizontal ? 13 : 0),
                    width: horizontal ? unit : 26,
                    height: horizontal ? 26 : unit,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => move(i),
                      child: Center(
                        child: Container(
                          width: horizontal ? unit - 12 : 7,
                          height: horizontal ? 7 : unit - 12,
                          decoration: BoxDecoration(
                            color:
                                dots.edges[i] == 0
                                    ? Colors.white24
                                    : playerColors[dots.edges[i] - 1],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            for (var r = 0; r < 4; r++)
              for (var col = 0; col < 4; col++)
                Positioned(
                  left: origin + col * unit - 5,
                  top: origin + r * unit - 5,
                  child: const IgnorePointer(
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
          ],
        );
      },
    ),
  );
  Widget codeView() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C3159), Color(0xFF14213D)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF507CFF).withValues(alpha: .38)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: Color(0xFF9DB7FF), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CRACK THE CODE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF507CFF).withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${attempts[turn]} / 8',
                    style: const TextStyle(color: Color(0xFFB8CAFF), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Find the 4 hidden colors. Repeats are allowed.',
              style: TextStyle(color: JoyTheme.muted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < guess.length ? colors[guess[i]] : const Color(0xFF0D1830),
                        border: Border.all(
                          color: i < guess.length ? Colors.white.withValues(alpha: .8) : const Color(0xFF526487),
                          width: 2,
                        ),
                        boxShadow: i < guess.length
                            ? [BoxShadow(color: colors[guess[i]].withValues(alpha: .35), blurRadius: 12, spreadRadius: 1)]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          i < guess.length ? '${guess[i] + 1}' : '${i + 1}',
                          style: TextStyle(
                            color: i < guess.length ? Colors.white : const Color(0xFF7384A7),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text('CHOOSE A COLOR', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: JoyTheme.muted, fontWeight: FontWeight.w800)),
                ),
                Text('${guess.length} of 4 selected', style: const TextStyle(fontSize: 10, color: Color(0xFF9DB7FF))),
              ],
            ),
            const SizedBox(height: 9),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 11,
              runSpacing: 10,
              children: [
                for (var i = 0; i < colors.length; i++)
                  Semantics(
                    button: true,
                    label: 'Color ${i + 1}',
                    child: InkWell(
                      onTap: guess.length < 4
                          ? () {
                              JoySounds.instance.play(SoundEffect.tap);
                              setState(() => guess.add(i));
                            }
                          : null,
                      customBorder: const CircleBorder(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 39,
                        height: 39,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[i],
                          border: Border.all(color: Colors.white.withValues(alpha: .85), width: 2),
                          boxShadow: [BoxShadow(color: colors[i].withValues(alpha: .3), blurRadius: 9, offset: const Offset(0, 3))],
                        ),
                        child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: guess.isEmpty
                        ? null
                        : () {
                            JoySounds.instance.play(SoundEffect.tap);
                            setState(() => guess.clear());
                          },
                    icon: const Icon(Icons.restart_alt_rounded, size: 17),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB8CAFF),
                      side: const BorderSide(color: Color(0xFF526487)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: guess.length == 4 ? checkCode : null,
                    icon: const Icon(Icons.lock_open_rounded, size: 17),
                    label: const Text('Check code'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF507CFF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF33415F),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 13),
      Row(
        children: [
          const Expanded(child: Text('YOUR ATTEMPTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
          Text('${8 - attempts[turn]} remaining', style: const TextStyle(fontSize: 11, color: JoyTheme.muted)),
        ],
      ),
      const SizedBox(height: 7),
      if (history[turn].isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF17243E),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: .07)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFC16D), size: 17),
              SizedBox(width: 8),
              Flexible(child: Text('Your feedback will appear here after each guess.', textAlign: TextAlign.center, style: TextStyle(color: JoyTheme.muted, fontSize: 11))),
            ],
          ),
        )
      else
        for (var index = history[turn].length - 1; index >= 0; index--)
          _codeAttemptRow(index + 1, history[turn][index]),
      const SizedBox(height: 7),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FeedbackLegend(color: Colors.white, label: 'Exact position'),
          SizedBox(width: 14),
          _FeedbackLegend(color: Color(0xFF71809B), label: 'Right color'),
        ],
      ),
    ],
  );

  Widget _codeAttemptRow(int number, _CodeAttempt attempt) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF17243E),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Row(
      children: [
        SizedBox(width: 25, child: Text('$number', style: const TextStyle(color: JoyTheme.muted, fontSize: 11, fontWeight: FontWeight.w800))),
        for (final peg in attempt.pegs)
          Container(
            width: 17,
            height: 17,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors[peg], border: Border.all(color: Colors.white54, width: 1)),
          ),
        const Spacer(),
        for (var i = 0; i < attempt.exact; i++)
          const Padding(padding: EdgeInsets.only(left: 3), child: _FeedbackDot(color: Colors.white)),
        for (var i = 0; i < attempt.misplaced; i++)
          const Padding(padding: EdgeInsets.only(left: 3), child: _FeedbackDot(color: Color(0xFF71809B))),
        const SizedBox(width: 8),
        Text('${attempt.exact}+${attempt.misplaced}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFB8CAFF))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    String message = notice.isEmpty ? '${widget.names[turn]}’s turn' : notice;
    if (id == 16) {
      message = 'Bracket opposing discs between yours to capture them.';
    }
    if (id == 32) {
      message = 'Join two dots. Close a box to score and play again.';
    }
    if (id == 33) {
      message = '${widget.names[turn]}: fire at the enemy’s hidden fleet.';
    }
    if (id == 34) {
      message = '${widget.names[turn]}: solve your code before your rival.';
    }
    if (id == 35) message = 'Shields ${lives.join(' / ')} • $notice';
    return GameStage(
      names: widget.names,
      scores: score,
      turn: turn,
      message: message,
      child:
          pass
              ? Column(
                children: [
                  const Icon(Icons.screen_lock_portrait_rounded, size: 85),
                  const SizedBox(height: 20),
                  Text(
                    'Pass to ${widget.names[turn]}',
                    style: const TextStyle(fontSize: 25),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => setState(() => pass = false),
                    child: Text(
                      widget.id == 1
                          ? 'Ready — place my bid'
                          : widget.id == 34
                          ? 'Ready — make my guess'
                          : 'Ready — view target grid',
                    ),
                  ),
                ],
              )
              : switch (id) {
                1 => auctionView(),
                16 => boardGrid(36, 6, (i) {
                  final v = reversi.cells[i],
                      legal = reversi.captures(i, turn + 1).isNotEmpty;
                  return gameTile(
                    onTap: () => move(i),
                    color: const Color(0xFF1A304C),
                    child:
                        v == 0
                            ? (legal
                                ? Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: Colors.white38,
                                    shape: BoxShape.circle,
                                  ),
                                )
                                : const SizedBox())
                            : AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: const Alignment(-.4, -.5),
                                  colors: [
                                    Color.lerp(
                                      playerColors[v - 1],
                                      Colors.white,
                                      .5,
                                    )!,
                                    playerColors[v - 1],
                                  ],
                                ),
                              ),
                            ),
                  );
                }),
                32 => dotsView(),
                33 => Column(
                  children: [
                    boardGrid(36, 6, (i) {
                      final board = fleets[1 - turn],
                          hit = board.shots.contains(i);
                      return gameTile(
                        onTap: () => move(i),
                        color:
                            hit
                                ? (board.ships.contains(i)
                                    ? const Color(0xFF704356)
                                    : const Color(0xFF1D3954))
                                : const Color(0xFF162844),
                        child: Icon(
                          hit
                              ? (board.ships.contains(i)
                                  ? Icons.local_fire_department_rounded
                                  : Icons.water_drop_rounded)
                              : Icons.radar_rounded,
                          color: hit ? Colors.white : Colors.white24,
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Your fleet: ${fleets[turn].ships.length - fleets[turn].shots.where(fleets[turn].ships.contains).length} hull cells remaining',
                    ),
                    const Text(
                      'Enemy ships: lengths 3, 2, 2 • One shot per turn',
                    ),
                  ],
                ),
                34 => codeView(),
                _ => Column(
                  children: [
                    boardGrid(36, 6, (i) {
                      final open = mines.revealed.contains(i),
                          bomb = mines.mines.contains(i),
                          flag = mines.flags.contains(i),
                          n = mines.clue(i);
                      return gameTile(
                        onTap: () => move(i),
                        color:
                            open
                                ? const Color(0xFF28354B)
                                : const Color(0xFF1C294A),
                        child:
                            open
                                ? (bomb
                                    ? const Icon(
                                      Icons.blur_on,
                                      color: Colors.orange,
                                    )
                                    : Text(
                                      n == 0 ? '' : '$n',
                                      style: TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                        color: colors[n % 6],
                                      ),
                                    ))
                                : flag
                                ? const Icon(
                                  Icons.flag_rounded,
                                  color: Colors.amber,
                                )
                                : const Icon(
                                  Icons.square_rounded,
                                  color: Colors.white10,
                                ),
                      );
                    }),
                    SwitchListTile(
                      title: const Text('Flag mode'),
                      subtitle: const Text(
                        'Mark suspected mines without ending your turn',
                      ),
                      value: flagMode,
                      onChanged: (v) => setState(() => flagMode = v),
                    ),
                    const Text(
                      'First reveal is safe. Empty cells open their neighbors.\nMost safe cells wins, or survive your rival’s two mine hits.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              },
    );
  }
}

class _FeedbackDot extends StatelessWidget {
  final Color color;
  const _FeedbackDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white24, width: .5),
    ),
  );
}

class _FeedbackLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _FeedbackLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _FeedbackDot(color: color),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: JoyTheme.muted, fontSize: 9)),
    ],
  );
}
