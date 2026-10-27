import 'dart:math';
import 'package:flutter/material.dart';

/// Resolution-independent gameplay sprites keep their silhouettes crisp on
/// tablets and do not change the engine's collision sizes or input coordinates.
class GameSprites {
  static void orb(Canvas c, Offset center, double radius, Color color) {
    c.drawCircle(
      center + Offset(0, radius * .22),
      radius,
      Paint()..color = Colors.black.withValues(alpha: .30),
    );
    c.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.4, -.5),
          colors: [
            Color.lerp(color, Colors.white, .6)!,
            color,
            Color.lerp(color, Colors.black, .35)!,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    c.drawOval(
      Rect.fromCenter(
        center: center + Offset(-radius * .25, -radius * .4),
        width: radius * .6,
        height: radius * .25,
      ),
      Paint()..color = Colors.white.withValues(alpha: .5),
    );
  }

  static void car(
    Canvas c,
    Offset center,
    double radius,
    Color color, {
    bool reverse = false,
  }) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(reverse ? pi : 0);
    c.scale(radius / 24);
    final p = Paint();
    c.drawOval(
      const Rect.fromLTWH(-23, -26, 46, 65),
      p..color = Colors.black.withValues(alpha: .35),
    );
    for (final x in [-23.0, 15.0]) {
      for (final y in [-21.0, 14.0]) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 8, 15),
            const Radius.circular(3),
          ),
          p..color = const Color(0xFF080F23),
        );
      }
    }
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-19, -32, 38, 66),
      const Radius.circular(13),
    );
    c.drawRRect(
      body,
      p
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, .4)!,
            color,
            Color.lerp(color, Colors.black, .3)!,
          ],
        ).createShader(body.outerRect),
    );
    p.shader = null;
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, -16, 28, 22),
        const Radius.circular(7),
      ),
      p..color = const Color(0xFF101F3B),
    );
    c.drawPath(
      Path()
        ..moveTo(-12, -13)
        ..lineTo(10, -13)
        ..lineTo(-9, 2)
        ..close(),
      p..color = const Color(0xFF92C9FF).withValues(alpha: .65),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13, 12, 26, 11),
        const Radius.circular(4),
      ),
      p..color = const Color(0xFF172745),
    );
    for (final x in [-13.0, 8.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -27, 6, 5),
          const Radius.circular(2),
        ),
        p..color = const Color(0xFFFFEDB3),
      );
      c.drawRect(
        Rect.fromLTWH(x, 27, 6, 3),
        p..color = const Color(0xFFFF9099),
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2, -30, 4, 12),
        const Radius.circular(2),
      ),
      p..color = Colors.white.withValues(alpha: .6),
    );
    c.restore();
  }

  static void tank(
    Canvas c,
    Offset center,
    double radius,
    Color color,
    double angle,
  ) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(angle);
    c.scale(radius / 24);
    final p = Paint();
    for (final x in [-25.0, 15.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -27, 10, 54),
          const Radius.circular(5),
        ),
        p..color = const Color(0xFF080F23),
      );
      for (var y = -22.0; y < 26; y += 8) {
        c.drawLine(
          Offset(x + 1, y),
          Offset(x + 9, y),
          p
            ..color = const Color(0xFF65718D)
            ..strokeWidth = 2,
        );
      }
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -23, 36, 46),
        const Radius.circular(7),
      ),
      p..color = color,
    );
    orb(c, Offset.zero, 14, color);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, -37, 10, 31),
        const Radius.circular(3),
      ),
      p..color = Color.lerp(color, Colors.white, .25)!,
    );
    c.drawRect(
      const Rect.fromLTWH(-5, -37, 10, 5),
      p..color = const Color(0xFF1B2844),
    );
    c.restore();
  }

  static void bomb(Canvas c, Offset center, double radius, double time) {
    orb(c, center, radius, const Color(0xFF34425D));
    final p =
        Paint()
          ..color = const Color(0xFFEDBD75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * .16;
    c.drawArc(
      Rect.fromLTWH(center.dx, center.dy - radius * 1.5, radius, radius),
      pi,
      pi,
      false,
      p,
    );
    final spark = center + Offset(radius, -radius);
    orb(
      c,
      spark,
      radius * (.15 + .07 * sin(time * 18)),
      const Color(0xFFFFB74D),
    );
  }

  static void ball(
    Canvas c,
    Offset center,
    double radius, {
    bool football = false,
    bool basketball = false,
  }) {
    orb(
      c,
      center,
      radius,
      basketball ? const Color(0xFFFFAB55) : const Color(0xFFF5F4F0),
    );
    final p =
        Paint()
          ..color = const Color(0xFF25304B)
          ..strokeWidth = max(1, radius * .09)
          ..style = PaintingStyle.stroke;
    if (basketball) {
      c.drawLine(center + Offset(-radius, 0), center + Offset(radius, 0), p);
      c.drawLine(center + Offset(0, -radius), center + Offset(0, radius), p);
      c.drawOval(
        Rect.fromCenter(center: center, width: radius, height: radius * 1.85),
        p,
      );
    }
    if (football) {
      final path = Path();
      for (var i = 0; i < 5; i++) {
        final a = -pi / 2 + i * pi * 2 / 5;
        final pt = center + Offset(cos(a), sin(a)) * radius * .45;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      c.drawPath(path, p..style = PaintingStyle.fill);
      for (var i = 0; i < 5; i++) {
        final a = -pi / 2 + i * pi * 2 / 5;
        c.drawLine(
          center + Offset(cos(a), sin(a)) * radius * .45,
          center + Offset(cos(a), sin(a)) * radius * .92,
          p..style = PaintingStyle.stroke,
        );
      }
    }
  }

  static void wrestler(Canvas c, Offset center, double radius, Color color) {
    orb(c, center, radius, const Color(0xFFF2C4A7));
    final p = Paint();
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, radius * .4),
          width: radius * 1.9,
          height: radius * .65,
        ),
        Radius.circular(radius * .2),
      ),
      p..color = color,
    );
    for (final sign in [-1, 1]) {
      orb(
        c,
        center + Offset(radius * .95 * sign, 0),
        radius * .32,
        const Color(0xFFF2C4A7),
      );
    }
    c.drawArc(
      Rect.fromCircle(
        center: center - Offset(0, radius * .2),
        radius: radius * .55,
      ),
      pi,
      pi,
      false,
      p
        ..color = const Color(0xFF25304B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .2,
    );
  }

  static void goal(
    Canvas c,
    Offset center,
    double radius,
    int type,
    Color color,
  ) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    if (type == 2) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: radius * 1.7,
            height: radius * 2.4,
          ),
          Radius.circular(radius * .2),
        ),
        p,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: 'P',
          style: TextStyle(
            color: color,
            fontSize: radius * 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
    }
    if (type == 8) {
      c.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * .85,
        ),
        p
          ..color = const Color(0xFFFFBC6D)
          ..strokeWidth = 3,
      );
      for (var i = -1; i <= 1; i++) {
        c.drawLine(
          center + Offset(i * radius * .7, 0),
          center + Offset(i * radius * .4, radius),
          p
            ..color = Colors.white60
            ..strokeWidth = 1,
        );
      }
      c.drawLine(
        center + Offset(-radius * .4, radius),
        center + Offset(radius * .4, radius),
        p,
      );
    }
    if (type == 9) {
      c.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 1.5,
          height: radius * .65,
        ),
        p
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF060D1D),
      );
      c.drawLine(
        center,
        center - Offset(0, radius * 2),
        p
          ..color = Colors.white
          ..strokeWidth = 2,
      );
      c.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - radius * 2)
          ..lineTo(center.dx + radius, center.dy - radius * 1.65)
          ..lineTo(center.dx, center.dy - radius * 1.3)
          ..close(),
        p..color = color,
      );
    }
  }
}
