import 'dart:math';

import 'package:flutter/material.dart';

import 'games/sprites.dart';
import 'joy_theme.dart';

const _coral = Color(0xFFFF6F83);
const _amber = Color(0xFFFFC16D);
const _violet = Color(0xFFA08AFF);
const _green = Color(0xFF4CD08A);
const _clay = Color(0xFF9C7352);
const _turf = Color(0xFF1F6F4A);

/// Games whose tutorial shows a finger dragging.
const tutorialDragGames = {0, 2, 5, 6, 7, 9, 11, 13};

/// Games played with arrow buttons or the keyboard.
const tutorialArrowGames = {10, 12};

/// The caption under the animated demonstration.
String tutorialHint(int id) {
  if (tutorialArrowGames.contains(id)) {
    return 'Demonstration: hold an arrow button to move.';
  }
  if (tutorialDragGames.contains(id)) {
    return 'Demonstration: drag the highlighted control.';
  }
  return 'Demonstration: tap the highlighted target.';
}

/// Paints a small looping scene that looks like the game it explains.
///
/// [t] runs from 0 to 1 and repeats. Every scene draws its own pointer, so the
/// demonstration shows the real gesture: a drag, a tap or a held arrow.
void paintTutorialScene(Canvas c, Size s, double t, int id) {
  final p = _Pen(c, s, t);
  p.rrect(Offset.zero & s, JoyTheme.surface, radius: 24);
  switch (id) {
    case 0:
      _rally(p);
    case 1:
      _auction(p);
    case 2:
      _parking(p);
    case 3:
      _traffic(p);
    case 4:
      _stack(p);
    case 5:
      _pong(p);
    case 6:
      _hockey(p);
    case 7:
      _penalty(p);
    case 8:
      _basket(p);
    case 9:
      _golf(p);
    case 10:
      _sumo(p);
    case 11:
      _tank(p);
    case 12:
      _snake(p);
    case 13:
      _bomber(p);
    case 14:
      _runner(p);
    case 15:
      _sliding(p);
    case 16:
      _reversi(p);
    case 17:
      _maze(p);
    case 18:
      _connect(p);
    case 19:
      _tictactoe(p);
    case 20:
      _pairs(p);
    case 21:
      _spot(p);
    case 22:
      _hidden(p);
    case 23:
      _simon(p);
    case 24:
      _cups(p);
    case 25:
      _riddle(p);
    case 26:
      _math(p);
    case 27:
      _reaction(p);
    case 28:
      _scramble(p);
    case 29:
      _rps(p);
    case 30:
      _crossword(p);
    case 31:
      _wordSearch(p);
    case 32:
      _dots(p);
    case 33:
      _battleship(p);
    case 34:
      _code(p);
    default:
      _mines(p);
  }
}

class _Pen {
  final Canvas c;
  final Size s;
  final double t;
  final Paint _paint = Paint();
  _Pen(this.c, this.s, this.t);

  double get w => s.width;
  double get h => s.height;
  Offset get mid => s.center(Offset.zero);

  /// A smooth -1..1 swing that completes [times] cycles per loop.
  double wave({double times = 1, double phase = 0}) =>
      sin((t * times + phase) * pi * 2);

  /// Smoothstep progress of the loop between [a] and [b].
  double ease(double a, double b) {
    final v = ((t - a) / (b - a)).clamp(0.0, 1.0);
    return v * v * (3 - 2 * v);
  }

  void rrect(
    Rect r,
    Color color, {
    double radius = 8,
    Color? stroke,
    double width = 2,
  }) {
    final shape = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(
      shape,
      _paint
        ..style = PaintingStyle.fill
        ..color = color,
    );
    if (stroke != null) {
      c.drawRRect(
        shape,
        _paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = stroke,
      );
      _paint.style = PaintingStyle.fill;
    }
  }

  void circle(Offset at, double r, Color color, {double? stroke}) {
    _paint
      ..style = stroke == null ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = stroke ?? 1
      ..color = color;
    c.drawCircle(at, r, _paint);
    _paint.style = PaintingStyle.fill;
  }

  void line(Offset a, Offset b, Color color, {double width = 2}) {
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color;
    c.drawLine(a, b, _paint);
    _paint.style = PaintingStyle.fill;
  }

  void text(
    String value,
    Offset at, {
    double size = 18,
    Color color = JoyTheme.ink,
    FontWeight weight = FontWeight.w700,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(c, at - Offset(painter.width / 2, painter.height / 2));
  }

  /// A fingertip. With [tap] it pulses; otherwise it rests with a soft halo.
  void finger(Offset at, {bool tap = false}) {
    if (tap) {
      final k = (t * 2) % 1;
      circle(at, 10 + 16 * k, _amber.withValues(alpha: .5 * (1 - k)));
    } else {
      circle(at, 17, _amber.withValues(alpha: .25));
    }
    circle(at, 9, _amber);
    circle(at, 9, Colors.white.withValues(alpha: .6), stroke: 1.5);
  }

  /// A portrait court centered in the scene.
  Rect court([double widthFactor = .5, double maxWidth = 160]) =>
      Rect.fromCenter(
        center: mid,
        width: min(w * widthFactor, maxWidth),
        height: h - 20,
      );

  /// A board of [cols] x [rows] square-ish cells centered in the scene.
  Rect board(int cols, int rows, {double fill = .72}) {
    final size = min(w * fill / cols, (h - 28) / rows);
    return Rect.fromCenter(
      center: mid,
      width: size * cols,
      height: size * rows,
    );
  }

  void clipRRect(Rect r, double radius, void Function() body) {
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)));
    body();
    c.restore();
  }
}

Rect _cell(Rect a, int cols, int rows, int x, int y, [double gap = 4]) {
  final cw = (a.width - gap * (cols - 1)) / cols;
  final ch = (a.height - gap * (rows - 1)) / rows;
  return Rect.fromLTWH(a.left + x * (cw + gap), a.top + y * (ch + gap), cw, ch);
}

