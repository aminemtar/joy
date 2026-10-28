import '../sound.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'game_stage.dart';
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
  final random = Random(), score = [0, 0], coins = [12, 12], lives = [2, 2];
  int turn = 0, round = 1, bid = 0, value = 5;
  int? secretBid;
  bool done = false, pass = false, flagMode = false;
  String notice = '';
  final reversi = ReversiBoard(), dots = DotsBoard();
  late final List<FleetBoard> fleets;
  late final MineBoard mines;
  late final List<List<int>> secrets;
  final guess = <int>[], history = [<String>[], <String>[]];
  final attempts = [0, 0];
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
    fleets = [FleetBoard(random), FleetBoard(random)];
    mines = MineBoard(random);
    secrets = List.generate(
      2,
      (_) => List.generate(4, (_) => random.nextInt(6)),
    );
    value = 3 + random.nextInt(7);
  }

  void end([int? winner]) {
    if (done) return;
    done = true;
    widget.onFinish(
      winner ??
          (score[0] == score[1]
              ? -1
              : score[0] > score[1]
              ? 0
              : 1),
    );
  }

  void nextTurn() {
    turn = 1 - turn;
    pass = widget.id == 33;
  }

  void auction() {
    if (done) return;
    setState(() {
      if (secretBid == null) {
        JoySounds.instance.play(SoundEffect.tap);
        secretBid = bid;
        turn = 1;
        bid = 0;
        pass = true;
        return;
      }
      final first = secretBid!,
          winner =
              first == bid
                  ? -1
                  : first > bid
                  ? 0
                  : 1;
      JoySounds.instance.play(
        winner >= 0 ? SoundEffect.correct : SoundEffect.tap,
      );
      if (winner >= 0) {
        score[winner] += value;
        coins[winner] -= winner == 0 ? first : bid;
      }
      notice =
          'Bids $first / $bid. ${winner < 0 ? 'Tie — treasure unclaimed' : '${widget.names[winner]} takes $value gems'}.';
      secretBid = null;
      bid = 0;
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
              end(1 - turn);
              return;
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
        '${guess.map((i) => i + 1).join(' ')}   •   ${feedback.exact} exact / ${feedback.misplaced} misplaced',
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
      Text('Auction $round of 6 • Coins: ${coins[0]} / ${coins[1]}'),
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
    children: [
      const Text(
        'A different hidden code for each player.\n4 pegs • 6 colors • repeats allowed',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.all(7),
              child: CircleAvatar(
                radius: 22,
                backgroundColor:
                    i < guess.length ? colors[guess[i]] : Colors.white12,
                child: Text(i < guess.length ? '${guess[i] + 1}' : '?'),
              ),
            ),
        ],
      ),
      Wrap(
        spacing: 10,
        children: [
          for (var i = 0; i < 6; i++)
            IconButton.filled(
              onPressed:
                  guess.length < 4 ? () => setState(() => guess.add(i)) : null,
              style: IconButton.styleFrom(backgroundColor: colors[i]),
              icon: Text('${i + 1}'),
            ),
        ],
      ),
      Wrap(
        spacing: 12,
        children: [
          TextButton(
            onPressed:
                guess.isEmpty ? null : () => setState(() => guess.removeLast()),
            child: const Text('Undo'),
          ),
          FilledButton(
            onPressed: guess.length == 4 ? checkCode : null,
            child: const Text('Test code'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text('Attempt ${attempts[turn] + 1} / 8'),
      for (final row in history[turn])
        Padding(padding: const EdgeInsets.all(7), child: Text(row)),
    ],
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
    if (id == 35) message = 'Shields ${lives[0]} / ${lives[1]} • $notice';
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
