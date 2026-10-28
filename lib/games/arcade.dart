import '../sound.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'arcade_models.dart';
import 'game_stage.dart';
import 'sprites.dart';

class ArcadeGame extends StatefulWidget {
  final int id;
  final List<String> names;
  final ValueChanged<int> onFinish;
  const ArcadeGame({
    super.key,
    required this.id,
    required this.names,
    required this.onFinish,
  });
  @override
  State<ArcadeGame> createState() => _ArcadeGameState();
}

class _ArcadeGameState extends State<ArcadeGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Ticker ticker;
  double previous = 0,
      time = 0,
      countdown = 3,
      spawn = 0,
      flightTime = 0,
      cooldown = 0,
      keeper = .5,
      keeperTarget = .5;
  bool paused = false, done = false, flying = false;
  final score = [0, 0],
      phase = [0, 0],
      height = [0.0, 0.0],
      jumpVelocity = [0.0, 0.0];
  final cars = <TrafficCar>[];
  final tower = TowerBoard();
  final random = Random();
  int turn = 0, shots = 0;
  Offset ball = const Offset(.5, .85), ballVelocity = Offset.zero;
  Offset? aim;
  int? shootingPointer, keeperPointer;
  String notice = '';
  Size size = Size.zero;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    JoySounds.instance.play(SoundEffect.tick);
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

  double get movingLeft =>
      (sin(time * 1.7) + 1) / 2 * (1 - tower.layers.last.width);
  void finish([int? winner]) {
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

  void drop() {
    if (paused || done || countdown > 0) return;
    setState(() {
      final accuracy = tower.drop(movingLeft, turn);
      JoySounds.instance.play(
        accuracy == 0 ? SoundEffect.wrong : SoundEffect.hit,
      );
      if (accuracy == 0) {
        finish(1 - turn);
      } else {
        score[turn] += accuracy;
        turn = 1 - turn;
        if (tower.layers.length >= 21) finish();
      }
    });
  }

  void jump(int player) {
    if (paused || done || countdown > 0 || height[player] > 0) return;
    JoySounds.instance.play(SoundEffect.jump);
    setState(() => jumpVelocity[player] = 1.4);
  }

  double gapLeft(int player) => 1.15 - ((time + player * .25) % 4) * .38;
  void resolveShot(bool goal) {
    if (!flying) return;
    flying = false;
    JoySounds.instance.play(goal ? SoundEffect.correct : SoundEffect.wrong);
    if (goal) score[turn]++;
    notice = goal ? 'GOAL!' : 'Saved / off target';
    cooldown = 1.2;
    shots++;
  }

  void tick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6,
        dt = (now - previous).clamp(0.0, .033);
    previous = now;
    if (done || paused) return;
    if (countdown > 0) {
      final before = countdown.ceil();
      setState(() => countdown -= dt);
      if (countdown.ceil() != before) {
        JoySounds.instance.play(
          countdown <= 0 ? SoundEffect.start : SoundEffect.tick,
        );
      }
      return;
    }
    time += dt;
    if (widget.id == 3) {
      spawn += dt;
      if (spawn >= 1.15) {
        spawn = 0;
        final axis = random.nextInt(2);
        for (var p = 0; p < 2; p++) {
          cars.add(TrafficCar(p, axis));
        }
      }
      for (final car in cars) {
        final ahead =
            cars
                .where(
                  (other) =>
                      other != car &&
                      other.player == car.player &&
                      other.axis == car.axis &&
                      other.progress > car.progress,
                )
                .map((other) => other.progress)
                .toList();
        var next = car.progress + dt * .48;
        if (car.progress <= .36 && phase[car.player] != car.axis) {
          next = min(.36, next);
        }
        if (ahead.isNotEmpty) {
          next = min(next, ahead.reduce(min) - .13);
        }
        car.progress = max(car.progress, next);
      }
      final dead = [for (var p = 0; p < 2; p++) trafficCollision(cars, p)];
      if (dead.any((d) => d)) {
        finish(
          dead.every((d) => d)
              ? -1
              : dead[0]
              ? 1
              : 0,
        );
      }
      for (final car in cars.where((c) => c.progress > 1.05)) {
        score[car.player]++;
        JoySounds.instance.play(SoundEffect.correct);
      }
      cars.removeWhere((c) => c.progress > 1.05);
      if (score.any((s) => s >= 12) || time >= 60) finish();
    }
    if (widget.id == 14) {
      final dead = [false, false];
      for (var p = 0; p < 2; p++) {
        jumpVelocity[p] -= dt * 3.6;
        height[p] = max(0, height[p] + jumpVelocity[p] * dt);
        if (height[p] == 0) jumpVelocity[p] = 0;
        final gap = gapLeft(p);
        dead[p] = height[p] < .035 && .2 > gap && .2 < gap + .18;
        score[p] = (time / 4).floor();
      }
      if (dead.any((d) => d)) {
        finish(
          dead.every((d) => d)
              ? -1
              : dead[0]
              ? 1
              : 0,
        );
      }
    }
    if (widget.id == 7) {
      keeper += (keeperTarget - keeper).clamp(-dt * .85, dt * .85);
      if (cooldown > 0) {
        cooldown -= dt;
        if (cooldown <= 0) {
          if (shots >= 10 &&
              shots.isEven &&
              (score[0] != score[1] || shots >= 16)) {
            finish();
          } else {
            turn = 1 - turn;
            ball = const Offset(.5, .85);
            ballVelocity = Offset.zero;
            notice = '';
            aim = null;
          }
        }
      } else if (flying) {
        flightTime += dt;
        ball += ballVelocity * dt;
        if (ball.dy <= .14) {
          resolveShot(
            ball.dx > .15 && ball.dx < .85 && (ball.dx - keeper).abs() > .12,
          );
        } else if (ball.dx < 0 || ball.dx > 1 || flightTime > 2) {
          resolveShot(false);
        }
      }
    }
    setState(() {});
  }

  Offset local(PointerEvent e) =>
      Offset(e.localPosition.dx / size.width, e.localPosition.dy / size.height);
  void down(PointerDownEvent e) {
    if (done || paused || countdown > 0 || widget.id != 7) return;
    final p = local(e);
    if (p.dy < .4 && keeperPointer == null) {
      keeperPointer = e.pointer;
      keeperTarget = p.dx.clamp(.15, .85);
    } else if (p.dy > .55 &&
        !flying &&
        cooldown <= 0 &&
        shootingPointer == null) {
      shootingPointer = e.pointer;
      aim = p;
    }
  }

  void move(PointerEvent e) {
    if (done || paused) return;
    final p = local(e);
    if (e.pointer == keeperPointer) keeperTarget = p.dx.clamp(.15, .85);
    if (e.pointer == shootingPointer && !flying) aim = p;
  }

  void up(PointerEvent e) {
    if (e.pointer == keeperPointer) keeperPointer = null;
    if (e.pointer != shootingPointer) return;
    shootingPointer = null;
    if (paused || done || flying || cooldown > 0) return;
    final target = local(e), direction = target - const Offset(.5, .85);
    if (direction.dy >= -.12) {
      setState(() => notice = 'Flick upward from the ball toward the goal.');
      return;
    }
    ballVelocity = direction / direction.distance * 1.25;
    flightTime = 0;
    flying = true;
    JoySounds.instance.play(SoundEffect.shoot);
    aim = null;
  }

  Widget penalty() => Column(
    children: [
      Text(
        '${widget.names[turn]} shoots • ${widget.names[1 - turn]} keeps\nShot ${shots + 1} • 5 shots each, then up to 3 sudden-death pairs',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 10),
      AspectRatio(
        aspectRatio: .65,
        child: LayoutBuilder(
          builder: (c, box) {
            size = Size(box.maxWidth, box.maxHeight);
            return GestureDetector(
              onPanStart: (_) {},
              onPanUpdate: (_) {},
              onPanEnd: (_) {},
              child: Listener(
                onPointerDown: down,
                onPointerMove: move,
                onPointerUp: up,
                onPointerCancel: (e) {
                  if (e.pointer == shootingPointer) {
                    shootingPointer = null;
                    aim = null;
                  }
                  if (e.pointer == keeperPointer) keeperPointer = null;
                },
                child: CustomPaint(
                  size: size,
                  painter: _PenaltyPainter(ball, keeper, turn, aim),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Keeper: drag the upper half. Shooter: flick the ball upward.\nRoles switch after each shot.',
        textAlign: TextAlign.center,
      ),
    ],
  );
  Widget traffic() => Column(
    children: [
      for (final p in [1, 0])
        Column(
          children: [
            Text(
              widget.names[p],
              style: TextStyle(
                color: playerColors[p],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.5,
              child: CustomPaint(
                painter: _TrafficPainter(
                  cars.where((c) => c.player == p).toList(),
                  phase[p],
                  p,
                ),
              ),
            ),
            FilledButton.tonal(
              onPressed: () {
                JoySounds.instance.play(SoundEffect.tap);
                setState(() => phase[p] = 1 - phase[p]);
              },
              child: Text(
                phase[p] == 0
                    ? 'East–west open • Switch to north–south'
                    : 'North–south open • Switch to east–west',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      const Text(
        'Do not switch while a car is crossing. First to 12 safely delivered cars wins; a collision loses.',
        textAlign: TextAlign.center,
      ),
    ],
  );
  Widget towerView() => Column(
    children: [
      AspectRatio(
        aspectRatio: .85,
        child: CustomPaint(
          painter: _TowerPainter(tower.layers, movingLeft, turn),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: drop,
        icon: const Icon(Icons.arrow_downward),
        label: Text('${widget.names[turn]} — drop block'),
      ),
      const SizedBox(height: 12),
      const Text(
        'Only the overlapping part stays. A miss loses immediately. Survive 20 drops for an accuracy-score finish.',
        textAlign: TextAlign.center,
      ),
    ],
  );
  Widget runner() => Column(
    children: [
      AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _JumpPainter(height, [gapLeft(0), gapLeft(1)]),
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          for (var p = 0; p < 2; p++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: playerColors[p],
                    minimumSize: const Size(0, 90),
                  ),
                  onPressed: () => jump(p),
                  child: Text(
                    '${widget.names[p]}\nJUMP',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 15),
      const Text(
        'Jump across scrolling gaps. You can jump again only after landing.',
        textAlign: TextAlign.center,
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      GameStage(
        names: widget.names,
        scores: score,
        turn: widget.id == 3 || widget.id == 14 ? -1 : turn,
        message:
            notice.isNotEmpty
                ? notice
                : widget.id == 3
                ? 'Control two independent intersections'
                : widget.id == 4
                ? 'Place, trim, balance'
                : widget.id == 14
                ? 'Last runner standing wins'
                : 'Flick a shot past the human goalkeeper',
        child:
            widget.id == 3
                ? traffic()
                : widget.id == 4
                ? towerView()
                : widget.id == 7
                ? penalty()
                : runner(),
      ),
      Positioned(
        right: 10,
        top: 0,
        child: IconButton(
          onPressed: () => setState(() => paused = !paused),
          icon: Icon(paused ? Icons.play_arrow : Icons.pause),
        ),
      ),
      if (paused || countdown > 0)
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withValues(alpha: .65),
            child: Center(
              child:
                  paused
                      ? FilledButton(
                        onPressed: () => setState(() => paused = false),
                        child: const Text('Resume'),
                      )
                      : Text(
                        '${countdown.ceil()}',
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
            ),
          ),
        ),
    ],
  );
}

class _TrafficPainter extends CustomPainter {
  final List<TrafficCar> cars;
  final int phase, player;
  _TrafficPainter(this.cars, this.phase, this.player);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(20)),
      p..color = const Color(0xFF1C294A),
    );
    c.drawRect(
      Rect.fromLTWH(0, s.height * .35, s.width, s.height * .3),
      p..color = const Color(0xFF0B142B),
    );
    c.drawRect(Rect.fromLTWH(s.width * .38, 0, s.width * .24, s.height), p);
    for (final axis in [0, 1]) {
      final color =
          phase == axis ? const Color(0xFF70ABFF) : const Color(0xFFFF6F83);
      c.drawCircle(
        axis == 0
            ? Offset(s.width * .32, s.height * .31)
            : Offset(s.width * .66, s.height * .29),
        5,
        p..color = color,
      );
    }
    for (final car in cars) {
      final position =
          car.axis == 0
              ? Offset(car.progress * s.width, s.height * .5)
              : Offset(s.width * .5, car.progress * s.height);
      c.save();
      c.translate(position.dx, position.dy);
      c.rotate(car.axis == 0 ? pi / 2 : pi);
      GameSprites.car(
        c,
        Offset.zero,
        min(s.width, s.height) * .045,
        playerColors[player],
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TrafficPainter old) => true;
}

class _TowerPainter extends CustomPainter {
  final List<TowerLayer> layers;
  final double moving;
  final int turn;
  _TowerPainter(this.layers, this.moving, this.turn);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(20)),
      p..color = const Color(0xFF111C37),
    );
    final visible = layers.skip(max(0, layers.length - 12)).toList(),
        h = s.height / 16;
    for (var i = 0; i < visible.length; i++) {
      final layer = visible[i];
      final rect = Rect.fromLTWH(
        layer.left * s.width,
        s.height - (i + 2) * h,
        layer.width * s.width,
        h * .85,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        p
          ..color =
              layer.player < 0
                  ? const Color(0xFF93A5C8)
                  : playerColors[layer.player],
      );
      c.drawLine(
        rect.topLeft + const Offset(4, 3),
        rect.topRight + const Offset(-4, 3),
        p
          ..color = Colors.white38
          ..strokeWidth = 2,
      );
    }
    final y = s.height - (visible.length + 2) * h;
    final rect = Rect.fromLTWH(
      moving * s.width,
      y,
      layers.last.width * s.width,
      h * .85,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      p..color = playerColors[turn],
    );
  }

  @override
  bool shouldRepaint(covariant _TowerPainter old) => true;
}

class _JumpPainter extends CustomPainter {
  final List<double> heights, gaps;
  _JumpPainter(this.heights, this.gaps);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    for (var player = 0; player < 2; player++) {
      final base = s.height * (player == 0 ? .42 : .92);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, base, s.width, 12),
          const Radius.circular(5),
        ),
        p..color = const Color(0xFF57709F),
      );
      c.save();
      c.clipRect(Rect.fromLTWH(0, base, s.width, 15));
      c.drawRect(
        Rect.fromLTWH(gaps[player] * s.width, base, s.width * .18, 15),
        p..color = const Color(0xFF0B1128),
      );
      c.restore();
      GameSprites.orb(
        c,
        Offset(s.width * .2, base - 15 - heights[player] * s.height),
        14,
        playerColors[player],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JumpPainter old) => true;
}

class _PenaltyPainter extends CustomPainter {
  final Offset ball;
  final double keeper;
  final int shooter;
  final Offset? aim;
  _PenaltyPainter(this.ball, this.keeper, this.shooter, this.aim);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    Offset at(Offset v) => Offset(v.dx * s.width, v.dy * s.height);
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(20)),
      p..color = const Color(0xFF18314E),
    );
    c.drawRect(
      Rect.fromLTWH(
        s.width * .15,
        s.height * .05,
        s.width * .7,
        s.height * .09,
      ),
      p..color = Colors.white12,
    );
    for (var x = .15; x <= .85; x += .07) {
      c.drawLine(
        Offset(s.width * x, s.height * .05),
        Offset(s.width * x, s.height * .14),
        p
          ..color = Colors.white24
          ..strokeWidth = 1,
      );
    }
    c.drawRect(
      Rect.fromLTWH(
        s.width * .15,
        s.height * .05,
        s.width * .7,
        s.height * .09,
      ),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white70,
    );
    p.style = PaintingStyle.fill;
    GameSprites.orb(
      c,
      at(Offset(keeper, .14)),
      s.width * .06,
      playerColors[1 - shooter],
    );
    if (aim != null) {
      c.drawLine(
        at(ball),
        at(aim!),
        p
          ..color = Colors.amber
          ..strokeWidth = 2,
      );
    }
    GameSprites.ball(c, at(ball), s.width * .035, football: true);
  }

  @override
  bool shouldRepaint(covariant _PenaltyPainter old) => true;
}
