import 'dart:math';

import 'package:flutter/material.dart';

/// The player's choice for sparks, floating texts and screen shake, separate
/// from vibration and sound so each channel can be switched off on its own.
abstract final class JoyEffects {
  /// Whether hit effects are switched on in Settings.
  static bool enabled = true;
}

/// One short-lived spark of an impact burst, in arena coordinates (0 to 1).
class Spark {
  Offset position;
  final Offset velocity;
  final Color color;
  final double size, lifetime;
  double age = 0;
  Spark(this.position, this.velocity, this.color, this.size, this.lifetime);
}

/// A short text that floats up from a spot and fades, such as "+1".
class Pop {
  Offset position;
  final String text;
  final Color color;
  double age = 0;
  static const lifetime = .9;
  Pop(this.position, this.text, this.color);
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

  /// The floating texts alive right now.
  final pops = <Pop>[];

  /// Current shake strength from 0 (still) to 1 (hard hit).
  double shake = 0;

  final Random _random = Random();
  static const _maxSparks = 80;

  /// Whether anything is still moving, so a finished game keeps repainting
  /// until the last spark fades and the shake settles.
  bool get active => sparks.isNotEmpty || pops.isNotEmpty || shake > .01;

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

  /// Floats [text] up from [at], kept inside the arena.
  void pop(Offset at, String text, Color color) {
    if (!enabled || pops.length >= 6) return;
    pops.add(
      Pop(Offset(at.dx.clamp(.1, .9), at.dy.clamp(.12, .88)), text, color),
    );
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
    for (final p in pops) {
      p.age += dt;
      p.position = p.position.translate(0, -.12 * dt);
    }
    pops.removeWhere((p) => p.age >= Pop.lifetime);
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
    for (final p in juice.pops) {
      final t = p.age / Pop.lifetime;
      // Pop in quickly, then fade out.
      final scale = t < .15 ? .6 + t / .15 * .6 : 1.2 - (t - .15) * .2;
      final text = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontSize: 26 * scale,
            fontWeight: FontWeight.w900,
            color: p.color.withValues(alpha: (1 - t * t).clamp(0.0, 1.0)),
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(
          p.position.dx * size.width - text.width / 2,
          p.position.dy * size.height - text.height / 2,
        ),
      );
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant JuicePainter oldDelegate) => true;
}