Offset _lerp(Offset a, Offset b, double k) => Offset.lerp(a, b, k)!;

// ---------------------------------------------------------------- action ---

void _rally(_Pen p) {
  final road = p.court(.5, 170);
  p.rrect(road, JoyTheme.background, radius: 18);
  p.clipRRect(road, 18, () {
    for (var i = 0; i < 5; i++) {
      final y = road.top + ((i * 50 + p.t * 50) % 250) - 20;
      p.rrect(
        Rect.fromLTWH(road.center.dx - 2, y, 4, 24),
        JoyTheme.border,
        radius: 2,
      );
    }
    final gold = Path()..moveTo(road.center.dx, road.bottom);
    for (var i = 1; i <= 20; i++) {
      final y = road.bottom - road.height * i / 20;
      gold.lineTo(road.center.dx + sin(i / 20 * pi * 2) * road.width * .14, y);
    }
    p.c.drawPath(
      gold,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _amber.withValues(alpha: .55),
    );
  });
  final trafficY = road.top + p.t * (road.height + 40) - 20;
  GameSprites.car(
    p.c,
    Offset(road.center.dx + road.width * .22, trafficY),
    17,
    _coral,
    reverse: true,
  );
  final carX = road.center.dx + p.wave() * road.width * .2;
  final carY = road.bottom - 48;
  GameSprites.car(p.c, Offset(carX, carY), 20, JoyTheme.accent);
  p.finger(Offset(carX, carY + 34));
}

void _auction(_Pen p) {
  p.text('💎  worth 3 gems', Offset(p.mid.dx, 36), size: 20);
  p.text(
    'Secret bid: 0 to 4 coins',
    Offset(p.mid.dx, 66),
    size: 13,
    color: JoyTheme.muted,
  );
  final active = (p.t * 5).floor().clamp(0, 4);
  final size = min(48.0, (p.w - 70) / 5);
  final start = p.mid.dx - (size * 5 + 8 * 4) / 2;
  for (var i = 0; i < 5; i++) {
    final r = Rect.fromLTWH(start + i * (size + 8), 100, size, size + 8);
    p.rrect(
      r,
      i == active ? JoyTheme.accent : JoyTheme.raised,
      radius: 12,
      stroke: i == active ? Colors.white54 : JoyTheme.border,
    );
    p.text('$i', r.center, size: 22);
  }
  p.text('🪙 12 coins', Offset(p.mid.dx, 176), size: 14, color: _amber);
  p.finger(Offset(start + active * (size + 8) + size / 2, 138), tap: true);
}

void _parking(_Pen p) {
  final lot = p.court(.62, 200);
  p.rrect(lot, JoyTheme.background, radius: 18);
  final target = 1;
  for (var i = 0; i < 3; i++) {
    final bay = Rect.fromLTWH(
      lot.left + 10 + i * (lot.width - 20) / 3,
      lot.top + 14,
      (lot.width - 20) / 3 - 6,
      62,
    );
    final lit = i == target;
    p.rrect(
      bay,
      lit ? _amber.withValues(alpha: .28) : Colors.transparent,
      radius: 6,
      stroke: lit ? _amber : JoyTheme.border,
    );
    if (lit) p.text('P', bay.center, size: 20, color: _amber);
  }
  final bay = Rect.fromLTWH(
    lot.left + 10 + target * (lot.width - 20) / 3,
    lot.top + 14,
    (lot.width - 20) / 3 - 6,
    62,
  );
  final start = Offset(lot.center.dx - 18, lot.bottom - 40);
  final k = p.ease(.1, .7);
  final pos = _lerp(start, bay.center, k);
  GameSprites.car(p.c, pos, 17, JoyTheme.accent);
  p.finger(pos + const Offset(0, 28));
}

void _traffic(_Pen p) {
  final cx = p.mid.dx, cy = p.mid.dy;
  p.rrect(
    Rect.fromCenter(center: p.mid, width: p.w - 40, height: 54),
    JoyTheme.background,
    radius: 6,
  );
  p.rrect(
    Rect.fromCenter(center: p.mid, width: 54, height: p.h - 20),
    JoyTheme.background,
    radius: 6,
  );
  final go = p.t < .5;
  p.circle(Offset(cx - 38, cy - 38), 7, go ? _green : _coral);
  p.circle(Offset(cx + 38, cy + 38), 7, go ? _coral : _green);
  final across = (p.t * 2) % 1;
  if (go) {
    GameSprites.car(
      p.c,
      Offset(20 + across * (p.w - 40), cy + 12),
      13,
      JoyTheme.accent,
    );
  } else {
    GameSprites.car(
      p.c,
      Offset(cx + 12, 16 + across * (p.h - 32)),
      13,
      _coral,
    );
  }
  final button = Rect.fromCenter(
    center: Offset(p.w - 56, p.h - 28),
    width: 78,
    height: 30,
  );
  p.rrect(button, JoyTheme.accent, radius: 15);
  p.text('SWITCH', button.center, size: 12);
  if ((p.t - .5).abs() < .2 || p.t > .9 || p.t < .1) {
    p.finger(button.center, tap: true);
  }
}

void _stack(_Pen p) {
  final cx = p.mid.dx;
  final blockW = min(110.0, p.w * .36);
  for (var i = 0; i < 4; i++) {
    p.rrect(
      Rect.fromCenter(
        center: Offset(cx + (i == 3 ? 6 : 0), p.h - 30 - i * 28),
        width: blockW,
        height: 24,
      ),
      Color.lerp(JoyTheme.accent, _amber, i / 4)!,
      radius: 5,
    );
  }
  final x = cx + p.wave() * p.w * .24;
  final moving = Rect.fromCenter(
    center: Offset(x, 34),
    width: blockW,
    height: 24,
  );
  p.rrect(moving, _coral, radius: 5);
  final aligned = (x - cx - 6).abs() < 10;
  if (aligned) {
    p.line(
      Offset(cx + 6, 52),
      Offset(cx + 6, p.h - 120),
      Colors.white24,
      width: 2,
    );
  }
  p.finger(Offset(p.w - 50, p.h - 40), tap: aligned);
}

