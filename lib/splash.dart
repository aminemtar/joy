import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
      duration: const Duration(milliseconds: 2300),
    )..addStatusListener((state) {
        if (state == AnimationStatus.completed) finish();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.duration = MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 350)
        : const Duration(milliseconds: 2300);
    if (controller.value == 0 && !controller.isAnimating) {
      controller.forward();
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

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: JoyTheme.background,
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final t = controller.value;
            final screen = MediaQuery.sizeOf(context);
            final iconSize = min(320.0, screen.width * .78);
            final entrance = Curves.easeOutBack.transform(
              (t * 1.4).clamp(0.0, 1.0),
            );
            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -.18),
                  radius: 1.12,
                  colors: [
                    Color(0xFF315BC0),
                    Color(0xFF172D68),
                    Color(0xFF080F25),
                  ],
                  stops: [0, .52, 1],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _OrbitPainter(t)),
                  Positioned(
                    top: -screen.width * .34,
                    right: -screen.width * .28,
                    child: _AmbientGlow(diameter: screen.width * .9),
                  ),
                  Positioned(
                    bottom: -screen.width * .42,
                    left: -screen.width * .3,
                    child: _AmbientGlow(diameter: screen.width * .95),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Opacity(
                        opacity: (t * 3.5).clamp(0.0, 1.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: .68 + entrance * .32,
                              child: SizedBox(
                                width: iconSize + 94,
                                height: iconSize + 94,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: iconSize + 35,
                                      height: iconSize + 35,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6C9BFF)
                                                .withValues(alpha: .42),
                                            blurRadius: 72,
                                            spreadRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Lottie.asset(
                                      'assets/animations/joy_splash_orbit.json',
                                      width: iconSize + 94,
                                      height: iconSize + 94,
                                      fit: BoxFit.contain,
                                      repeat: true,
                                      animate: !MediaQuery.disableAnimationsOf(
                                        context,
                                      ),
                                    ),
                                    Container(
                                      width: iconSize,
                                      height: iconSize,
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(54),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: .32,
                                          ),
                                          width: 1.5,
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withValues(alpha: .18),
                                            Colors.white.withValues(alpha: .035),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: .38,
                                            ),
                                            blurRadius: 38,
                                            offset: const Offset(0, 22),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(49),
                                        child: Image.asset(
                                          'assets/art/app_icon.png',
                                          width: iconSize,
                                          height: iconSize,
                                          fit: BoxFit.cover,
                                          cacheWidth: 720,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'JOY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 60,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 16,
                                shadows: [
                                  Shadow(
                                    color: Color(0x885D8FFF),
                                    blurRadius: 28,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 13),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .075),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .13),
                                ),
                              ),
                              child: const Text(
                                'SMALL GAMES  •  BIG RIVALRIES',
                                style: TextStyle(
                                  color: Color(0xFFD3E0FF),
                                  letterSpacing: 2.1,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: 150,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: t,
                                  minHeight: 3,
                                  color: const Color(0xFF9DBBFF),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: .14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 28,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: TextButton(
                        onPressed: finish,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: .8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'LET’S PLAY',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

class _AmbientGlow extends StatelessWidget {
  final double diameter;
  const _AmbientGlow({required this.diameter});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF477BFF).withValues(alpha: .13),
                const Color(0xFF477BFF).withValues(alpha: .035),
                Colors.transparent,
              ],
            ),
          ),
        ),
      );
}

class _OrbitPainter extends CustomPainter {
  final double t;
  _OrbitPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - size.height * .04);
    final shortest = min(size.width, size.height);
    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromCenter(
        center: center,
        width: shortest * (.78 + i * .19),
        height: shortest * (.78 + i * .19),
      );
      final paint = Paint()
        ..color = const Color(0xFF8DB2FF).withValues(alpha: .075 - i * .014)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawArc(rect, t * .35 + i, pi * 1.25, false, paint);
    }
    for (var i = 0; i < 18; i++) {
      final angle = i * pi / 9 + t * .42;
      final radius = shortest * (.34 + (i % 4) * .105);
      final point = center +
          Offset(cos(angle) * radius, sin(angle) * radius * .92);
      canvas.drawCircle(
        point,
        1.8 + (i % 3) * .8,
        Paint()
          ..color = [
            const Color(0xFF8DB2FF),
            const Color(0xFF5E91FF),
            const Color(0xFFD2E2FF),
          ][i % 3].withValues(alpha: .18 + .22 * t),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => old.t != t;
}
