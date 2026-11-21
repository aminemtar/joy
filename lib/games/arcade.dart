import '../sound.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'arcade_models.dart';
import 'bot_skill.dart';
import 'game_stage.dart';
import 'juice.dart';
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

  /// Computer opponent state. The computer always plays as player 1.
  double botTimer = -1, botWait = 0, botAge = 0, botDelay = -1, botReact = 0;
  double? botAimX, botJumpAt;
  bool? botSlip;
  bool botArmed = true, botPlanned = false;

  /// Whether player 1 is the computer for this match.
  bool get vsComputer => BotSkill.isComputer(context);

  /// Sparks, floating texts and screen shake drawn over the whole game.
  final juice = Juice();

  /// Sparks and optional shake at [at] (0 to 1 across the whole screen).
  void impact(
    Offset at,
    Color color, {
    int count = 10,
    double shake = 0,
    String? text,
  }) {
    juice.burst(at, color, count: count);
    if (shake > 0) juice.kick(shake);
    if (text != null) juice.pop(at, text, color);
  }

  /// Bumped every frame; only the game canvases listen to it.
  final repaint = ValueNotifier<int>(0);

  /// Fingerprint of everything build() shows outside the canvases.
  int shownState = 0;

  int get stateFingerprint => Object.hash(
    score[0],
    score[1],
    turn,
    shots,
    notice,
    tower.layers.length,
  );

  /// Wraps a canvas so it repaints every frame without rebuilding the page.
  Widget live(Widget Function() canvas) => RepaintBoundary(
    child: ListenableBuilder(
      listenable: repaint,
      builder: (context, _) => canvas(),
    ),
  );
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
    repaint.dispose();
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
    if (widget.id == 14) juice.kick(.8);
    widget.onFinish(
      winner ??
          (score[0] == score[1]
              ? -1
              : score[0] > score[1]
              ? 0
              : 1),
    );
  }

  void drop({bool bot = false}) {
    if (paused || done || countdown > 0) return;
    if (vsComputer && turn == 1 && !bot) return;
    setState(() {
      final accuracy = tower.drop(movingLeft, turn);
      JoySounds.instance.play(
        accuracy == 0 ? SoundEffect.crash : SoundEffect.land,
      );
      if (accuracy == 0) {
        impact(const Offset(.5, .5), Colors.white70, count: 16, shake: .8);
      } else {
        impact(
          const Offset(.5, .5),
          playerColors[turn],
          count: 8,
          shake: .15,
        );
      }
      if (accuracy == 0) {
        finish(1 - turn);
      } else {
        score[turn] += accuracy;
        turn = 1 - turn;
        if (tower.layers.length >= 21) finish();
      }
    });
  }

  void jump(int player, {bool bot = false}) {
    if (paused || done || countdown > 0 || height[player] > 0) return;
    if (vsComputer && player == 1 && !bot) return;
    JoySounds.instance.play(SoundEffect.jump);
    setState(() => jumpVelocity[player] = 1.4);
  }

  double gapLeft(int player) => 1.15 - ((time + player * .25) % 4) * .38;
  void resolveShot(bool goal) {
    if (!flying) return;
    flying = false;
    JoySounds.instance.play(goal ? SoundEffect.swish : SoundEffect.wall);
    if (goal) score[turn]++;
    notice = goal ? 'GOAL!' : 'Saved / off target';
    if (goal) {
      impact(
        const Offset(.5, .35),
        playerColors[turn],
        count: 18,
        shake: .5,
        text: 'GOAL!',
      );
    } else {
      impact(const Offset(.5, .4), Colors.white70, count: 6);
    }
    cooldown = 1.2;
    shots++;
  }

  void tick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6,
        dt = (now - previous).clamp(0.0, .033);
    previous = now;
    juice.enabled =
        JoyEffects.enabled &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    juice.step(dt);
    if ((done || paused) && juice.active) repaint.value++;
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
    if (vsComputer) botThink(dt);
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
        JoySounds.instance.play(SoundEffect.crash);
        impact(const Offset(.5, .5), Colors.orange, count: 20, shake: 1);
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
        juice.pop(
          Offset(.5, car.player == 0 ? .75 : .25),
          '+1',
          playerColors[car.player],
        );
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
    repaint.value++;
    final fingerprint = stateFingerprint;
    if (fingerprint != shownState) {
      shownState = fingerprint;
      setState(() {});
    }
  }

  /// Lets the computer act, using the same actions a human has.
  void botThink(double dt) {
    final skill = BotSkill.of(context);
    switch (widget.id) {
      case 3:
        botTraffic(dt, skill);
      case 4:
        botTower(dt, skill);
      case 7:
        botPenalty(dt, skill);
      case 14:
        botRunner(skill);
    }
  }

  /// Opens the other road when cars queue, but only when nothing is about to
  /// cross. Easy occasionally switches too early and crashes.
  void botTraffic(double dt, BotSkill skill) {
    botTimer -= dt;
    if (botTimer > 0) return;
    final interval = skill.think(random, seconds: .3).inMilliseconds / 1000;
    botTimer = interval;
    final mine = cars.where((c) => c.player == 1).toList();
    final open = phase[1];
    final queued = mine.where(
      (c) => c.axis != open && c.progress > .1 && c.progress <= .37,
    );
    if (queued.isEmpty) {
      botWait = 0;
      return;
    }
    botWait += interval;
    final approaching = mine.any(
      (c) => c.axis == open && c.progress > 0 && c.progress <= .36,
    );
    if (approaching && botWait < 1.3) return;
    final crossing = mine.any(
      (c) => c.axis == open && c.progress > .36 && c.progress < .52,
    );
    final reckless = random.nextDouble() < (1 - skill.accuracy) * .35;
    if (crossing && !reckless) return;
    botWait = 0;
    JoySounds.instance.play(SoundEffect.tap);
    setState(() => phase[1] = 1 - phase[1]);
  }

  /// Waits for the sliding block to line up with the tower, then drops it
  /// after a short reaction delay. A "slip" drops it at a random moment.
  void botTower(double dt, BotSkill skill) {
    if (turn != 1) {
      botAge = 0;
      botDelay = -1;
      botSlip = null;
      return;
    }
    botAge += dt;
    if (botDelay >= 0) {
      botDelay -= dt;
      if (botDelay <= 0) {
        botDelay = -1;
        botSlip = null;
        botAge = 0;
        drop(bot: true);
      }
      return;
    }
    if (botAge < .6) return;
    final top = tower.layers.last;
    botSlip ??= random.nextDouble() < (1 - skill.accuracy) * .3;
    final tolerance = botSlip! ? 1.0 : (1 - skill.accuracy) * .5 * top.width;
    if ((movingLeft - top.left).abs() <= tolerance) {
      botDelay = skill.think(random, seconds: .08).inMilliseconds / 1000;
    }
  }

  /// Shoots when it is the computer's turn and keeps when it is the human's.
  void botPenalty(double dt, BotSkill skill) {
    if (done) return;
    if (turn == 1) {
      if (flying || cooldown > 0) {
        botTimer = -1;
        return;
      }
      if (botTimer < 0) {
        botTimer = skill.think(random, seconds: 1.1).inMilliseconds / 1000;
        return;
      }
      botTimer -= dt;
      if (botTimer <= 0) {
        botTimer = -1;
        botShoot(skill);
      }
      return;
    }
    if (!flying) {
      botPlanned = false;
      if (cooldown <= 0) keeperTarget = .5 + sin(time * 1.3) * .12;
      return;
    }
    if (!botPlanned) {
      botPlanned = true;
      final travel = (ball.dy - .14) / max(.01, -ballVelocity.dy);
      final predicted = ball.dx + ballVelocity.dx * travel;
      final guess = random.nextBool() ? .32 : .68;
      final noise = (random.nextDouble() - .5) * (1 - skill.accuracy) * .5;
      botAimX = skill.succeeds(random) ? predicted + noise : guess;
      botReact = skill.think(random, seconds: .38).inMilliseconds / 1000;
    }
    botReact -= dt;
    if (botReact <= 0 && botAimX != null) {
      keeperTarget = botAimX!.clamp(.15, .85);
    }
  }

  /// Aims for the side away from the human keeper, with a little scatter.
  void botShoot(BotSkill skill) {
    final away = keeper < .5 ? 1.0 : -1.0;
    final wrong = random.nextBool() ? 1.0 : -1.0;
    final side = skill.succeeds(random) ? away : wrong;
    var x = .5 + side * (.2 + random.nextDouble() * .14);
    x += (random.nextDouble() - .5) * (1 - skill.accuracy) * .5;
    launch(Offset(x.clamp(.17, .83) - .5, .14 - .85));
  }

  /// Jumps when the gap is the right distance away. The distance is jittered
  /// per gap, so Easy mistimes now and then and Hard almost never does.
  void botRunner(BotSkill skill) {
    final gap = gapLeft(1);
    if (!botArmed) {
      if (gap > 1) botArmed = true;
      return;
    }
    if (botJumpAt == null) {
      final spread = (1 - skill.accuracy) * .5;
      final jitter = (random.nextDouble() + random.nextDouble() - 1) * spread;
      botJumpAt = .2 + .38 * (.155 + jitter);
    }
    if (gap <= botJumpAt!) {
      botArmed = false;
      botJumpAt = null;
      jump(1, bot: true);
    }
  }

  /// A small label shown where the computer's controls would be.
  Widget computerPill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: playerColors[1].withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: playerColors[1].withValues(alpha: .6)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.smart_toy_rounded, size: 14),
        SizedBox(width: 6),
        Text(
          'Computer',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  void launch(Offset direction) {
    ballVelocity = direction / direction.distance * 1.25;
    flightTime = 0;
    flying = true;
    JoySounds.instance.play(SoundEffect.shoot);
    aim = null;
  }

  Offset local(PointerEvent e) =>
      Offset(e.localPosition.dx / size.width, e.localPosition.dy / size.height);
  void down(PointerDownEvent e) {
    if (done || paused || countdown > 0 || widget.id != 7) return;
    final p = local(e);
    final computer = vsComputer;
    if (p.dy < .4 && keeperPointer == null) {
      if (computer && turn == 0) return;
      keeperPointer = e.pointer;
      keeperTarget = p.dx.clamp(.15, .85);
    } else if (p.dy > .55 &&
        !flying &&
        cooldown <= 0 &&
        shootingPointer == null) {
      if (computer && turn == 1) return;
      shootingPointer = e.pointer;
      aim = p;
    }
  }

  void move(PointerEvent e) {
    if (done || paused) return;
    final p = local(e);
    if (e.pointer == keeperPointer && !(vsComputer && turn == 0)) {
      keeperTarget = p.dx.clamp(.15, .85);
    }
    if (e.pointer == shootingPointer && !flying) aim = p;
  }

  void up(PointerEvent e) {
    if (e.pointer == keeperPointer) keeperPointer = null;
    if (e.pointer != shootingPointer) return;
    shootingPointer = null;
    if (paused || done || flying || cooldown > 0) return;
    if (vsComputer && turn == 1) return;
    final target = local(e), direction = target - const Offset(.5, .85);
    if (direction.dy >= -.12) {
      setState(() => notice = 'Flick upward from the ball toward the goal.');
      return;
    }
    launch(direction);
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
                child: live(
                  () => CustomPaint(
                    size: size,
                    painter: _PenaltyPainter(ball, keeper, turn, aim),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      if (vsComputer) ...[
        computerPill(),
        const SizedBox(height: 6),
        Text(
          turn == 0
              ? 'Your shot: flick the ball upward. The computer keeps.'
              : 'Computer shoots: drag the upper half to guard the goal.',
          textAlign: TextAlign.center,
        ),
      ] else
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
              child: live(
                () => CustomPaint(
                  painter: _TrafficPainter(
                    cars.where((c) => c.player == p).toList(),
                    phase[p],
                    p,
                  ),
                ),
              ),
            ),
            if (vsComputer && p == 1) computerPill(),
            FilledButton.tonal(
              onPressed:
                  vsComputer && p == 1
                      ? null
                      : () {
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
        child: live(
          () => CustomPaint(
            painter: _TowerPainter(tower.layers, movingLeft, turn),
          ),
        ),
      ),
      const SizedBox(height: 20),
      if (vsComputer && turn == 1) computerPill(),
      FilledButton.icon(
        onPressed: vsComputer && turn == 1 ? null : () => drop(),
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
        child: live(
          () => CustomPaint(
            painter: _JumpPainter(height, [gapLeft(0), gapLeft(1)]),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          for (var p = 0; p < 2; p++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child:
                    vsComputer && p == 1
                        ? SizedBox(
                          height: 90,
                          child: Center(child: computerPill()),
                        )
                        : FilledButton(
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
      ListenableBuilder(
        listenable: repaint,
        builder:
            (context, child) =>
                Transform.translate(offset: juice.offset, child: child),
        child: GameStage(
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
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: ListenableBuilder(
              listenable: repaint,
              builder:
                  (context, _) => CustomPaint(painter: JuicePainter(juice)),
            ),
          ),
        ),
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
