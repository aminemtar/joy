import '../joy_theme.dart';
import '../players.dart';
import '../sound.dart';
import '../party_data.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'arrow_pad.dart';
import 'bot_skill.dart';
import 'juice.dart';
import 'sprites.dart';
import 'tuning.dart';

class ActionGame extends StatefulWidget {
  final int id;
  final List<String> names;
  final bool haptics;
  final ValueChanged<int> onFinish;
  const ActionGame({
    super.key,
    required this.id,
    required this.onFinish,
    required this.haptics,
    this.names = const ['Blue', 'Coral'],
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
  final paddleGrip = <int, double>{};
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
  final lastMoved = [const Point(1, 0), const Point(-1, 0)];
  Point<int> food = const Point(10, 10);
  Offset ball = const Offset(.5, .5), ballV = const Offset(.25, .36);
  final targets = [const Offset(.3, .7), const Offset(.7, .3)];
  Size area = Size.zero;

  /// Paddle hits in the current ping-pong rally (the ball speeds up with it).
  int rally = 0;

  /// Sparks and screen shake that make hits and goals feel solid.
  final juice = Juice();

  /// Sound, sparks and shake for one impact at [at].
  void impact(Offset at, Color color, {int count = 8, double shake = 0}) {
    juice.burst(at, color, count: count);
    if (shake > 0) juice.kick(shake);
  }

  /// Bumped every frame; only the arena canvas listens to it.
  final repaint = ValueNotifier<int>(0);

  /// Scores last drawn by build(), to rebuild the rest only when they change.
  final shownScores = [0, 0];

  /// Seconds left before the ball moves again after a point.
  double serve = 0;

  /// Arrow directions each player holds, in screen coordinates. Sumo reads
  /// them as a joystick; Snake turns on the press instead.
  final held = [<Point<int>>{}, <Point<int>>{}];

  /// Whether the two Sumo wrestlers were touching on the previous frame.
  bool touching = false;
  final focus = FocusNode(debugLabel: 'arena');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.id == 5) {
      players[0] = const Offset(.5, .87);
      players[1] = const Offset(.5, .13);
    }
    JoySounds.instance.play(SoundEffect.tick);
    ticker = createTicker(tick)..start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    repaint.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => paused = true);
    }
  }

  bool get racing => widget.id == 0;
  bool get field => [5, 6].contains(widget.id);
  bool get ring => widget.id == 10;

  /// Sumo and Snake are played with arrow buttons or the keyboard, not touch.
  bool get arrows => widget.id == 10 || widget.id == 12;
  Offset normal(Offset o) {
    final d = o.distance;
    return d == 0 ? Offset.zero : o / d;
  }

  Offset clamp(Offset p) =>
      Offset(p.dx.clamp(.035, .965), p.dy.clamp(.035, .965));
  void finish(int p) {
    if (over) return;
    over = true;
    final ending = switch (widget.id) {
      0 => SoundEffect.crash,
      10 => SoundEffect.splash,
      12 => SoundEffect.crash,
      13 => SoundEffect.blast,
      _ => null,
    };
    if (ending != null) {
      JoySounds.instance.play(ending);
      juice.kick(1);
    }
    widget.onFinish(p);
  }

  void point(int p, [int goal = 5]) {
    JoySounds.instance.play(switch (widget.id) {
      5 || 6 => SoundEffect.goal,
      8 => SoundEffect.swish,
      11 => SoundEffect.blast,
      _ => SoundEffect.correct,
    });
    impact(
      switch (widget.id) {
        5 || 6 => ball,
        11 => players[1 - p],
        _ => players[p],
      },
      playerColors[p],
      count: 16,
      shake: widget.id == 5 || widget.id == 6 || widget.id == 11 ? .6 : .3,
    );
    score[p]++;
    if (score[p] >= goal) finish(p);
  }

  void tick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - last).clamp(0.0, .033);
    last = now;
    juice.enabled = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    juice.step(dt);
    if (paused || over || area.isEmpty) {
      if (over && juice.active) repaint.value++;
      MatchOptions.read(context)?.onPause?.call(true);
      return;
    }
    if (countdown > 0) {
      MatchOptions.read(context)?.onPause?.call(true);
      final before = countdown.ceil();
      setState(() => countdown -= dt);
      if (countdown.ceil() != before) {
        JoySounds.instance.play(
          countdown <= 0 ? SoundEffect.start : SoundEffect.tick,
        );
      }
      return;
    }
    final options = MatchOptions.read(context);
    options?.onPause?.call(false);
    options?.onScores?.call(List.of(score));
    if (widget.id == 5 && options?.computer == true) {
      final level = options!.difficulty;
      final speed = FieldTuning.botSpeed(level);
      final aim = (ball.dx +
              (level == Difficulty.easy ? sin(time * 2) * .12 : 0))
          .clamp(.10, .90);
      players[1] = Offset(
        players[1].dx + (aim - players[1].dx).clamp(-dt * speed, dt * speed),
        .13,
      );
    }
    vsBot = options?.computer == true;
    if (vsBot) {
      botSkill = BotSkill(options!.difficulty);
      if (widget.id != 5) computerPlay(dt);
    }
    time += dt;
    clock += dt;
    for (var p = 0; p < 2; p++) {
      cooldown[p] = max(0, cooldown[p] - dt);
    }
    if (!racing &&
        widget.id != 5 &&
        widget.id != 8 &&
        widget.id != 9 &&
        widget.id != 12) {
      for (final entry in aims.entries) {
        final p = entry.key;
        final delta = entry.value - players[p];
        final follow =
            widget.id == 6
                ? FieldTuning.hockeyFollow
                : FieldTuning.defaultFollow;
        players[p] += normal(delta) * min(delta.distance, dt * follow);
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
      final level = options?.difficulty ?? Difficulty.normal;
      final speed = widget.id == 5 ? FieldTuning.ballSpeed(level) : 1.0;
      if (serve > 0) {
        serve = max(0.0, serve - dt);
      } else {
        ball += ballV * dt * speed;
        ballV *= pow(.998, dt * 60).toDouble();
      }
      if (ball.dx < .025 || ball.dx > .975) {
        ballV = Offset(-ballV.dx, ballV.dy);
        ball = Offset(ball.dx.clamp(.025, .975), ball.dy);
        JoySounds.instance.play(SoundEffect.wall);
        impact(ball, Colors.white70, count: 4);
      }
      for (var p = 0; p < 2; p++) {
        final d = ball - players[p];
        if (d.distance < (widget.id == 5 ? .1 : .075)) {
          if (widget.id == 5) {
            if ((p == 0 && ballV.dy > 0) || (p == 1 && ballV.dy < 0)) {
              JoySounds.instance.play(SoundEffect.paddle);
              impact(ball, playerColors[p], count: 6 + min(rally, 8));
              rally++;
              final hitSpeed =
                  FieldTuning.hitSpeed * FieldTuning.rallyBoost(rally);
              ballV = Offset(
                (ball.dx - players[p].dx) * 5,
                p == 0 ? -hitSpeed : hitSpeed,
              );
              ball = Offset(ball.dx, players[p].dy + (p == 0 ? -.06 : .06));
            }
          } else {
            JoySounds.instance.play(SoundEffect.puck);
            impact(ball, playerColors[p], count: 8);
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
          rally = 0;
          serve = FieldTuning.serveDelay;
        } else {
          ball = Offset(ball.dx, top ? .01 : .99);
          ballV = Offset(ballV.dx, -ballV.dy);
          JoySounds.instance.play(SoundEffect.wall);
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
      for (var p = 0; p < 2; p++) {
        final want = heldVector(p) * FieldTuning.sumoSpeed;
        final blend = 1 - exp(-dt * FieldTuning.sumoGrip);
        velocity[p] = Offset.lerp(velocity[p], want, blend)!;
        players[p] = clamp(players[p] + velocity[p] * dt);
      }
      final d = players[1] - players[0];
      if (d.distance < .10) {
        if (!touching) {
          JoySounds.instance.play(SoundEffect.bump);
          impact(
            Offset.lerp(players[0], players[1], .5)!,
            Colors.white70,
            count: 10,
            shake: .35,
          );
        }
        touching = true;
        final n = normal(d.distance == 0 ? const Offset(1, 0) : d);
        final push = .009 * dt * 60;
        // Charging into the rival adds weight to the shove, so a good timing
        // beats simply leaning on the other wrestler.
        double charge(Offset v, Offset toward) =>
            max(0.0, v.dx * toward.dx + v.dy * toward.dy) *
            FieldTuning.sumoShove *
            dt;
        players[0] -= n * (push + charge(velocity[1], -n));
        players[1] += n * (push + charge(velocity[0], n));
      } else {
        touching = false;
      }
      final radius = FieldTuning.sumoRadius(time);
      final out = [
        for (var p = 0; p < 2; p++)
          (players[p] - const Offset(.5, .5)).distance > radius,
      ];
      if (out[0] || out[1]) {
        finish(
          out[0] && out[1]
              ? -1
              : out[0]
              ? 1
              : 0,
        );
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
          final hit = [
            for (var p = 0; p < 2; p++) (s.p - players[p]).distance < .16,
          ];
          if (hit[0] || hit[1]) {
            finish(
              hit[0] && hit[1]
                  ? -1
                  : hit[0]
                  ? 1
                  : 0,
            );
            break;
          }
        }
      }
      shots.removeWhere((s) => s.life <= 0);
    }
    if (widget.id == 12) {
      snakeClock += dt;
      if (snakeClock > .16) {
        snakeClock = 0;
        if (vsBot) botSnake();
        for (var p = 0; p < 2; p++) {
          lastMoved[p] = dirs[p];
        }
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
              JoySounds.instance.play(SoundEffect.eat);
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
    repaint.value++;
    if (score[0] != shownScores[0] || score[1] != shownScores[1]) {
      shownScores[0] = score[0];
      shownScores[1] = score[1];
      setState(() {});
    }
  }

  /// Whether the top player is the computer (set every frame by [tick]).
  bool vsBot = false;
  BotSkill botSkill = const BotSkill(Difficulty.normal);

  /// Seconds until the computer opponent acts again.
  double botWait = 0;

  /// The last Parking Duel bay the computer saw, to pause on a new one.
  Offset botGoal = const Offset(.7, .3);

  /// A random think time for the computer, around [base] seconds.
  double thinkSeconds(double base) =>
      botSkill.think(rng, seconds: base).inMilliseconds / 1000;

  /// Drags player [p] toward [goal] at [follow] per second, like a finger.
  void moveToward(int p, Offset goal, double follow, double dt) {
    final delta = goal - players[p];
    final step = min(delta.distance, dt * follow);
    players[p] = clamp(players[p] + normal(delta) * step);
  }

  /// Keeps the computer in its own half in Parking Duel and Air Hockey.
  void keepTopHalf() {
    players[1] = Offset(players[1].dx, players[1].dy.clamp(.05, .45));
  }

  /// Plays the top side for the computer. It uses the same inputs a person
  /// has (steering, a dragged piece, held arrows, shots) and never cheats.
  void computerPlay(double dt) {
    botWait = max(0.0, botWait - dt);
    switch (widget.id) {
      case 0:
        botRally();
      case 2:
        botParking(dt);
      case 6:
        botHockey(dt);
      case 8:
        botBasket();
      case 9:
        botGolf();
      case 10:
        botSumo();
      case 11:
        botTank(dt);
      case 13:
        botBomber(dt);
    }
  }

  /// Neon Rally: ride the gold line and sidestep oncoming traffic.
  void botRally() {
    final x = players[1].dx;
    final gap = (.5 + sin(time * 1.3 + .2) * .28) - x;
    var dir = gap.abs() < .02 ? 0.0 : (gap > 0 ? 1.0 : -1.0);
    final lookAhead = switch (botSkill.level) {
      Difficulty.easy => .18,
      Difficulty.normal => .28,
      Difficulty.hard => .38,
    };
    for (final s in shots) {
      if (s.owner != 1) continue;
      final ahead = s.p.dy - players[1].dy;
      if (ahead < 0 || ahead > lookAhead) continue;
      final side = s.p.dx - x;
      if (side.abs() > .13) continue;
      dir = side > 0 ? -1.0 : 1.0;
      if (x + dir * .1 < .06 || x + dir * .1 > .94) dir = -dir;
      break;
    }
    steer[1] = dir;
  }

  /// Parking Duel: drive to the bay, pausing briefly when a new one opens.
  void botParking(double dt) {
    if (targets[1] != botGoal) {
      botGoal = targets[1];
      botWait = thinkSeconds(.5);
    }
    if (botWait > 0) return;
    final follow =
        FieldTuning.defaultFollow * FieldTuning.botPace(botSkill.level);
    moveToward(1, targets[1], follow, dt);
    keepTopHalf();
  }

  /// Air Hockey: get above the puck and knock it down the table, or guard
  /// the goal when the puck is in the other half.
  void botHockey(double dt) {
    final me = players[1];
    var goal = Offset(.5 + (ball.dx - .5) * .5, .12);
    if (ball.dy < .55) {
      if (ball.dy < me.dy - .02) {
        // The puck got behind the striker: swing round it from the side.
        goal = Offset(ball.dx + (ball.dx < .5 ? .11 : -.11), ball.dy + .05);
      } else {
        goal = Offset(ball.dx, max(.05, ball.dy - .06));
      }
    }
    final follow =
        FieldTuning.hockeyFollow * FieldTuning.botPace(botSkill.level);
    moveToward(1, goal, follow, dt);
    keepTopHalf();
  }

  /// Basket Shots: tap when the sweeping ball lines up with the hoop.
  void botBasket() {
    if (cooldown[1] > 0 || botWait > 0) return;
    final slack = switch (botSkill.level) {
      Difficulty.easy => .14,
      Difficulty.normal => .095,
      Difficulty.hard => .07,
    };
    final gap = (players[1].dx - targets[1].dx).abs();
    if (gap > slack) return;
    if (!botSkill.succeeds(rng)) {
      botWait = .5;
      return;
    }
    cooldown[1] = .45;
    botWait = thinkSeconds(.9);
    if (gap < .10) {
      point(1);
    } else {
      JoySounds.instance.play(SoundEffect.wall);
    }
  }

  /// Mini Golf: once the ball rests, putt it toward the cup with a little
  /// aim and power error that shrinks on harder levels.
  void botGolf() {
    if (botWait > 0 || velocity[1].distance > .08) return;
    final to = targets[1] - players[1];
    if (to.distance < .02) return;
    final error = 1 - botSkill.accuracy;
    final angle = (rng.nextDouble() - .5) * error;
    final power = 1 + (rng.nextDouble() - .5) * error * .8;
    // The ball loses 1.5% of its speed per frame, so it rolls v / 0.9068
    // before stopping: aim the launch speed to stop on the cup.
    final speed = min(1.1, to.distance * .9068 * power);
    final dir = normal(to);
    velocity[1] =
        Offset(
          dir.dx * cos(angle) - dir.dy * sin(angle),
          dir.dx * sin(angle) + dir.dy * cos(angle),
        ) *
        speed;
    strokes[1]++;
    JoySounds.instance.play(SoundEffect.paddle);
    botWait = thinkSeconds(1.0);
  }

  /// Sumo: come back to the middle near the edge, otherwise get between the
  /// rival and the centre and push them outward.
  void botSumo() {
    if (botWait > 0) return;
    botWait = thinkSeconds(.14);
    const center = Offset(.5, .5);
    final me = players[1], foe = players[0];
    final radius = FieldTuning.sumoRadius(time);
    var goal = center;
    if ((me - center).distance <= radius - .09 && botSkill.succeeds(rng)) {
      final out = normal(foe - center);
      final close = (foe - me).distance < .16;
      goal = close ? foe : foe - out * .08;
    }
    final dx = goal.dx - me.dx, dy = goal.dy - me.dy;
    held[1].clear();
    if (dx.abs() > .03) held[1].add(Point(dx > 0 ? 1 : -1, 0));
    if (dy.abs() > .03) held[1].add(Point(0, dy > 0 ? 1 : -1));
  }

  /// Tank Battle: strafe along the top, sidestep incoming shells and fire.
  void botTank(double dt) {
    final me = players[1];
    var goal = Offset(.5 + sin(time * 1.1) * .38, .16 + sin(time * .7) * .07);
    final reach = switch (botSkill.level) {
      Difficulty.easy => .15,
      Difficulty.normal => .25,
      Difficulty.hard => .35,
    };
    for (final s in shots) {
      if (s.owner != 0) continue;
      final heading = normal(s.v);
      final rel = me - s.p;
      final along = rel.dx * heading.dx + rel.dy * heading.dy;
      if (along <= 0 || along > reach) continue;
      final lateral = rel - heading * along;
      if (lateral.distance > .09) continue;
      final side = Offset(-heading.dy, heading.dx);
      final sign = lateral.dx * side.dx + lateral.dy * side.dy < 0 ? -1.0 : 1.0;
      goal = me + side * (.25 * sign);
      break;
    }
    final follow =
        FieldTuning.defaultFollow * FieldTuning.botPace(botSkill.level);
    moveToward(1, goal, follow, dt);
    if (botWait <= 0 && cooldown[1] <= 0) {
      fire(1);
      botWait = thinkSeconds(1.1);
      if (shots.isNotEmpty && shots.last.owner == 1) {
        final miss = (rng.nextDouble() - .5) * (1 - botSkill.accuracy);
        final v = shots.last.v;
        shots.last.v = Offset(
          v.dx * cos(miss) - v.dy * sin(miss),
          v.dx * sin(miss) + v.dy * cos(miss),
        );
      }
    }
  }

  /// Bomber Arena: stalk the rival, drop a bomb up close, then run clear.
  void botBomber(double dt) {
    final me = players[1];
    final follow =
        FieldTuning.defaultFollow * FieldTuning.botPace(botSkill.level);
    final threat = switch (botSkill.level) {
      Difficulty.easy => .20,
      Difficulty.normal => .25,
      Difficulty.hard => .28,
    };
    Shot? nearest;
    var best = threat;
    for (final s in shots) {
      final d = (s.p - me).distance;
      if (d < best) {
        best = d;
        nearest = s;
      }
    }
    if (nearest != null) {
      var away = normal(me - nearest.p);
      if (away == Offset.zero) away = normal(const Offset(.5, .5) - me);
      var goal = clamp(me + away * .5);
      if ((goal - me).distance < .1) {
        goal = clamp(me + Offset(-away.dy, away.dx) * .5);
      }
      moveToward(1, goal, follow, dt);
      return;
    }
    final foe = players[0];
    if ((foe - me).distance > .13) {
      moveToward(1, foe, follow, dt);
    } else if (botWait <= 0 && cooldown[1] <= 0) {
      fire(1);
      botWait = thinkSeconds(1.2);
    }
  }

  bool _snakeFree(Point<int> n) =>
      n.x >= 0 &&
      n.x < 20 &&
      n.y >= 0 &&
      n.y < 20 &&
      !snakes.any((s) => s.contains(n));

  /// Snake Duel: head for the fruit without boxing itself in or running
  /// next to the rival's head. Easy sometimes picks any safe turn instead.
  void botSnake() {
    const moves = [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)];
    final head = snakes[1].first, foe = snakes[0].first;
    final back = lastMoved[1];
    final careful = botSkill.succeeds(rng);
    Point<int>? pick;
    var bestScore = -1e9;
    for (final d in moves) {
      if (d.x == -back.x && d.y == -back.y) continue;
      final n = Point(head.x + d.x, head.y + d.y);
      if (!_snakeFree(n)) continue;
      var room = 0;
      for (final e in moves) {
        if (_snakeFree(Point(n.x + e.x, n.y + e.y))) room++;
      }
      var score = rng.nextDouble() * .5;
      if (careful) {
        score -= (n.x - food.x).abs() + (n.y - food.y).abs();
        if (room == 0) score -= 50;
        if (room == 1) score -= 6;
        if ((n.x - foe.x).abs() + (n.y - foe.y).abs() <= 1) score -= 20;
      } else if (room == 0) {
        score -= 50;
      }
      if (score > bestScore) {
        bestScore = score;
        pick = d;
      }
    }
    if (pick != null) direction(1, pick);
  }

  Offset location(PointerEvent e) =>
      Offset(e.localPosition.dx / area.width, e.localPosition.dy / area.height);
  void down(PointerDownEvent e) {
    if (paused || over || countdown > 0 || arrows) return;
    final v = location(e);
    final p = v.dy > .5 ? 0 : 1;
    if (pointers.containsValue(p) ||
        p == 1 && MatchOptions.read(context)?.computer == true) {
      return;
    }
    pointers[e.pointer] = p;
    if (widget.id == 5) {
      paddleGrip[p] = players[p].dx - v.dx;
      return;
    }
    if (widget.id == 8) {
      if (cooldown[p] > 0) return;
      cooldown[p] = .45;
      if ((players[p].dx - targets[p].dx).abs() < .10) {
        point(p);
      } else {
        JoySounds.instance.play(SoundEffect.wall);
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
    if (widget.id == 5) {
      players[p] = Offset(
        (v.dx + (paddleGrip[p] ?? 0)).clamp(.10, .90),
        p == 0 ? .87 : .13,
      );
      return;
    }
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
    }
  }

  void up(PointerEvent e) {
    final p = pointers.remove(e.pointer);
    if (p == null) return;
    steer[p] = 0;
    aims.remove(p);
    paddleGrip.remove(p);
    if (widget.id == 9 && !paused) {
      velocity[p] = (players[p] - location(e)) * 2.5;
      final speed = velocity[p].distance;
      if (speed > .01) JoySounds.instance.play(SoundEffect.paddle);
      if (speed > 1.1) velocity[p] = normal(velocity[p]) * 1.1;
    }
  }

  void fire(int p) {
    if (paused || over || countdown > 0 || cooldown[p] > 0) return;
    cooldown[p] = widget.id == 13 ? 1 : .5;
    JoySounds.instance.play(SoundEffect.shoot);
    impact(players[p], playerColors[p], count: 5);
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
    // Compare with the last step taken, so two quick taps cannot reverse
    // the snake into its own body before it has moved.
    if (d.x != -lastMoved[p].x || d.y != -lastMoved[p].y) dirs[p] = d;
  }

  /// Turns a direction seen from player [p]'s side into screen coordinates.
  /// The pad of the player across the table is rotated by 180 degrees.
  Point<int> screen(int p, Point<int> d) => p == 0 ? d : Point(-d.x, -d.y);

  /// The direction player [p] is holding, as a unit vector (or zero).
  Offset heldVector(int p) {
    var x = 0, y = 0;
    for (final d in held[p]) {
      x += d.x;
      y += d.y;
    }
    return normal(Offset(x.toDouble(), y.toDouble()));
  }

  void press(int p, Point<int> d) {
    if (widget.id == 12) {
      direction(p, d);
    } else {
      held[p].add(d);
    }
  }

  void release(int p, Point<int> d) => held[p].remove(d);

  static final _arrowKeys = <LogicalKeyboardKey, Point<int>>{
    LogicalKeyboardKey.arrowLeft: const Point(-1, 0),
    LogicalKeyboardKey.arrowUp: const Point(0, -1),
    LogicalKeyboardKey.arrowDown: const Point(0, 1),
    LogicalKeyboardKey.arrowRight: const Point(1, 0),
  };
  static final _wasdKeys = <LogicalKeyboardKey, Point<int>>{
    LogicalKeyboardKey.keyA: const Point(-1, 0),
    LogicalKeyboardKey.keyW: const Point(0, -1),
    LogicalKeyboardKey.keyS: const Point(0, 1),
    LogicalKeyboardKey.keyD: const Point(1, 0),
  };

  /// Keyboard play: the bottom player uses the arrow keys, the top one WASD.
  KeyEventResult onKey(FocusNode node, KeyEvent e) {
    if (!arrows) return KeyEventResult.ignored;
    for (var p = 0; p < 2; p++) {
      if (p == 1 && vsBot) continue;
      final d = (p == 0 ? _arrowKeys : _wasdKeys)[e.logicalKey];
      if (d == null) continue;
      if (e is KeyDownEvent) {
        press(p, d);
      } else if (e is KeyUpEvent) {
        release(p, d);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget controls(int p) {
    final color = playerColors[p];
    final computer = p == 1 && MatchOptions.read(context)?.computer == true;
    if (arrows && !computer) {
      return ArrowPad(
        player: p,
        color: color,
        onPress: (d) => press(p, screen(p, d)),
        onRelease: (d) => release(p, screen(p, d)),
      );
    }
    if ((widget.id == 11 || widget.id == 13) && !computer) {
      return Center(
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: JoyTheme.background,
            minimumSize: const Size(160, 44),
          ),
          onPressed: () => fire(p),
          child: Text(widget.id == 13 ? 'DROP BOMB' : 'FIRE'),
        ),
      );
    }
    final label =
        '${PartyData.instance.colorSymbols ? 'P${p + 1} ' : ''}'
        '${widget.names[p]} • ${score[p]}';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (computer) ...[
              Icon(
                Icons.smart_toy_rounded,
                size: 16,
                color: Color.lerp(color, Colors.white, .35),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: Color.lerp(color, Colors.white, .35),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: focus,
    autofocus: true,
    onKeyEvent: onKey,
    child: arena(),
  );

  Widget arena() => Column(
    children: [
      SizedBox(
        height: arrows ? 58 : 48,
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
                  child: RepaintBoundary(
                    child: ListenableBuilder(
                      listenable: repaint,
                      builder:
                          (context, _) => Transform.translate(
                            offset: juice.offset,
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
                              foregroundPainter: JuicePainter(juice),
                            ),
                          ),
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
      SizedBox(height: arrows ? 72 : 64, child: controls(0)),
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

  /// Draws the Sumo ring. It is the same ellipse the physics uses (radius .43
  /// of the arena, shrinking after a few seconds), with a clay floor, a straw rope and a red edge warning.
  void dohyo(Canvas c, Size s) {
    final radius = FieldTuning.sumoRadius(time);
    final rect = Rect.fromCenter(
      center: s.center(Offset.zero),
      width: radius * 2 * s.width,
      height: radius * 2 * s.height,
    );
    c.drawOval(
      rect.shift(const Offset(0, 8)).inflate(4),
      Paint()
        ..color = Colors.black.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    c.drawOval(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF3B4F82), Color(0xFF263760)],
        ).createShader(rect),
    );
    final ripple =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: .07);
    for (final f in const [.35, .6, .82]) {
      c.drawOval(
        Rect.fromCenter(
          center: rect.center,
          width: rect.width * f,
          height: rect.height * f,
        ),
        ripple,
      );
    }
    // Starting lines, one in each player's colour.
    for (var p = 0; p < 2; p++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s.width * .5, s.height * (p == 0 ? .82 : .18)),
            width: s.width * .16,
            height: 4,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = playerColors[p].withValues(alpha: .45),
      );
    }
    final reach = players
        .map((p) => (p - const Offset(.5, .5)).distance / radius)
        .reduce(max);
    final danger = ((reach - .72) / .28).clamp(0.0, 1.0);
    if (danger > 0) {
      c.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = const Color(0xFFFF6F83).withValues(alpha: danger * .7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    c.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0xFFD9B26A),
    );
    c.drawOval(
      rect.deflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: .35),
    );
    final knot = Paint()..color = const Color(0xFF8C6A32);
    for (var i = 0; i < 28; i++) {
      final angle = 2 * pi * i / 28;
      c.drawCircle(
        rect.center +
            Offset(cos(angle) * rect.width / 2, sin(angle) * rect.height / 2),
        1.8,
        knot,
      );
    }
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
    if (id != 10) {
      c.drawLine(
        Offset(0, s.height / 2),
        Offset(s.width, s.height / 2),
        brush
          ..color = Colors.white24
          ..strokeWidth = 2,
      );
    }
    if (id == 10) {
      dohyo(c, s);
    }
    if (id == 6) {
      final lines =
          Paint()
            ..color = Colors.white.withValues(alpha: .18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(10, 10, s.width - 20, s.height - 20),
          const Radius.circular(18),
        ),
        lines,
      );
      c.drawCircle(at(const Offset(.5, .5)), unit * .16, lines);
      for (final y in [.2, .8]) {
        c.drawCircle(at(Offset(.5, y)), unit * .09, lines);
      }
    }
    if (id == 0) {
      for (final x in [s.width * .025, s.width * .975]) {
        c.drawLine(
          Offset(x, 0),
          Offset(x, s.height),
          Paint()
            ..color = const Color(0xFF6387D3)
            ..strokeWidth = 4,
        );
      }
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
      GameSprites.orb(
        c,
        Offset((food.x + .5) * s.width / 20, (food.y + .5) * s.height / 20),
        unit / 42,
        const Color(0xFFFFC16D),
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
        GameSprites.goal(c, at(targets[p]), unit * .04, id, color);
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
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: at(players[p]) - const Offset(0, 3),
              width: s.width * .18,
              height: 3,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.white.withValues(alpha: .5),
        );
      } else {
        final center = at(players[p]), r = unit * .04;
        if (id <= 4) {
          GameSprites.car(c, center, r, color, reverse: p == 1);
        } else if (id == 11) {
          final direction = at(players[1 - p]) - center;
          GameSprites.tank(
            c,
            center,
            r,
            color,
            atan2(direction.dy, direction.dx) + pi / 2,
          );
        } else if (id == 10) {
          c.drawOval(
            Rect.fromCenter(
              center: center + Offset(0, r * 1.05),
              width: r * 2.4,
              height: r * .8,
            ),
            Paint()..color = Colors.black.withValues(alpha: .3),
          );
          c.drawCircle(
            center,
            r * 1.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = color.withValues(alpha: .45),
          );
          GameSprites.wrestler(c, center, r, color);
        } else if (id == 8) {
          GameSprites.ball(c, center, r, basketball: true);
        } else if (id == 9) {
          GameSprites.ball(c, center, r * .65);
        } else {
          GameSprites.orb(c, center, r, color);
          c.drawCircle(
            center,
            r * .5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.white.withValues(alpha: .55),
          );
        }
      }
    }
    if ([5, 6].contains(id)) {
      GameSprites.ball(c, at(ball), unit * .022, football: false);
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
        GameSprites.bomb(c, at(shot.p), unit * .035, time);
      } else if (id == 0) {
        GameSprites.car(
          c,
          at(shot.p),
          unit * .04,
          const Color(0xFFFFC16D),
          reverse: shot.owner == 0,
        );
      } else {
        c.drawCircle(at(shot.p), unit * .012, brush..color = Colors.amber);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ArenaPainter oldDelegate) => true;
}