void _pong(_Pen p) {
  final cr = p.court(.62, 200);
  p.rrect(cr, JoyTheme.background, radius: 18);
  p.line(
    Offset(cr.left + 8, cr.center.dy),
    Offset(cr.right - 8, cr.center.dy),
    JoyTheme.border,
  );
  final ballX = cr.center.dx + p.wave(times: 2) * cr.width * .36;
  final ballY = _lerp(
    Offset(0, cr.top + 38),
    Offset(0, cr.bottom - 38),
    (1 - (2 * ((p.t * 2) % 1) - 1).abs()),
  ).dy;
  final bottom = Offset(ballX.clamp(cr.left + 32, cr.right - 32), cr.bottom - 24);
  final topX = (cr.center.dx + p.wave(times: 2, phase: -.08) * cr.width * .34)
      .clamp(cr.left + 32, cr.right - 32);
  p.rrect(
    Rect.fromCenter(center: Offset(topX, cr.top + 24), width: 56, height: 10),
    _coral,
    radius: 6,
  );
  p.rrect(
    Rect.fromCenter(center: bottom, width: 56, height: 10),
    JoyTheme.accent,
    radius: 6,
  );
  GameSprites.ball(p.c, Offset(ballX, ballY), 7);
  p.finger(bottom + const Offset(0, 24));
}

void _hockey(_Pen p) {
  final cr = p.court(.62, 200);
  p.rrect(cr, JoyTheme.background, radius: 18, stroke: JoyTheme.border);
  p.line(
    Offset(cr.left, cr.center.dy),
    Offset(cr.right, cr.center.dy),
    JoyTheme.border,
  );
  p.circle(cr.center, 26, JoyTheme.border, stroke: 2);
  for (final y in [cr.top, cr.bottom]) {
    p.rrect(
      Rect.fromCenter(center: Offset(cr.center.dx, y), width: 44, height: 8),
      _amber,
      radius: 4,
    );
  }
  final puckStart = Offset(cr.center.dx + 6, cr.bottom - 80);
  final goal = Offset(cr.center.dx, cr.top + 14);
  final hit = p.ease(.3, .9);
  final puck = _lerp(puckStart, goal, hit);
  final striker = _lerp(
    Offset(cr.center.dx - 40, cr.bottom - 34),
    puckStart + const Offset(0, 22),
    p.ease(0, .3),
  );
  p.circle(Offset(cr.center.dx, cr.top + 46), 14, _coral);
  p.circle(striker, 15, JoyTheme.accent);
  p.circle(striker, 15, Colors.white54, stroke: 2);
  p.circle(puck, 8, Colors.white);
  p.finger(striker, tap: false);
}

void _penalty(_Pen p) {
  final cx = p.mid.dx;
  final goal = Rect.fromCenter(center: Offset(cx, 52), width: 150, height: 56);
  p.rrect(goal, Colors.white10, radius: 4, stroke: Colors.white70, width: 3);
  for (var i = 1; i < 6; i++) {
    p.line(
      Offset(goal.left + i * goal.width / 6, goal.top + 2),
      Offset(goal.left + i * goal.width / 6, goal.bottom - 2),
      Colors.white12,
      width: 1,
    );
  }
  final keeperX = cx + p.wave(times: 1) * 50;
  p.rrect(
    Rect.fromCenter(center: Offset(keeperX, goal.bottom - 14), width: 34, height: 22),
    JoyTheme.accent,
    radius: 8,
  );
  final ballStart = Offset(cx, p.h - 42);
  final aim = Offset(cx + 46, goal.center.dy + 4);
  final flick = p.ease(.3, .7);
  final ball = _lerp(ballStart, aim, flick);
  GameSprites.ball(p.c, ball, 11, football: true);
  final fingerPos = _lerp(
    ballStart + const Offset(0, 6),
    ballStart + const Offset(20, -60),
    p.ease(.1, .45),
  );
  if (p.t < .5) p.finger(fingerPos);
}

void _basket(_Pen p) {
  final cx = p.mid.dx;
  // The hoop slides slowly; the ball sweeps faster and is shot where the
  // hoop is going, not where it is.
  final hoopX = cx + sin(p.t * pi * 2 - 1) * p.w * .22;
  p.rrect(
    Rect.fromCenter(center: Offset(hoopX, 30), width: 90, height: 12),
    Colors.white12,
    radius: 6,
    stroke: Colors.white54,
  );
  p.rrect(
    Rect.fromCenter(center: Offset(hoopX, 48), width: 50, height: 12),
    const Color(0xFFFF8A3D),
    radius: 6,
  );
  final sweep = cx + p.wave(times: 2) * p.w * .3;
  final shot = p.ease(.5, .8);
  final target = Offset(cx + sin(.8 * pi * 2 - 1) * p.w * .22, 52);
  final pos =
      p.t < .5 || p.t > .85
          ? Offset(sweep, p.h - 46)
          : _lerp(Offset(cx + p.wave(times: 2, phase: .5 - .25) * p.w * .3, p.h - 46), target, shot);
  GameSprites.ball(p.c, pos, 14 + 6 * sin(pi * shot), basketball: true);
  if ((p.t - .5).abs() < .12) p.finger(Offset(pos.dx, p.h - 22), tap: true);
}

void _golf(_Pen p) {
  final green = Rect.fromCenter(
    center: p.mid,
    width: min(p.w - 60, 260),
    height: p.h - 30,
  );
  p.rrect(green, _turf, radius: 20, stroke: Colors.white24);
  final cup = Offset(green.right - 44, green.top + 36);
  p.circle(cup, 10, Colors.black87);
  final ball = Offset(green.left + 54, green.bottom - 40);
  final pull = p.ease(0, .4);
  final release = p.ease(.5, .9);
  final dir = (cup - ball) / (cup - ball).distance;
  final pos = _lerp(ball, cup, release);
  if (p.t < .5) {
    final back = ball - dir * (46 * pull);
    p.line(ball, ball + dir * (70 * pull), Colors.white70, width: 2);
    p.finger(back);
  }
  GameSprites.ball(p.c, p.t < .5 ? ball : pos, 8);
}

