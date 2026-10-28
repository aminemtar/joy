import 'dart:math';
import 'package:flutter/material.dart';
import 'joy_theme.dart';

class JoySplash extends StatefulWidget {
  final VoidCallback onFinished;
  const JoySplash({super.key, required this.onFinished});
  @override
  State<JoySplash> createState() => _JoySplashState();
}

class _JoySplashState extends State<JoySplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  bool complete = false;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener((state) {
      if (state == AnimationStatus.completed) finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.duration =
        MediaQuery.disableAnimationsOf(context)
            ? const Duration(milliseconds: 350)
            : const Duration(milliseconds: 1800);
    if (controller.value == 0 && !controller.isAnimating) controller.forward();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -.25),
              radius: 1.2,
              colors: [Color(0xFFFFEDB5), Color(0xFFFFFBF2)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _OrbitPainter(t)),
              Center(
                child: Opacity(
                  opacity: (t * 4).clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale:
                            .75 +
                            Curves.easeOutBack.transform(
                                  (t * 1.8).clamp(0.0, 1.0),
                                ) *
                                .25,
                        child: Transform.rotate(
                          angle: sin(t * pi * 2) * .04,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(38),
                            child: Image.asset(
                              'assets/art/app_icon.png',
                              width: 155,
                              height: 155,
                              cacheWidth: 400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'JOY',
                        style: TextStyle(
                          color: JoyTheme.purple,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A LITTLE PLAY. A LOT OF HAPPY.',
                        style: TextStyle(
                          color: JoyTheme.muted,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 34),
                      SizedBox(
                        width: 130,
                        child: LinearProgressIndicator(
                          value: t,
                          color: JoyTheme.purple,
                          backgroundColor: Color(0xFFE6DDF4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 35,
                left: 0,
                right: 0,
                child: TextButton(
                  onPressed: finish,
                  child: const Text('Let’s play'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  final double t;
  _OrbitPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    for (var i = 0; i < 14; i++) {
      final a = i * pi / 7 + t * .45,
          r = min(s.width, s.height) * (.32 + (i % 3) * .09);
      final point = center + Offset(cos(a) * r, sin(a) * r * .95);
      c.drawCircle(
        point,
        3 + (i % 3) * 2,
        Paint()
          ..color = [
            const Color(0xFF507CFF),
            const Color(0xFFFF6F83),
            const Color(0xFFFFC16D),
          ][i % 3].withValues(alpha: .20 + .35 * t),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => old.t != t;
}
