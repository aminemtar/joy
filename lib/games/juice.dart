import 'dart:math';

import 'package:flutter/material.dart';

/// One short-lived spark of an impact burst, in arena coordinates (0 to 1).
class Spark {
  Offset position;
  final Offset velocity;
  final Color color;
  final double size, lifetime;
  double age = 0;
  Spark(this.position, this.velocity, this.color, this.size, this.lifetime);
}

/// Cheap "game feel": sparks where things collide and a short screen shake
/// when something big happens (a goal, a blast, a crash).
///
/// Games call [burst] and [kick] next to the matching sound effect. Both do
/// nothing when [enabled] is false, which follows the reduced-motion setting,
/// so the game plays exactly the same with the effects off.
class Juice {
  /// Whether sparks and shake are shown (off for reduced motion).
  bool enabled = true;

  /// The sparks alive right now.
  final sparks = <Spark>[];

  /// Current shake strength from 0 (still) to 1 (hard hit).
  double shake = 0;

  final Random _random = Random();
  static const _maxSparks = 80;

  /// Whether anything is still moving, so a finished game keeps repainting
  /// until the last spark fades and the shake settles.
  bool get active => sparks.isNotEmpty || shake > .01;

  /// Throws [count] sparks of [color] outward from [at].
  void burst(
    Offset at,
    Color color, {
    int count = 8,
    double power = .5,
    double size = 3,
  }) {
    if (!enabled) return;
    for (var i = 0; i < count && sparks.length < _maxSparks; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = power * (.4 + _random.nextDouble() * .6);
      sparks.add(
        Spark(
          at,
          Offset(cos(angle), sin(angle)) * speed,
          color,
          size * (.7 + _random.nextDouble() * .6),
          .28 + _random.nextDouble() * .22,
        ),
      );
    }
  }

  /// Shakes the screen; a stronger kick wins over a weaker one in progress.
  void kick(double amount) {
    if (enabled) shake = max(shake, amount.clamp(0.0, 1.0));
  }

  /// Moves every spark forward by [dt] seconds and settles the shake.
  void step(double dt) {
    for (final s in sparks) {
      s.age += dt;
      s.position += s.velocity * dt;
    }
    sparks.removeWhere((s) => s.age >= s.lifetime);
    shake = max(0.0, shake - dt * 3.2);
  }

  /// Where to draw the arena this frame, in logical pixels.
  Offset get offset {
    if (shake <= .01) return Offset.zero;
    final amplitude = shake * 7;
    return Offset(
      (_random.nextDouble() - .5) * 2 * amplitude,
      (_random.nextDouble() - .5) * 2 * amplitude,
    );
  }
}

/// Draws the sparks of a [Juice] on top of the arena.
class JuicePainter extends CustomPainter {
  final Juice juice;
  JuicePainter(this.juice);
  final _brush = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in juice.sparks) {
      final fade = 1 - s.age / s.lifetime;
      _brush.color = s.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(s.position.dx * size.width, s.position.dy * size.height),
        s.size * (.4 + .6 * fade),
        _brush,
      );
    }
  }

  @override
  bool shouldRepaint(covariant JuicePainter oldDelegate) => true;
}