void _sumo(_Pen p) {
  final r = min(p.h * .4, p.w * .24);
  final ring = Offset(p.w * .3, p.mid.dy);
  p.circle(ring, r + 6, _amber.withValues(alpha: .85), stroke: 5);
  p.circle(ring, r, _clay);
  p.circle(ring, r * .55, Colors.white12, stroke: 1.5);
  final push = p.ease(.15, .85);
  final blue = ring + Offset(-r * .45 + push * r * .8, 0);
  final coral = ring + Offset(r * .25 + push * r * 1.2, 0);
  GameSprites.wrestler(p.c, coral, 17, _coral);
  GameSprites.wrestler(p.c, blue, 17, JoyTheme.accent);
  final bs = ((p.w - (ring.dx + r + 30)) / 4 - 4).clamp(24.0, 34.0);
  final startX = p.w - 18 - (bs + 4) * 4;
  const icons = ['←', '↑', '↓', '→'];
  for (var i = 0; i < 4; i++) {
    final r2 = Rect.fromLTWH(startX + i * (bs + 4), p.mid.dy - bs / 2, bs, bs);
    final active = i == 3 && p.t > .12 && p.t < .9;
    p.rrect(
      r2,
      active ? JoyTheme.accent : JoyTheme.accent.withValues(alpha: .16),
      radius: 10,
      stroke: JoyTheme.accent,
      width: 1.5,
    );
    p.text(icons[i], r2.center, size: 18);
    if (active) p.finger(r2.center);
  }
  p.text(
    'HOLD',
    Offset(startX + (bs + 4) * 2 - 2, p.mid.dy + bs / 2 + 18),
    size: 11,
    color: JoyTheme.muted,
  );
}

void _tank(_Pen p) {
  final cr = p.court(.62, 200);
  p.rrect(cr, JoyTheme.background, radius: 18);
  final enemy = Offset(cr.center.dx + p.wave(phase: .2) * 30, cr.top + 40);
  final me = Offset(cr.center.dx + p.wave() * 34, cr.bottom - 56);
  GameSprites.tank(p.c, enemy, 17, _coral, pi);
  GameSprites.tank(p.c, me, 17, JoyTheme.accent, 0);
  final fire = p.ease(.5, .85);
  if (p.t > .5 && p.t < .86) {
    p.circle(_lerp(me + const Offset(0, -24), enemy, fire), 4, _amber);
  }
  final button = Rect.fromCenter(
    center: Offset(cr.right + 44, p.h - 34),
    width: 64,
    height: 30,
  );
  p.rrect(button, _coral, radius: 15);
  p.text('FIRE', button.center, size: 12);
  if (p.t < .5) {
    p.finger(me + const Offset(-4, 34));
  } else {
    p.finger(button.center, tap: true);
  }
}

void _drawPad(_Pen p, Offset center, int active) {
  const icons = ['←', '↑', '↓', '→'];
  const size = 30.0;
  final startX = center.dx - (size * 4 + 4 * 3) / 2;
  for (var i = 0; i < 4; i++) {
    final r = Rect.fromLTWH(startX + i * (size + 4), center.dy, size, size);
    p.rrect(
      r,
      i == active ? JoyTheme.accent : JoyTheme.accent.withValues(alpha: .16),
      radius: 9,
      stroke: JoyTheme.accent,
      width: 1.5,
    );
    p.text(icons[i], r.center, size: 16);
    if (i == active) p.finger(r.center);
  }
}

void _snake(_Pen p) {
  final b = p.board(9, 5, fill: .8).shift(const Offset(0, -16));
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 9; x++) {
      p.rrect(
        _cell(b, 9, 5, x, y, 2),
        (x + y).isEven ? JoyTheme.background : JoyTheme.raised,
        radius: 3,
      );
    }
  }
  const path = [
    (1, 3),
    (2, 3),
    (3, 3),
    (4, 3),
    (5, 3),
    (5, 2),
    (5, 1),
    (6, 1),
    (7, 1),
  ];
  final head = ((p.t * path.length).floor()).clamp(0, path.length - 1);
  p.text('🍎', _cell(b, 9, 5, 8, 1, 2).center, size: 14);
  for (var k = 4; k >= 0; k--) {
    final i = head - k;
    if (i < 0) continue;
    final cell = _cell(b, 9, 5, path[i].$1, path[i].$2, 2);
    p.rrect(
      cell.deflate(1),
      k == 0 ? JoyTheme.accent : JoyTheme.accent.withValues(alpha: .75 - k * .1),
      radius: 5,
    );
  }
  final moveUp = head > 0 &&
      head < path.length &&
      path[head].$2 < path[max(head - 1, 0)].$2;
  final moveRight = !moveUp;
  _drawPad(p, Offset(p.mid.dx, b.bottom + 16), moveRight ? 3 : 1);
}

void _bomber(_Pen p) {
  final b = p.board(7, 5, fill: .78);
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 7; x++) {
      final wall = x.isOdd && y.isOdd;
      p.rrect(
        _cell(b, 7, 5, x, y, 2),
        wall ? JoyTheme.border : JoyTheme.background,
        radius: 4,
      );
    }
  }
  final bomb = _cell(b, 7, 5, 4, 2, 2).center;
  final away = p.ease(.1, .5);
  final me = _lerp(bomb, _cell(b, 7, 5, 2, 2, 2).center, away);
  final rival = _cell(b, 7, 5, 6, 2, 2).center;
  final blast = p.t > .75;
  if (blast) {
    final cell = _cell(b, 7, 5, 4, 2, 2);
    for (final r in [
      Rect.fromCenter(center: bomb, width: cell.width * 3, height: cell.height),
      Rect.fromCenter(center: bomb, width: cell.width, height: cell.height * 3),
    ]) {
      p.rrect(r, _amber.withValues(alpha: .55), radius: 6);
    }
  } else {
    GameSprites.bomb(p.c, bomb, 9, p.t * 3);
  }
  GameSprites.orb(p.c, rival, 8, _coral);
  GameSprites.orb(p.c, me, 8, JoyTheme.accent);
  p.finger(me + const Offset(0, 26));
}

