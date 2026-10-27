import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class ActionGame extends StatefulWidget {
  final int id;
  final bool haptics;
  final ValueChanged<int> onFinish;
  const ActionGame({
    super.key,
    required this.id,
    required this.onFinish,
    required this.haptics,
  });
  @override
  State<ActionGame> createState() => _ActionGameState();
}

class Shot {
  Offset p, v;
  final int owner;
  double life;
  Shot(this.p, this.v, this.owner, this.life);
}

class _ActionGameState extends State<ActionGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker ticker;
  double last = 0, time = 0, countdown = 3, clock = 0, snakeClock = 0;
  bool paused = false, over = false;
  final rng = Random(), score = [0, 0];
  final players = [const Offset(.5, .82), const Offset(.5, .18)];
  final velocity = [Offset.zero, Offset.zero];
  final steer = [0.0, 0.0];
  final pointers = <int, int>{};
  final strokes = [0, 0];
  final progress = [0.0, 0.0];
  final aims = <int, Offset>{};
  final shots = <Shot>[];
  final cooldown = [0.0, 0.0];
  final snakes = [
    <Point<int>>[const Point(5, 14)],
    <Point<int>>[const Point(14, 5)],
  ];
  final dirs = [const Point(1, 0), const Point(-1, 0)];
  Point<int> food = const Point(10, 10);
  Offset ball = const Offset(.5, .5), ballV = const Offset(.25, .36);
  final targets = [const Offset(.3, .7), const Offset(.7, .3)];
  Size area = Size.zero;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ticker = createTicker(tick)..start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => paused = true);
    }
  }

  bool get racing => widget.id == 0 || widget.id == 3;
  bool get field => [1, 5, 6, 7].contains(widget.id);
  bool get ring => [4, 10, 14].contains(widget.id);
  Offset normal(Offset o) {
    final d = o.distance;
    return d == 0 ? Offset.zero : o / d;
  }

  Offset clamp(Offset p) =>
      Offset(p.dx.clamp(.035, .965), p.dy.clamp(.035, .965));
  void finish(int p) {
    if (over) return;
    over = true;
    if (widget.haptics) HapticFeedback.mediumImpact();
    widget.onFinish(p);
  }

  void point(int p, [int goal = 5]) {
    score[p]++;
    if (widget.haptics) HapticFeedback.lightImpact();
    if (score[p] >= goal) finish(p);
  }

  void tick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - last).clamp(0.0, .033);
    last = now;
    if (paused || over || area.isEmpty) return;
    if (countdown > 0) {
      setState(() => countdown -= dt);
      return;
    }
    time += dt;
    clock += dt;
    for (var p = 0; p < 2; p++) {
      cooldown[p] = max(0, cooldown[p] - dt);
    }
    if (!racing && widget.id != 8 && widget.id != 9 && widget.id != 12) {
      for (final entry in aims.entries) {
        final p = entry.key;
        final delta = entry.value - players[p];
        players[p] += normal(delta) * min(delta.distance, dt * .65);
      }
    }
    if (racing) {
      for (var p = 0; p < 2; p++) {
        players[p] = Offset(
          (players[p].dx + steer[p] * dt * .7).clamp(.06, .94),
          p == 0 ? .82 : .18,
        );
      }
      if (clock > .65) {
        clock = 0;
        for (var p = 0; p < 2; p++) {
          shots.add(
            Shot(
              Offset(.08 + rng.nextDouble() * .84, p == 0 ? .51 : .49),
              Offset(0, p == 0 ? .4 : -.4),
              p,
              3,
            ),
          );
        }
      }
      for (final s in shots) {
        s.p += s.v * dt;
        s.life -= dt;
        if ((s.p - players[s.owner]).distance < .065) {
          finish(1 - s.owner);
          break;
        }
      }
      shots.removeWhere((s) => s.life <= 0);
      if (widget.id == 0) {
        for (var p = 0; p < 2; p++) {
          final ideal = .5 + sin(time * 1.3 + p * .2) * .28;
          progress[p] +=
              dt * (.3 + max(0, 1 - (players[p].dx - ideal).abs() * 3));
          score[p] = progress[p].floor();
          if (score[p] >= 10) {
            finish(p);
            break;
          }
        }
      }
    }
    if (field) {
      ball += ballV * dt;
      ballV *= pow(.998, dt * 60).toDouble();
      if (ball.dx < .025 || ball.dx > .975) {
        ballV = Offset(-ballV.dx, ballV.dy);
        ball = Offset(ball.dx.clamp(.025, .975), ball.dy);
      }
      for (var p = 0; p < 2; p++) {
        final d = ball - players[p];
        if (d.distance < (widget.id == 5 ? .1 : .075)) {
          if (widget.id == 5) {
            if ((p == 0 && ballV.dy > 0) || (p == 1 && ballV.dy < 0)) {
              ballV = Offset(
                (ball.dx - players[p].dx) * 5,
                p == 0 ? -.55 : .55,
              );
              ball = Offset(ball.dx, players[p].dy + (p == 0 ? -.06 : .06));
            }
          } else {
            ballV = normal(d) * .7;
            ball = players[p] + normal(d) * .08;
          }
        }
      }
      if (ball.dy < 0 || ball.dy > 1) {
        final top = ball.dy < 0;
        if (widget.id == 5 || ball.dx >= .3 && ball.dx <= .7) {
          point(top ? 0 : 1);
          ball = const Offset(.5, .5);
          ballV = Offset((rng.nextDouble() - .5) * .5, top ? .4 : -.4);
        } else {
          ball = Offset(ball.dx, top ? .01 : .99);
          ballV = Offset(ballV.dx, -ballV.dy);
        }
      }
    }
    if (widget.id == 2) {
      for (var p = 0; p < 2; p++) {
        if ((players[p] - targets[p]).distance < .055) {
          point(p);
          targets[p] = Offset(
            .1 + rng.nextDouble() * .8,
            p == 0
                ? .57 + rng.nextDouble() * .35
                : .08 + rng.nextDouble() * .35,
          );
        }
      }
    }
    if (ring) {
      final d = players[1] - players[0];
      if (d.distance < .10) {
        final n = normal(d.distance == 0 ? const Offset(1, 0) : d);
        players[0] -= n * .009;
        players[1] += n * .009;
      }
      final radius = widget.id == 14 ? max(.12, .43 - time * .007) : .43;
      for (var p = 0; p < 2; p++) {
        final relative = players[p] - const Offset(.5, .5);
        if (relative.distance > radius) {
          finish(1 - p);
          break;
        }
      }
    }
    if (widget.id == 8) {
      for (var p = 0; p < 2; p++) {
        players[p] = Offset(.5 + sin(time * 2.2 + p) * .4, p == 0 ? .75 : .25);
      }
    }
    if (widget.id == 9) {
      for (var p = 0; p < 2; p++) {
        players[p] += velocity[p] * dt;
        velocity[p] *= pow(.985, dt * 60).toDouble();
        if (players[p].dx < .03 || players[p].dx > .97) {
          velocity[p] = Offset(-velocity[p].dx, velocity[p].dy);
        }
        final minY = p == 0 ? .52 : .03, maxY = p == 0 ? .97 : .48;
        if (players[p].dy < minY || players[p].dy > maxY) {
          velocity[p] = Offset(velocity[p].dx, -velocity[p].dy);
        }
        players[p] = Offset(
          players[p].dx.clamp(.03, .97),
          players[p].dy.clamp(minY, maxY),
        );
        if ((players[p] - targets[p]).distance < .045 &&
            velocity[p].distance < .35) {
          point(p, 3);
          players[p] = Offset(.5, p == 0 ? .9 : .1);
          velocity[p] = Offset.zero;
          targets[p] = Offset(.1 + rng.nextDouble() * .8, p == 0 ? .6 : .4);
        }
      }
    }
    if (widget.id == 11 || widget.id == 13) {
      for (final s in shots) {
        s.life -= dt;
        if (widget.id == 11) {
          s.p += s.v * dt;
          if ((s.p - players[1 - s.owner]).distance < .06) {
            point(s.owner);
            s.life = -1;
          }
        } else if (s.life <= 0) {
          for (var p = 0; p < 2; p++) {
            if ((s.p - players[p]).distance < .16) {
              finish(1 - p);
              break;
            }
          }
        }
      }
      shots.removeWhere((s) => s.life <= 0);
    }
    if (widget.id == 12) {
      snakeClock += dt;
      if (snakeClock > .16) {
        snakeClock = 0;
        final heads = [
          for (var p = 0; p < 2; p++)
            Point(snakes[p].first.x + dirs[p].x, snakes[p].first.y + dirs[p].y),
        ];
        final dead = [false, false];
        for (var p = 0; p < 2; p++) {
          final n = heads[p];
          dead[p] =
              n.x < 0 ||
              n.x >= 20 ||
              n.y < 0 ||
              n.y >= 20 ||
              snakes.any((s) => s.contains(n)) ||
              n == heads[1 - p];
        }
        if (dead[0] || dead[1]) {
          finish(
            dead[0] && dead[1]
                ? -1
                : dead[0]
                ? 1
                : 0,
          );
        } else {
          for (var p = 0; p < 2; p++) {
            snakes[p].insert(0, heads[p]);
            if (heads[p] == food) {
              score[p]++;
              final available = [
                for (var x = 0; x < 20; x++)
                  for (var y = 0; y < 20; y++)
                    if (!snakes.any((s) => s.contains(Point(x, y))))
                      Point(x, y),
              ];
              if (available.isEmpty) {
                finish(
                  score[0] == score[1]
                      ? -1
                      : score[0] > score[1]
                      ? 0
                      : 1,
                );
              } else {
                food = available[rng.nextInt(available.length)];
              }
            } else if (snakes[p].length > 4) {
              snakes[p].removeLast();
            }
          }
        }
      }
    }
    setState(() {});
  }

  Offset location(PointerEvent e) =>
      Offset(e.localPosition.dx / area.width, e.localPosition.dy / area.height);
  void down(PointerDownEvent e) {
    if (paused || over || countdown > 0) return;
    final v = location(e);
    final p = v.dy > .5 ? 0 : 1;
    if (pointers.containsValue(p)) return;
    pointers[e.pointer] = p;
    if (widget.id == 8) {
      if (cooldown[p] > 0) return;
      cooldown[p] = .45;
      if ((players[p].dx - targets[p].dx).abs() < .10) {
        point(p);
      } else if (widget.haptics) {
        HapticFeedback.lightImpact();
      }
      return;
    }
    if (widget.id == 9) {
      velocity[p] = Offset.zero;
      strokes[p]++;
    }
    move(e);
  }

  void move(PointerEvent e) {
    final p = pointers[e.pointer];
    if (p == null || paused || over || countdown > 0) return;
    final v = location(e);
    if (racing) {
      steer[p] = v.dx < .5 ? -1 : 1;
    } else if (widget.id != 8 && widget.id != 9 && widget.id != 12) {
      final clamped = clamp(v);
      final dest =
          ring || widget.id == 11 || widget.id == 13
              ? clamped
              : Offset(
                clamped.dx,
                clamped.dy.clamp(p == 0 ? .55 : .05, p == 0 ? .95 : .45),
              );
      aims[p] = dest;
      if (widget.id == 5) players[p] = Offset(dest.dx, p == 0 ? .87 : .13);
    }
  }

  void up(PointerEvent e) {
    final p = pointers.remove(e.pointer);
    if (p == null) return;
    steer[p] = 0;
    aims.remove(p);
    if (widget.id == 9 && !paused) {
      velocity[p] = (players[p] - location(e)) * 2.5;
      final speed = velocity[p].distance;
      if (speed > 1.1) velocity[p] = normal(velocity[p]) * 1.1;
    }
  }

  void fire(int p) {
    if (paused || over || countdown > 0 || cooldown[p] > 0) return;
    cooldown[p] = widget.id == 13 ? 1 : .5;
    shots.add(
      Shot(
        players[p],
        normal(players[1 - p] - players[p]) * .6,
        p,
        widget.id == 13 ? 2 : 2.5,
      ),
    );
  }

  void direction(int p, Point<int> d) {
    if (d.x != -dirs[p].x || d.y != -dirs[p].y) dirs[p] = d;
  }

  Widget controls(int p) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children:
        widget.id == 12
            ? [
              for (final d in [
                const Point(-1, 0),
                const Point(0, -1),
                const Point(0, 1),
                const Point(1, 0),
              ])
                IconButton(
                  onPressed: () => direction(p, d),
                  icon: Icon(
                    d.x == -1
                        ? Icons.arrow_back
                        : d.x == 1
                        ? Icons.arrow_forward
                        : d.y == -1
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                ),
            ]
            : [
              if (widget.id == 11 || widget.id == 13)
                FilledButton(
                  onPressed: () => fire(p),
                  child: Text(widget.id == 13 ? 'DROP BOMB' : 'FIRE'),
                )
              else
                Text(
                  p == 0 ? 'BLUE • ${score[0]}' : 'CORAL • ${score[1]}',
                  style: TextStyle(
                    color:
                        p == 0
                            ? const Color(0xFF709AFF)
                            : const Color(0xFFFF8CA4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(child: RotatedBox(quarterTurns: 2, child: controls(1))),
            IconButton(
              onPressed: () => setState(() => paused = !paused),
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
            ),
          ],
        ),
      ),
      Expanded(
        child: LayoutBuilder(
          builder: (c, box) {
            area = Size(box.maxWidth, box.maxHeight);
            return Stack(
              children: [
                Listener(
                  onPointerDown: down,
                  onPointerMove: move,
                  onPointerUp: up,
                  onPointerCancel: up,
                  child: CustomPaint(
                    size: area,
                    painter: ArenaPainter(
                      id: widget.id,
                      time: time,
                      players: players,
                      ball: ball,
                      shots: shots,
                      targets: targets,
                      snakes: snakes,
                      food: food,
                    ),
                  ),
                ),
                if (countdown > 0 || paused)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child:
                            paused
                                ? FilledButton(
                                  onPressed:
                                      () => setState(() => paused = false),
                                  child: const Text('Resume'),
                                )
                                : Text(
                                  '${countdown.ceil()}',
                                  style: const TextStyle(
                                    fontSize: 90,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      SizedBox(height: 64, child: controls(0)),
    ],
  );
}

class ArenaPainter extends CustomPainter {
  final int id;
  final double time;
  final List<Offset> players, targets;
  final Offset ball;
  final List<Shot> shots;
  final List<List<Point<int>>> snakes;
  final Point<int> food;
  ArenaPainter({
    required this.id,
    required this.time,
    required this.players,
    required this.ball,
    required this.shots,
    required this.targets,
    required this.snakes,
    required this.food,
  });
  final brush = Paint();
  void text(Canvas c, String s, Offset p, double size) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, p - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas c, Size s) {
    Offset at(Offset p) => Offset(p.dx * s.width, p.dy * s.height);
    final unit = min(s.width, s.height);
    c.drawRect(Offset.zero & s, brush..color = const Color(0xFF111C37));
    for (var x = 0.0; x < s.width; x += 32) {
      c.drawLine(
        Offset(x, 0),
        Offset(x, s.height),
        brush
          ..color = Colors.white.withValues(alpha: .025)
          ..strokeWidth = 1,
      );
    }
    c.drawLine(
      Offset(0, s.height / 2),
      Offset(s.width, s.height / 2),
      brush
        ..color = Colors.white24
        ..strokeWidth = 2,
    );
    if ([4, 10, 14].contains(id)) {
      final radius =
          id == 14
              ? max(.12, .43 - time * .007)
              : .43; // Physics uses normalized arena coordinates, so render the same ellipse.
      c.drawOval(
        Rect.fromCenter(
          center: at(const Offset(.5, .5)),
          width: radius * 2 * s.width,
          height: radius * 2 * s.height,
        ),
        brush..color = const Color(0xFF283861),
      );
    }
    if (id == 0 || id == 3) {
      for (var p = 0; p < 2; p++) {
        for (var lane = 1; lane < 4; lane++) {
          for (var y = 0.0; y < .44; y += .08) {
            final yy = (y + time * .25) % .44 + (p == 0 ? .53 : .03);
            c.drawRect(
              Rect.fromLTWH(
                s.width * lane / 4,
                yy * s.height,
                3,
                s.height * .04,
              ),
              brush..color = Colors.white24,
            );
          }
        }
      }
    }
    if (id == 0) {
      for (var p = 0; p < 2; p++) {
        c.drawCircle(
          at(Offset(.5 + sin(time * 1.3 + p * .2) * .28, p == 0 ? .57 : .43)),
          unit * .018,
          brush..color = Colors.amber,
        );
      }
    }
    if (id == 12) {
      for (var p = 0; p < 2; p++) {
        for (final cell in snakes[p]) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                cell.x * s.width / 20,
                cell.y * s.height / 20,
                s.width / 20 - 1,
                s.height / 20 - 1,
              ),
              const Radius.circular(4),
            ),
            brush
              ..color =
                  p == 0 ? const Color(0xFF507CFF) : const Color(0xFFFF6F83),
          );
        }
      }
      text(
        c,
        '🍎',
        Offset((food.x + .5) * s.width / 20, (food.y + .5) * s.height / 20),
        unit / 20,
      );
      return;
    }
    for (var p = 0; p < 2; p++) {
      final color = p == 0 ? const Color(0xFF507CFF) : const Color(0xFFFF6F83);
      if ([2, 8, 9].contains(id)) {
        c.drawCircle(
          at(targets[p]),
          unit * .05,
          brush..color = color.withValues(alpha: .3),
        );
        text(
          c,
          id == 2
              ? '🅿️'
              : id == 8
              ? '🏀'
              : '⛳',
          at(targets[p]),
          unit * .075,
        );
      }
      if (id == 5) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: at(players[p]),
              width: s.width * .20,
              height: 12,
            ),
            const Radius.circular(6),
          ),
          brush..color = color,
        );
      } else {
        c.drawCircle(
          at(players[p]),
          unit * .055,
          brush..color = color.withValues(alpha: .12),
        );
        c.drawCircle(at(players[p]), unit * .04, brush..color = color);
        text(
          c,
          [0, 1, 2, 3, 4].contains(id)
              ? '🚗'
              : id == 11
              ? '🎯'
              : id == 10
              ? '💪'
              : id == 7
              ? '⚽'
              : id == 8
              ? '🏀'
              : id == 9
              ? '●'
              : '',
          at(players[p]),
          unit * .06,
        );
      }
    }
    if ([1, 5, 6, 7].contains(id)) {
      c.drawCircle(at(ball), unit * .022, brush..color = Colors.white);
      for (final y in [0.0, s.height - 5]) {
        c.drawRect(
          Rect.fromLTWH(s.width * .3, y, s.width * .4, 5),
          brush..color = Colors.amber,
        );
      }
    }
    for (final shot in shots) {
      if (id == 13) {
        c.drawCircle(
          at(shot.p),
          unit * .16 * (1 - shot.life / 2),
          brush..color = Colors.orange.withValues(alpha: .12),
        );
        text(c, '💣', at(shot.p), unit * .06);
      } else if (id == 0 || id == 3) {
        text(c, '🚕', at(shot.p), unit * .07);
      } else {
        c.drawCircle(at(shot.p), unit * .012, brush..color = Colors.amber);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ArenaPainter oldDelegate) => true;
}
