import 'dart:math';

import 'package:flutter/material.dart';

import 'game_art.dart';
import 'joy_theme.dart';
import 'sound.dart';

/// The opening scene: a quick ping pong rally between the two players, the
/// last hit bursts into the JOY logo, and a strip of games slides in.
///
/// It is the real game's look (blue player at the bottom, coral on top, the
/// same "tac" sound), so the first seconds already say what Joy is about.
class JoySplash extends StatefulWidget {
  final VoidCallback onFinished;
  const JoySplash({super.key, required this.onFinished});

  @override
  State<JoySplash> createState() => _JoySplashState();
}

/// Moments of the animation, as fractions of the whole (0 to 1).
abstract final class _Beat {
  /// The rally lasts until here; the four paddle hits are evenly spread.
  static const rallyEnd = .42;
  static const hits = 4;

  /// The ball rises to the middle, then bursts into the logo.
  static const burst = .52;
  static const logo = .52;
  static const tagline = .72;
  static const games = .76;
  static const button = .86;
}

class _JoySplashState extends State<JoySplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  bool complete = false, still = false;
  int hitsPlayed = 0;
  bool burstPlayed = false;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 3200),
          )
          ..addListener(_cues)
          ..addStatusListener((state) {
            if (state == AnimationStatus.completed) finish();
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    still = MediaQuery.disableAnimationsOf(context);
    controller.duration = Duration(milliseconds: still ? 350 : 3200);
    if (controller.value == 0 && !controller.isAnimating) {
      controller.forward();
    }
  }

  /// Plays the paddle "tac" on every hit and the horn on the burst.
  void _cues() {
    if (still) return;
    final t = controller.value;
    final due = (t / _Beat.rallyEnd * _Beat.hits).floor().clamp(0, _Beat.hits);
    while (hitsPlayed < due) {
      hitsPlayed++;
      JoySounds.instance.play(SoundEffect.paddle);
    }
    if (!burstPlayed && t >= _Beat.burst) {
      burstPlayed = true;
      JoySounds.instance.play(SoundEffect.goal);
    }
  }

  void finish() {
    if (complete) return;
    complete = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// 0 before [from], 1 after [from] + [length], eased in between.
  static double _phase(double t, double from, double length) =>
      ((t - from) / length).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final logoSize = min(86.0, width * .22);
    return Scaffold(
      backgroundColor: JoyTheme.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.1),
            radius: 1.15,
            colors: [Color(0xFF1B3274), Color(0xFF0F1B45), Color(0xFF080F25)],
            stops: [0, .55, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: _CourtPainter(controller, still: still),
              ),
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final t = still ? 1.0 : controller.value;
                  return Column(
                    children: [
                      const Spacer(flex: 5),
                      _Logo(t: t, size: logoSize),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: _phase(t, _Beat.tagline, .1),
                        child: const Text(
                          'SMALL GAMES  •  BIG RIVALRIES',
                          style: TextStyle(
                            color: Color(0xFFD3E0FF),
                            letterSpacing: 2.2,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _GameStrip(t: t),
                      const Spacer(flex: 4),
                      Opacity(
                        opacity: _phase(t, _Beat.button, .1),
                        child: FilledButton(
                          onPressed: finish,
                          child: const Text('Let’s play'),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three letters of JOY, popping in one after the other in the colours of
/// the players (blue, coral) and the winner's gold.
class _Logo extends StatelessWidget {
  final double t, size;
  const _Logo({required this.t, required this.size});

  static const _letters = ['J', 'O', 'Y'];
  static const _colors = [
    Color(0xFF507CFF),
    Color(0xFFFF6F83),
    Color(0xFFFFC16D),
  ];

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'JOY',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Builder(
            builder: (context) {
              final p = _JoySplashState._phase(
                t,
                _Beat.logo + i * .04,
                .12,
              );
              return Opacity(
                opacity: p,
                child: Transform.scale(
                  scale: Curves.easeOutBack.transform(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _letters[i],
                      style: TextStyle(
                        fontSize: size,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: _colors[i],
                        shadows: [
                          Shadow(
                            color: _colors[i].withValues(alpha: .55),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}

/// A row of real game tiles that slides up, to show what is inside.
class _GameStrip extends StatelessWidget {
  final double t;
  const _GameStrip({required this.t});

  static const _ids = [5, 6, 10, 8, 16];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < _ids.length; i++)
        Builder(
          builder: (context) {
            final p = Curves.easeOutCubic.transform(
              _JoySplashState._phase(t, _Beat.games + i * .025, .12),
            );
            return Opacity(
              opacity: p,
              child: Transform.translate(
                offset: Offset(0, 22 * (1 - p)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GameArt(id: _ids[i], size: 54),
                  ),
                ),
              ),
            );
          },
        ),
    ],
  );
}

/// The ping pong court: two paddles, the ball, its trail, hit sparks and the
/// burst that opens the logo. It repaints from the controller, so nothing
/// else rebuilds while it plays.
class _CourtPainter extends CustomPainter {
  final Animation<double> animation;
  final bool still;
  _CourtPainter(this.animation, {required this.still})
    : super(repaint: animation);

  static const _blue = Color(0xFF507CFF), _coral = Color(0xFFFF6F83);

  /// Where the ball is at time [t] in 0..1 of the screen (x, y).
  Offset ball(double t) {
    final u = (t / _Beat.rallyEnd * _Beat.hits).clamp(0.0, _Beat.hits * 1.0);
    if (t <= _Beat.rallyEnd) {
      // Hit 0 is at the bottom paddle; each hit sends it to the other side.
      final leg = u.floor().clamp(0, _Beat.hits - 1);
      final f = u - leg;
      final fromBottom = leg.isEven;
      final y = fromBottom ? .86 - .72 * f : .14 + .72 * f;
      final x = .5 + sin(u * 1.6 + .4) * .26;
      return Offset(x, y);
    }
    // After the rally the ball rises from the bottom paddle to the centre.
    final rise = Curves.easeIn.transform(
      ((t - _Beat.rallyEnd) / (_Beat.burst - _Beat.rallyEnd)).clamp(0.0, 1.0),
    );
    final end = ball(_Beat.rallyEnd - 1e-6);
    return Offset.lerp(end, const Offset(.5, .42), rise)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = still ? 1.0 : animation.value;
    final brush = Paint();
    Offset at(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

    // The net: a dashed centre line that fades as the logo appears.
    final fade = 1 - ((t - _Beat.burst) / .15).clamp(0.0, 1.0);
    brush
      ..color = Colors.white.withValues(alpha: .10 * fade)
      ..strokeWidth = 2;
    final y = size.height * .5;
    for (var x = 12.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, y), Offset(x + 12, y), brush);
    }

    if (t < _Beat.burst) {
      final u = t / _Beat.rallyEnd * _Beat.hits;
      final rally = t <= _Beat.rallyEnd;
      final pos = ball(t);

      // Paddles follow the ball sideways, a little behind it.
      final px = ball((t - .012).clamp(0.0, _Beat.rallyEnd)).dx;
      final w = size.width * .22;
      for (final top in [false, true]) {
        final centre = at(Offset(px, top ? .09 : .91));
        final hitAge = _hitAge(u, top);
        final swell = rally && hitAge < .25 ? (1 - hitAge / .25) : 0.0;
        brush.color = (top ? _coral : _blue).withValues(alpha: .95);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: centre.translate(0, top ? swell * 6 : -swell * 6),
              width: w * (1 + .12 * swell),
              height: 12,
            ),
            const Radius.circular(8),
          ),
          brush,
        );
        if (swell > 0) {
          canvas.drawCircle(
            at(Offset(pos.dx, top ? .12 : .88)),
            18 + 26 * (1 - swell),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = (top ? _coral : _blue).withValues(alpha: .6 * swell),
          );
        }
      }

      // Trail, then the ball itself.
      for (var k = 7; k >= 1; k--) {
        final p = at(ball((t - k * .006).clamp(0.0, 1.0)));
        brush.color = Colors.white.withValues(alpha: .05 + .02 * (8 - k));
        canvas.drawCircle(p, 7.0 - k * .5, brush);
      }
      brush.color = Colors.white;
      canvas.drawCircle(at(pos), 9, brush);
      canvas.drawCircle(
        at(pos),
        16,
        Paint()
          ..color = Colors.white.withValues(alpha: .18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // The burst: a ring and sparks flying out from the middle of the court.
    final b = ((t - _Beat.burst) / .35).clamp(0.0, 1.0);
    if (b > 0 && b < 1) {
      final centre = at(const Offset(.5, .42));
      final reach = size.shortestSide * .75 * Curves.easeOut.transform(b);
      canvas.drawCircle(
        centre,
        reach,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - b) + 1
          ..color = const Color(0xFFFFC16D).withValues(alpha: .7 * (1 - b)),
      );
      for (var i = 0; i < 18; i++) {
        final a = i * 2 * pi / 18 + .2;
        final r = reach * (.55 + (i % 3) * .2);
        brush.color = [_blue, _coral, const Color(0xFFFFC16D)][i % 3]
            .withValues(alpha: 1 - b);
        canvas.drawCircle(
          centre + Offset(cos(a), sin(a)) * r,
          3.5 * (1 - b) + 1,
          brush,
        );
      }
    }
  }

  /// How far ([u] is the rally progress in hits) since the last hit on a
  /// paddle: the bottom paddle is hit on even hits, the top one on odd hits.
  double _hitAge(double u, bool top) {
    final n = u.floor();
    final last = top ? (n.isOdd ? n : n - 1) : (n.isEven ? n : n - 1);
    return last < 0 ? 9 : u - last;
  }

  @override
  bool shouldRepaint(covariant _CourtPainter old) => old.still != still;
}