// ---------------------------------------------------------------- arcade ---

void _runner(_Pen p) {
  final ground = p.h * .7;
  final gap = Rect.fromCenter(
    center: Offset(p.mid.dx + 16, ground + 26),
    width: 64,
    height: 52,
  );
  p.rrect(
    Rect.fromLTRB(16, ground, gap.left, p.h - 16),
    JoyTheme.raised,
    radius: 6,
  );
  p.rrect(
    Rect.fromLTRB(gap.right, ground, p.w - 16, p.h - 16),
    JoyTheme.raised,
    radius: 6,
  );
  final x = 40 + p.t * (p.w - 90);
  final jump = p.t > .3 && p.t < .62 ? sin((p.t - .3) / .32 * pi) * 58 : 0.0;
  GameSprites.orb(p.c, Offset(x, ground - 14 - jump), 13, JoyTheme.accent);
  if ((p.t - .3).abs() < .12) {
    p.finger(Offset(p.w - 50, p.h - 40), tap: true);
  }
}

void _sliding(_Pen p) {
  final b = p.board(3, 3, fill: .5);
  const tiles = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 0, 8],
  ];
  final move = p.ease(.35, .7);
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < 3; x++) {
      final value = tiles[y][x];
      if (value == 0) continue;
      var r = _cell(b, 3, 3, x, y, 6);
      if (value == 8) {
        r = Rect.lerp(r, _cell(b, 3, 3, 1, 2, 6), move)!;
      }
      p.rrect(r, value == 8 ? JoyTheme.accent : JoyTheme.raised, radius: 10);
      p.text('$value', r.center, size: 22);
    }
  }
  p.finger(_cell(b, 3, 3, 2, 2, 6).center, tap: p.t < .5);
}

void _reversi(_Pen p) {
  final b = p.board(4, 4, fill: .62);
  p.rrect(b.inflate(6), _turf, radius: 12);
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      p.rrect(
        _cell(b, 4, 4, x, y, 3),
        Colors.black.withValues(alpha: .18),
        radius: 4,
      );
    }
  }
  Offset at(int x, int y) => _cell(b, 4, 4, x, y, 3).center;
  final radius = b.width / 4 * .36;
  final flip = p.ease(.45, .65);
  p.circle(at(2, 1), radius, Colors.black87);
  p.circle(at(1, 2), radius, Colors.black87);
  p.circle(at(2, 2), radius, Colors.white);
  p.circle(at(1, 1), radius, Color.lerp(Colors.white, Colors.black87, flip)!);
  if (p.t < .4) {
    p.circle(at(0, 1), radius * .4, Colors.white54);
  } else {
    p.circle(at(0, 1), radius, Colors.black87);
  }
  p.finger(at(0, 1), tap: p.t < .45);
}

void _maze(_Pen p) {
  final b = p.board(6, 6, fill: .5);
  const open = {
    (0, 0), (1, 0), (1, 1), (1, 2), (2, 2), (3, 2), (3, 3), (3, 4),
    (4, 4), (5, 4), (5, 5), //
  };
  for (var y = 0; y < 6; y++) {
    for (var x = 0; x < 6; x++) {
      p.rrect(
        _cell(b, 6, 6, x, y, 2),
        open.contains((x, y)) ? JoyTheme.raised : JoyTheme.background,
        radius: 4,
      );
    }
  }
  final path = open.toList();
  final f = p.t * (path.length - 1);
  final i = f.floor().clamp(0, path.length - 2);
  final here = _lerp(
    _cell(b, 6, 6, path[i].$1, path[i].$2, 2).center,
    _cell(b, 6, 6, path[i + 1].$1, path[i + 1].$2, 2).center,
    f - i,
  );
  p.text('⭐', _cell(b, 6, 6, 5, 5, 2).center, size: 15);
  GameSprites.orb(p.c, here, b.width / 12, JoyTheme.accent);
  p.finger(_cell(b, 6, 6, path[min(i + 1, path.length - 1)].$1,
      path[min(i + 1, path.length - 1)].$2, 2).center, tap: true);
}

void _connect(_Pen p) {
  final b = p.board(7, 6, fill: .66);
  p.rrect(b.inflate(6), const Color(0xFF2A4FBF), radius: 12);
  const filled = {
    (3, 5): 0, (2, 5): 1, (3, 4): 1, (4, 5): 0, (1, 5): 1, //
  };
  for (var y = 0; y < 6; y++) {
    for (var x = 0; x < 7; x++) {
      final c = _cell(b, 7, 6, x, y, 3).center;
      final who = filled[(x, y)];
      p.circle(
        c,
        b.width / 7 * .38,
        who == null
            ? JoyTheme.background
            : (who == 0 ? _amber : _coral),
      );
    }
  }
  final drop = p.ease(.2, .7);
  final startY = b.top - 14;
  final endY = _cell(b, 7, 6, 3, 3, 3).center.dy;
  final x = _cell(b, 7, 6, 3, 3, 3).center.dx;
  p.circle(Offset(x, _lerp(Offset(0, startY), Offset(0, endY), drop).dy),
      b.width / 7 * .38, _amber);
  p.finger(Offset(x, b.top - 22), tap: p.t < .3);
}

