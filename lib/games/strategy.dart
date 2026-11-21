import '../sound.dart';
import '../joy_theme.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'bot_skill.dart';
import 'code_breaker_view.dart';
import 'game_stage.dart';
import '../players.dart' show leadingPlayer;
import 'strategy_bot.dart';
import 'strategy_models.dart';

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
  late final List<List<CodeAttempt>> history;
  static const colors = codeColors;

  /// The computer's solver for its own secret code (Code Breaker).
  final solver = CodeSolver();
  Timer? botTimer;

  /// Whether the second player is the computer.
  bool get vsComputer => BotSkill.isComputer(context);

  /// The player whose board is on screen: always the human against the
  /// computer, otherwise whoever's turn it is.
  int get viewer => vsComputer ? 0 : turn;
  @override
  void initState() {
    super.initState();
    score = List.filled(widget.names.length, 0);
    coins = List.filled(widget.names.length, 12);
    lives = List.filled(widget.names.length, 2);
    attempts = List.filled(widget.names.length, 0);
    history = List.generate(widget.names.length, (_) => <CodeAttempt>[]);
    fleets = [FleetBoard(random), FleetBoard(random)];
    mines = MineBoard(random);
    secrets = List.generate(
      widget.names.length,
      (_) => List.generate(4, (_) => random.nextInt(6)),
    );
    value = 3 + random.nextInt(7);
  }

  @override
  void dispose() {
    botTimer?.cancel();
    super.dispose();
  }

  /// Schedules the computer's move when it is its turn.
  void scheduleBot() {
    botTimer?.cancel();
    if (!mounted || done || !vsComputer || turn != 1 || widget.id == 1) return;
    final skill = BotSkill.of(context);
    botTimer = Timer(
      skill.think(random, seconds: widget.id == 34 ? 1.5 : 1.0),
      botMove,
    );
  }

  void botMove() {
    if (!mounted || done || turn != 1) return;
    final skill = BotSkill.of(context);
    switch (widget.id) {
      case 16:
        final cell = reversiBotMove(reversi, 2, random, skill);
        if (cell != null) move(cell, bot: true);
      case 32:
        move(dotsBotMove(dots, random, skill), bot: true);
      case 33:
        move(fleetBotShot(fleets[0], random, skill), bot: true);
      case 34:
        final code = solver.next(random, skill);
        checkCode(forced: code);
      case 35:
        final cell = minesBotMove(mines, random, skill);
        if (cell < 0) {
          setState(mines.flags.clear);
          scheduleBot();
        } else {
          move(cell, bot: true);
        }
    }
  }

  void end([int? winner]) {
    if (done) return;
    done = true;
    botTimer?.cancel();
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
    } while ((widget.id == 35 && lives[turn] <= 0) ||
        (widget.id == 34 && attempts[turn] >= 8));
    pass = (widget.id == 33 || widget.id == 34) && !vsComputer;
  }

  void auction() {
    if (done || pass) return;
    setState(() {
      sealedBids.add(bid);
      bid = 0;
      if (vsComputer && sealedBids.length == 1) {
        sealedBids.add(
          botBid(
            value: value,
            coins: coins[1],
            round: round,
            random: random,
            skill: BotSkill.of(context),
          ),
        );
      }
      if (sealedBids.length < widget.names.length) {
        turn++;
        pass = true;
        JoySounds.instance.play(SoundEffect.tap);
        return;
      }
      final winner = leadingPlayer(sealedBids);
      JoySounds.instance.play(
        winner < 0 ? SoundEffect.tap : SoundEffect.coin,
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

  void move(int cell, {bool bot = false}) {
    if (done || pass || (vsComputer && turn == 1 && !bot)) return;
    setState(() {
      switch (widget.id) {
        case 16:
          if (!reversi.play(cell, turn + 1)) return;
          JoySounds.instance.play(SoundEffect.place);
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
            gained > 0 ? SoundEffect.correct : SoundEffect.place,
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
          JoySounds.instance.play(hit ? SoundEffect.blast : SoundEffect.splash);
          if (hit) score[turn]++;
          notice = hit ? 'Hit!' : 'Splash — missed.';
          if (enemy.sunk) {
            end(turn);
          } else {
            nextTurn();
          }
          break;
        case 35:
          if (flagMode && !bot) {
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
            result < 0 ? SoundEffect.blast : SoundEffect.pop,
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
    scheduleBot();
  }

  void checkCode({List<int>? forced}) {
    final attempt = forced ?? guess;
    if (attempt.length != 4 || done) return;
    if (forced == null && vsComputer && turn == 1) return;
    setState(() {
      final feedback = evaluateCode(secrets[turn], attempt);
      if (turn == 1 && vsComputer) {
        solver.learn(attempt, feedback.exact, feedback.misplaced);
      }
      JoySounds.instance.play(
        feedback.exact == 4 ? SoundEffect.unlock : SoundEffect.place,
      );
      attempts[turn]++;
      history[turn].add(
        CodeAttempt(List<int>.of(attempt), feedback.exact, feedback.misplaced),
      );
      score[turn] = max(score[turn], feedback.exact);
      if (feedback.exact == 4) {
        end(turn);
      } else {
        if (forced == null) guess.clear();
        if (attempts.every((n) => n >= 8)) {
          end();
        } else {
          nextTurn();
        }
      }
    });
    scheduleBot();
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
  Widget codeView() => CodeBreakerBoard(
    guess: guess,
    history: history[viewer],
    maxAttempts: 8,
    enabled: !(vsComputer && turn == 1) && !done,
    onPick: (i) {
      JoySounds.instance.play(SoundEffect.tap);
      setState(() => guess.add(i));
    },
    onRemove: (i) {
      JoySounds.instance.play(SoundEffect.tap);
      setState(() => guess.removeAt(i));
    },
    onClear: () {
      JoySounds.instance.play(SoundEffect.tap);
      setState(guess.clear);
    },
    onCheck: checkCode,
    rivalName: vsComputer ? widget.names[1] : null,
    rivalHistory: history[1],
    rivalThinking: vsComputer && turn == 1 && !done,
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
      message =
          vsComputer && turn == 1
              ? '${widget.names[1]} is aiming…'
              : '${widget.names[turn]}: fire at the enemy’s hidden fleet.';
    }
    if (id == 34) {
      message =
          vsComputer && turn == 1
              ? '${widget.names[1]} is working on its code…'
              : '${widget.names[turn]}: solve your code before your rival.';
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
                      final board = fleets[1 - viewer],
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
                      'Your fleet: ${fleets[viewer].ships.length - fleets[viewer].shots.where(fleets[viewer].ships.contains).length} hull cells remaining',
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
                      onChanged:
                          vsComputer && turn == 1
                              ? null
                              : (v) => setState(() => flagMode = v),
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
