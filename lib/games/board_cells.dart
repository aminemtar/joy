import 'dart:math';

import 'package:flutter/material.dart';

import '../players.dart';

/// The cell widgets of the tap-a-square board games, so Connect Four, Tic Tac
/// Toe, the Sliding Puzzle and the Maze each look like their real-world
/// counterpart instead of a flat coloured square.

/// The blue plastic frame of Connect Four.
class ConnectFrame extends StatelessWidget {
  final Widget child;
  const ConnectFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D56C9), Color(0xFF1B3482)],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .45),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
}

/// One hole of Connect Four: empty, or filled by a glossy disc that drops in.
class DiscCell extends StatelessWidget {
  /// 0 empty, 1 first player, 2 second player.
  final int owner;

  /// Draws a triangle or square on the disc as well, for players who cannot
  /// tell the two colours apart.
  final bool symbols;
  final VoidCallback onTap;
  const DiscCell({
    super.key,
    required this.owner,
    required this.symbols,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(0, .5),
                colors: [Color(0xFF0B1636), Color(0xFF14224F)],
              ),
              border: Border.all(color: Colors.black.withValues(alpha: .35)),
            ),
          ),
          if (owner != 0)
            TweenAnimationBuilder<double>(
              key: ValueKey(owner),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.bounceOut,
              builder:
                  (context, t, child) => FractionalTranslation(
                    translation: Offset(0, -(1 - t) * 3.2),
                    child: child,
                  ),
              child: _Disc(owner: owner, symbols: symbols),
            ),
        ],
      ),
    ),
  );
}

class _Disc extends StatelessWidget {
  final int owner;
  final bool symbols;
  const _Disc({required this.owner, required this.symbols});

  @override
  Widget build(BuildContext context) {
    final color = playerColors[owner - 1];
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.35, -.4),
          colors: [
            Color.lerp(color, Colors.white, .45)!,
            color,
            Color.lerp(color, Colors.black, .35)!,
          ],
          stops: const [0, .55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .5),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: .16),
              width: 2,
            ),
          ),
          child:
              symbols
                  ? Center(
                    child: Text(
                      owner == 1 ? '▲' : '■',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  )
                  : null,
        ),
      ),
    );
  }
}

/// One square of Tic Tac Toe. The mark is drawn with a short pen stroke.
class MarkCell extends StatelessWidget {
  final int owner;
  final VoidCallback onTap;
  const MarkCell({super.key, required this.owner, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2C57), Color(0xFF14224A)],
        ),
        border: Border.all(
          color:
              owner == 0
                  ? Colors.white.withValues(alpha: .08)
                  : playerColors[owner - 1].withValues(alpha: .5),
        ),
      ),
      child:
          owner == 0
              ? null
              : TweenAnimationBuilder<double>(
                key: ValueKey(owner),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                builder:
                    (context, t, _) => CustomPaint(
                      painter: _MarkPainter(owner, t),
                    ),
              ),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  final int owner;
  final double progress;
  _MarkPainter(this.owner, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final color = playerColors[owner - 1];
    final pen =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = size.shortestSide * .12
          ..color = color;
    final glow =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = size.shortestSide * .2
          ..color = color.withValues(alpha: .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final c = size.center(Offset.zero), r = size.shortestSide * .28;
    if (owner == 1) {
      // Two strokes, the second one starts when the first is half done.
      final a = (progress * 2).clamp(0.0, 1.0);
      final b = (progress * 2 - 1).clamp(0.0, 1.0);
      final p1 = Offset.lerp(c + Offset(-r, -r), c + Offset(r, r), a)!;
      final p2 = Offset.lerp(c + Offset(r, -r), c + Offset(-r, r), b)!;
      for (final paint in [glow, pen]) {
        canvas.drawLine(c + Offset(-r, -r), p1, paint);
        if (b > 0) canvas.drawLine(c + Offset(r, -r), p2, paint);
      }
    } else {
      for (final paint in [glow, pen]) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 1.05),
          -pi / 2,
          2 * pi * progress,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) =>
      old.progress != progress || old.owner != owner;
}

/// A tile of the Sliding Puzzle. Tiles that already sit in their place glow.
class TileCell extends StatelessWidget {
  /// 1 to 15, or 0 for the empty space.
  final int number;
  final bool inPlace;
  final VoidCallback onTap;
  const TileCell({
    super.key,
    required this.number,
    required this.inPlace,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (number == 0) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: .25),
          border: Border.all(color: Colors.white.withValues(alpha: .05)),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
        ),
      );
    }
    final base = inPlace ? const Color(0xFF3FBF86) : const Color(0xFF507CFF);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(base, Colors.white, .22)!, base],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .35),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black38, blurRadius: 3)],
            ),
          ),
        ),
      ),
    );
  }
}

/// One square of the Maze Race: a stone wall, a floor tile, a runner or the
/// finish flag.
class MazeCell extends StatelessWidget {
  final bool wall, goal;

  /// 0 nobody, 1 first runner, 2 second runner.
  final int runner;
  final VoidCallback onTap;
  const MazeCell({
    super.key,
    required this.wall,
    required this.goal,
    required this.runner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(wall ? 6 : 12),
        gradient:
            wall
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A3350), Color(0xFF111833)],
                )
                : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF22335F), Color(0xFF1A294F)],
                ),
        border: Border.all(
          color: Colors.white.withValues(alpha: wall ? .14 : .06),
        ),
      ),
      child: Center(
        child:
            runner != 0
                ? DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-.3, -.35),
                      colors: [
                        Color.lerp(playerColors[runner - 1], Colors.white, .5)!,
                        playerColors[runner - 1],
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: playerColors[runner - 1].withValues(alpha: .7),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const SizedBox.square(dimension: 22),
                )
                : goal
                ? const Text('🏁', style: TextStyle(fontSize: 22))
                : null,
      ),
    ),
  );
}