void _tictactoe(_Pen p) {
  final b = p.board(3, 3, fill: .45);
  for (var i = 1; i < 3; i++) {
    p.line(
      Offset(b.left + i * b.width / 3, b.top),
      Offset(b.left + i * b.width / 3, b.bottom),
      JoyTheme.border,
      width: 3,
    );
    p.line(
      Offset(b.left, b.top + i * b.height / 3),
      Offset(b.right, b.top + i * b.height / 3),
      JoyTheme.border,
      width: 3,
    );
  }
  void cross(Offset c, double r, double k) {
    p.line(c - Offset(r, r) * k, c + Offset(r, r) * k, JoyTheme.accent, width: 5);
    p.line(
      c + Offset(r, -r) * k,
      c + Offset(-r, r) * k,
      JoyTheme.accent,
      width: 5,
    );
  }

  final cell = b.width / 3;
  cross(_cell(b, 3, 3, 0, 0, 0).center, cell * .24, 1);
  p.circle(_cell(b, 3, 3, 2, 0, 0).center, cell * .24, _coral, stroke: 5);
  p.circle(_cell(b, 3, 3, 0, 2, 0).center, cell * .24, _coral, stroke: 5);
  final k = p.ease(.4, .6);
  cross(_cell(b, 3, 3, 1, 1, 0).center, cell * .24, k);
  p.finger(_cell(b, 3, 3, 1, 1, 0).center, tap: p.t < .5);
}

// ----------------------------------------------------------- observation ---

void _pairs(_Pen p) {
  final b = p.board(3, 2, fill: .6);
  const faces = ['🍎', '🐟', '🍎', '🌟', '🐟', '🌟'];
  final reveal = [
    p.ease(.1, .25),
    p.ease(.4, .55),
  ];
  final matched = p.t > .7;
  for (var i = 0; i < 6; i++) {
    final r = _cell(b, 3, 2, i % 3, i ~/ 3, 8);
    final open = (i == 0 && reveal[0] > .5) ||
        (i == 2 && reveal[1] > .5) ||
        (matched && (i == 0 || i == 2));
    p.rrect(
      r,
      open ? JoyTheme.raised : JoyTheme.accent.withValues(alpha: .7),
      radius: 10,
      stroke: matched && open ? _green : null,
    );
    p.text(open ? faces[i] : '?', r.center, size: open ? 24 : 20);
  }
  final target = p.t < .35
      ? _cell(b, 3, 2, 0, 0, 8).center
      : _cell(b, 3, 2, 2, 0, 8).center;
  if (p.t < .7) p.finger(target, tap: true);
}

void _spot(_Pen p) {
  final colors = [JoyTheme.accent, _coral, _amber, _violet, _green];
  for (var side = 0; side < 2; side++) {
    final panel = Rect.fromCenter(
      center: Offset(p.w * (side == 0 ? .27 : .73), p.mid.dy),
      width: min(p.w * .4, 130.0),
      height: min(p.w * .4, 130.0),
    );
    p.rrect(panel, JoyTheme.background, radius: 12);
    for (var i = 0; i < 9; i++) {
      final cell = _cell(panel.deflate(8), 3, 3, i % 3, i ~/ 3, 6);
      final differs = side == 1 && i == 4;
      p.circle(
        cell.center,
        cell.width * .38,
        differs ? _violet : colors[i % 4],
      );
    }
    if (side == 1 && p.t > .45) {
      final c = _cell(panel.deflate(8), 3, 3, 1, 1, 6).center;
      p.circle(c, 20, _green, stroke: 3);
      p.finger(c, tap: true);
    }
  }
}

void _hidden(_Pen p) {
  p.text('Find: 🔑', Offset(p.mid.dx, 24), size: 18);
  final scene = Rect.fromLTWH(24, 44, p.w - 48, p.h - 64);
  p.rrect(scene, JoyTheme.background, radius: 16);
  const items = [
    ('🌲', .12, .3), ('🏠', .3, .62), ('🍄', .5, .25), ('🔑', .68, .6),
    ('🐞', .85, .3), ('⭐', .45, .78), //
  ];
  for (final item in items) {
    p.text(
      item.$1,
      Offset(scene.left + scene.width * item.$2, scene.top + scene.height * item.$3),
      size: 24,
    );
  }
  final key = Offset(scene.left + scene.width * .68, scene.top + scene.height * .6);
  final k = p.ease(.15, .55);
  final pos = _lerp(Offset(scene.left + 40, scene.bottom - 20), key, k);
  if (p.t > .55) p.circle(key, 22, _green, stroke: 3);
  p.finger(pos, tap: p.t > .5);
}

void _simon(_Pen p) {
  final colors = [JoyTheme.accent, _coral, _amber, _violet];
  final replay = p.t >= .5;
  final step = replay ? ((p.t - .5) * 8).floor() : (p.t * 8).floor();
  final lit = step % 4;
  p.text(
    replay ? 'Your turn' : 'Watch',
    Offset(p.mid.dx, 22),
    size: 14,
    color: JoyTheme.muted,
  );
  final b = Rect.fromCenter(center: p.mid + const Offset(0, 12), width: 160, height: 160);
  for (var i = 0; i < 4; i++) {
    final r = _cell(b, 2, 2, i % 2, i ~/ 2, 8);
    p.rrect(
      r,
      i == lit ? colors[i] : colors[i].withValues(alpha: .28),
      radius: 24,
    );
    if (replay && i == lit) p.finger(r.center, tap: true);
  }
}

void _cups(_Pen p) {
  final xs = [p.w * .25, p.w * .5, p.w * .75];
  final e1 = p.ease(.25, .5), e2 = p.ease(.5, .75);
  final a = p.t < .5 ? xs[0] + (xs[1] - xs[0]) * e1 : xs[1] + (xs[2] - xs[1]) * e2;
  final b = xs[1] + (xs[0] - xs[1]) * e1;
  final c = xs[2] + (xs[1] - xs[2]) * e2;
  final show = p.t < .15 || p.t > .85;
  final base = p.h * .66;
  void cup(double x, bool lifted, bool holder) {
    final lift = lifted ? -30.0 : 0.0;
    final path = Path()
      ..moveTo(x - 20, base + lift - 44)
      ..lineTo(x + 20, base + lift - 44)
      ..lineTo(x + 28, base + lift)
      ..lineTo(x - 28, base + lift)
      ..close();
    p.c.drawPath(path, Paint()..color = holder ? JoyTheme.accent : _violet);
  }

  p.text('💎', Offset(a, base - 12), size: 24);
  cup(a, show, true);
  cup(b, false, false);
  cup(c, false, false);
  if (p.t > .85) p.finger(Offset(a, base - 20), tap: true);
}

