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

/// The green felt of Reversi.
class ReversiFrame extends StatelessWidget {
  final Widget child;
  const ReversiFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF237A54), Color(0xFF165C3E)],
      ),
      border: Border.all(color: const Color(0xFF0D3B27), width: 3),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .4),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

/// One square of Reversi: a felt square, an optional hint ring showing where
/// the current player may play, and a disc that turns over when it changes.
class ReversiCell extends StatelessWidget {
  /// 0 empty, 1 or 2 a disc.
  final int owner;

  /// The player (1 or 2) whose turn it is, for the colour of the hint ring.
  final int turn;
  final bool legal;
  final VoidCallback onTap;
  const ReversiCell({
    super.key,
    required this.owner,
    required this.turn,
    required this.legal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .08),
        border: Border.all(color: Colors.black.withValues(alpha: .28)),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder:
              (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
          child:
              owner != 0
                  ? _Stone(key: ValueKey(owner), owner: owner)
                  : legal
                  ? Container(
                    key: const ValueKey('hint'),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: playerColors[turn - 1].withValues(alpha: .8),
                        width: 2,
                      ),
                    ),
                  )
                  : const SizedBox.shrink(key: ValueKey('none')),
        ),
      ),
    ),
  );
}

class _Stone extends StatelessWidget {
  final int owner;
  const _Stone({super.key, required this.owner});

  @override
  Widget build(BuildContext context) {
    final color = playerColors[owner - 1];
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.4, -.5),
          colors: [
            Color.lerp(color, Colors.white, .5)!,
            color,
            Color.lerp(color, Colors.black, .3)!,
          ],
          stops: const [0, .6, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .45),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// One square of the sea in Battleship Duel.
class SeaCell extends StatelessWidget {
  /// 0 not shot yet, 1 a miss (water), 2 a hit.
  final int state;
  final VoidCallback onTap;
  const SeaCell({super.key, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              state == 2
                  ? const [Color(0xFF5A2A3C), Color(0xFF3B1A28)]
                  : const [Color(0xFF1D4A7A), Color(0xFF12335A)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Center(
        child: switch (state) {
          1 => Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .7),
                width: 2,
              ),
            ),
          ),
          2 => const Text('💥', style: TextStyle(fontSize: 22)),
          _ => Icon(
            Icons.add_rounded,
            size: 16,
            color: Colors.white.withValues(alpha: .16),
          ),
        },
      ),
    ),
  );
}

/// One square of Minesweeper Duel: a raised tile that sinks when opened.
class MineCell extends StatelessWidget {
  final bool open, bomb, flag;

  /// Number of neighbouring mines, shown on an open safe square.
  final int clue;
  final VoidCallback onTap;
  const MineCell({
    super.key,
    required this.open,
    required this.bomb,
    required this.flag,
    required this.clue,
    required this.onTap,
  });

  static const _numberColors = [
    Colors.transparent,
    Color(0xFF6FD3FF),
    Color(0xFF4CD08A),
    Color(0xFFFF6F83),
    Color(0xFFA08AFF),
    Color(0xFFFFC16D),
    Color(0xFFFF9EDB),
    Colors.white,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient:
            open
                ? null
                : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3A5088), Color(0xFF26396A)],
                ),
        color:
            open
                ? (bomb
                    ? const Color(0xFF7A2D2D)
                    : Colors.black.withValues(alpha: .28))
                : null,
        boxShadow:
            open
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .4),
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
      ),
      child: Center(
        child:
            open
                ? (bomb
                    ? const Text('💣', style: TextStyle(fontSize: 22))
                    : clue == 0
                    ? null
                    : Text(
                      '$clue',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _numberColors[clue],
                      ),
                    ))
                : flag
                ? const Text('🚩', style: TextStyle(fontSize: 20))
                : null,
      ),
    ),
  );
}

/// A gold coin button used to choose a bid in Treasure Auction.
class CoinButton extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;
  const CoinButton({
    super.key,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$value ${value == 1 ? 'coin' : 'coins'}',
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.15 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-.3, -.4),
              colors: [Color(0xFFFFE08A), Color(0xFFE2A93A), Color(0xFFB07A1E)],
              stops: [0, .6, 1],
            ),
            border: Border.all(
              color: selected ? Colors.white : const Color(0xFF8A5E16),
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC16D).withValues(
                  alpha: selected ? .6 : .15,
                ),
                blurRadius: selected ? 14 : 4,
              ),
            ],
          ),
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5A3A08),
            ),
          ),
        ),
      ),
    ),
  );
}