// ----------------------------------------------------------------- brain ---

void _riddle(_Pen p) {
  final card = Rect.fromLTWH(28, 20, p.w - 56, 58);
  p.rrect(card, JoyTheme.background, radius: 14);
  p.text('❓  What has keys but no locks?', card.center, size: 14);
  final active = (p.t * 4).floor().clamp(0, 3);
  const answers = ['A door', 'A piano', 'A map', 'A clock'];
  final area = Rect.fromLTWH(28, 96, p.w - 56, 100);
  for (var i = 0; i < 4; i++) {
    final r = _cell(area, 2, 2, i % 2, i ~/ 2, 8);
    p.rrect(
      r,
      i == active ? JoyTheme.accent : JoyTheme.raised,
      radius: 12,
    );
    p.text(answers[i], r.center, size: 13);
    if (i == active) p.finger(r.center + Offset(r.width * .3, 6), tap: true);
  }
}

void _math(_Pen p) {
  p.text('7 + 5 = ?', Offset(p.mid.dx, 52), size: 32);
  const answers = [10, 12, 14];
  final w = (p.w - 80) / 3;
  for (var i = 0; i < 3; i++) {
    final r = Rect.fromLTWH(28 + i * (w + 12), 110, w, 56);
    final correct = i == 1 && p.t > .45;
    p.rrect(
      r,
      correct ? _green : JoyTheme.raised,
      radius: 14,
    );
    p.text('${answers[i]}', r.center, size: 22);
  }
  if (p.t > .3) p.finger(Offset(28 + (w + 12) + w / 2, 150), tap: true);
}

void _reaction(_Pen p) {
  final go = p.t > .6;
  final top = Rect.fromLTWH(30, 14, p.w - 60, 60);
  final bottom = Rect.fromLTWH(30, p.h - 74, p.w - 60, 60);
  p.rrect(top, _coral.withValues(alpha: go ? 1 : .5), radius: 16);
  p.rrect(bottom, JoyTheme.accent.withValues(alpha: go ? 1 : .5), radius: 16);
  p.c.save();
  p.c.translate(top.center.dx, top.center.dy);
  p.c.rotate(pi);
  p.text('TAP', Offset.zero, size: 18);
  p.c.restore();
  p.text('TAP', bottom.center, size: 18);
  p.text(
    go ? 'NOW!' : 'WAIT…',
    p.mid,
    size: 28,
    color: go ? _green : _amber,
  );
  p.finger(bottom.center + const Offset(40, 0), tap: go);
}

void _scramble(_Pen p) {
  const word = 'GAMES';
  const bank = 'MGSAE';
  final filled = (p.t * 6).floor().clamp(0, 5);
  for (var i = 0; i < 5; i++) {
    final r = Rect.fromLTWH(p.mid.dx - 125 + i * 52, 36, 44, 50);
    p.rrect(
      r,
      i < filled ? JoyTheme.accent : JoyTheme.background,
      radius: 10,
      stroke: JoyTheme.border,
    );
    if (i < filled) p.text(word[i], r.center, size: 22);
  }
  final used = <int>{
    for (var i = 0; i < filled; i++) bank.indexOf(word[i]),
  };
  for (var i = 0; i < 5; i++) {
    final r = Rect.fromLTWH(p.mid.dx - 125 + i * 52, 120, 44, 50);
    p.rrect(
      r,
      used.contains(i) ? JoyTheme.background : JoyTheme.raised,
      radius: 10,
    );
    p.text(
      bank[i],
      r.center,
      size: 22,
      color: used.contains(i) ? JoyTheme.muted : JoyTheme.ink,
    );
  }
  if (filled < 5) {
    final next = bank.indexOf(word[filled]);
    p.finger(Offset(p.mid.dx - 125 + next * 52 + 22, 145), tap: true);
  }
}

void _rps(_Pen p) {
  const icons = ['✊', '✋', '✌️'];
  final active = (p.t * 3).floor().clamp(0, 2);
  for (var i = 0; i < 3; i++) {
    final r = Rect.fromCenter(
      center: Offset(p.w * (.2 + i * .3), p.mid.dy - 10),
      width: 68,
      height: 84,
    );
    p.rrect(
      r,
      i == active ? JoyTheme.accent : JoyTheme.raised,
      radius: 18,
    );
    p.text(icons[i], r.center, size: 34);
  }
  p.text(
    '✊ > ✌️ > ✋ > ✊',
    Offset(p.mid.dx, p.h - 30),
    size: 14,
    color: JoyTheme.muted,
  );
  p.finger(Offset(p.w * (.2 + active * .3), p.mid.dy + 40), tap: true);
}

void _crossword(_Pen p) {
  final b = p.board(6, 5, fill: .7).shift(const Offset(0, -10));
  const rows = [
    '#C#A##',
    'CROSS#',
    '#S#T##',
    '##PLAY',
    '######',
  ];
  final reveal = (p.t * 12).floor();
  var n = 0;
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 6; x++) {
      final ch = rows[y][x];
      final r = _cell(b, 6, 5, x, y, 2);
      if (ch == '#') {
        p.rrect(r, JoyTheme.background, radius: 3);
        continue;
      }
      final inRow = y == 1;
      p.rrect(
        r,
        inRow ? JoyTheme.accent.withValues(alpha: .4) : JoyTheme.raised,
        radius: 3,
      );
      if (n++ < reveal) p.text(ch, r.center, size: 14);
    }
  }
  for (var i = 0; i < 10; i++) {
    p.rrect(
      Rect.fromLTWH(p.mid.dx - 105 + i * 21, b.bottom + 16, 18, 22),
      JoyTheme.raised,
      radius: 4,
    );
  }
  p.finger(Offset(p.mid.dx - 105 + (reveal % 10) * 21 + 9, b.bottom + 27), tap: true);
}

void _wordSearch(_Pen p) {
  const rows = ['QWERTY', 'UIOPAS', 'BPLAYZ', 'XCVBNM', 'DFGHJK', 'ZXQWEA'];
  p.text('Find: PLAY', Offset(p.mid.dx, 18), size: 14, color: _amber);
  final b = p.board(6, 6, fill: .55).shift(const Offset(0, 10));
  final found = (p.t * 6).floor().clamp(0, 4);
  for (var y = 0; y < 6; y++) {
    for (var x = 0; x < 6; x++) {
      final r = _cell(b, 6, 6, x, y, 2);
      final hit = y == 2 && x >= 1 && x <= found;
      p.rrect(r, hit ? JoyTheme.accent : JoyTheme.raised, radius: 5);
      p.text(rows[y][x], r.center, size: 14);
    }
  }
  final end = _cell(b, 6, 6, found.clamp(1, 4), 2, 2).center;
  p.finger(end);
}

void _dots(_Pen p) {
  final d = min(p.w * .6 / 3, (p.h - 50) / 3);
  final origin = Offset(p.mid.dx - d * 1.5, p.mid.dy - d * 1.5);
  Offset dot(int x, int y) => origin + Offset(x * d, y * d);
  final box = p.ease(.4, .55);
  p.rrect(
    Rect.fromPoints(dot(0, 0), dot(1, 1)).deflate(3),
    JoyTheme.accent.withValues(alpha: .55 * box),
    radius: 4,
  );
  void edge(Offset a, Offset b, Color color) => p.line(a, b, color, width: 4);
  edge(dot(0, 0), dot(1, 0), JoyTheme.accent);
  edge(dot(0, 0), dot(0, 1), JoyTheme.accent);
  edge(dot(0, 1), dot(1, 1), JoyTheme.accent);
  edge(dot(2, 1), dot(2, 2), _coral);
  edge(dot(1, 2), dot(2, 2), _coral);
  final k = p.ease(.4, .5);
  if (p.t < .4) {
    p.line(dot(1, 0), dot(1, 1), Colors.white24, width: 4);
  } else {
    p.line(dot(1, 0), _lerp(dot(1, 0), dot(1, 1), k), JoyTheme.accent, width: 4);
  }
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      p.circle(dot(x, y), 5, JoyTheme.ink);
    }
  }
  p.finger(_lerp(dot(1, 0), dot(1, 1), .5), tap: p.t < .55);
}

void _battleship(_Pen p) {
  p.text('ENEMY WATERS', Offset(p.mid.dx, 16), size: 11, color: JoyTheme.muted);
  final b = p.board(5, 5, fill: .55).shift(const Offset(0, 8));
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      p.rrect(
        _cell(b, 5, 5, x, y, 3),
        const Color(0xFF173A6B),
        radius: 5,
      );
    }
  }
  p.text('•', _cell(b, 5, 5, 0, 1, 3).center, size: 22, color: Colors.white70);
  p.text('•', _cell(b, 5, 5, 4, 3, 3).center, size: 22, color: Colors.white70);
  p.text('✖', _cell(b, 5, 5, 2, 2, 3).center, size: 18, color: _coral);
  final target = _cell(b, 5, 5, 3, 2, 3);
  if (p.t > .45) {
    p.rrect(target, _coral.withValues(alpha: .35), radius: 5);
    p.text('✖', target.center, size: 18, color: _coral);
  }
  p.finger(target.center, tap: p.t < .5);
}

void _code(_Pen p) {
  final colors = [JoyTheme.accent, _coral, _amber, _violet, _green];
  final filled = (p.t * 5).floor().clamp(0, 4);
  for (var row = 0; row < 3; row++) {
    final y = 28.0 + row * 46;
    for (var i = 0; i < 4; i++) {
      final center = Offset(p.mid.dx - 60 + i * 38, y + 16);
      final done = row == 0 || (row == 1 && i < filled);
      p.circle(
        center,
        13,
        done ? colors[(i + row * 2) % 5] : JoyTheme.background,
      );
    }
    if (row == 0) {
      const pegs = [Colors.white, Colors.white, Colors.black54, Colors.black54];
      for (var k = 0; k < 4; k++) {
        p.circle(
          Offset(p.mid.dx + 112 + (k % 2) * 12, y + 8 + (k ~/ 2) * 12),
          4.5,
          pegs[k],
        );
      }
    }
  }
  for (var i = 0; i < 5; i++) {
    p.circle(Offset(p.mid.dx - 80 + i * 40, p.h - 28), 12, colors[i]);
  }
  p.finger(Offset(p.mid.dx - 80 + (filled % 5) * 40, p.h - 28), tap: true);
}

void _mines(_Pen p) {
  p.text('❤️ ❤️ ❤️', Offset(p.mid.dx, 16), size: 12);
  final b = p.board(5, 5, fill: .5).shift(const Offset(0, 10));
  const rows = ['11 1 ', '1▪1 1', '121  ', '▪    ', '     '];
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final ch = rows[y][x];
      final r = _cell(b, 5, 5, x, y, 3);
      final closed = ch == '▪';
      p.rrect(
        r,
        closed ? JoyTheme.accent.withValues(alpha: .65) : JoyTheme.background,
        radius: 5,
      );
      if (ch != ' ' && ch != '▪') {
        p.text(ch, r.center, size: 14, color: ch == '1' ? _amber : _coral);
      }
    }
  }
  p.text('🚩', _cell(b, 5, 5, 0, 3, 3).center, size: 14);
  final target = _cell(b, 5, 5, 1, 1, 3);
  if (p.t > .5) {
    p.rrect(target, JoyTheme.background, radius: 5);
    p.text('2', target.center, size: 14, color: _coral);
  }
  p.finger(target.center, tap: p.t < .55);
}
