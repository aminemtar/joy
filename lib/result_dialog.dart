import 'dart:math';

import 'package:flutter/material.dart';

import 'joy_theme.dart';
import 'players.dart';

/// One button at the bottom of [MatchResultDialog].
class ResultAction {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// The main next step. It is filled and always listed first.
  final bool primary;
  const ResultAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });
}

/// Dialog shown when a match ends: the winner, the players and next steps.
///
/// Every animation here is finite (so tests can settle) and is skipped when
/// the system or the in-app setting asks for reduced motion.
class MatchResultDialog extends StatelessWidget {
  final String gameName;
  final List<String> names;

  /// Index of the winning player, or a negative number for a draw.
  final int winner;
  final int seconds;
  final List<ResultAction> actions;

  /// Optional feedback line, for example the outcome of a share request.
  final String? status;
  const MatchResultDialog({
    super.key,
    required this.gameName,
    required this.names,
    required this.winner,
    required this.seconds,
    required this.actions,
    this.status,
  });

  bool get _draw => winner < 0 || winner >= names.length;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final celebrate = !_draw && !reduceMotion;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (celebrate)
          const Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(child: ConfettiBurst()),
            ),
          ),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration:
                reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            builder:
                (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.scale(scale: .92 + .08 * t, child: child),
                ),
            child: _card(context, reduceMotion),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, bool reduceMotion) {
    final tone =
        _draw
            ? JoyTheme.muted
            : playerColors[winner % playerColors.length];
    final ordered = [
      ...actions.where((a) => a.primary),
      ...actions.where((a) => !a.primary),
    ];
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration:
                    reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder:
                    (context, t, child) => Transform.scale(
                      scale: t,
                      child: child,
                    ),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone.withValues(alpha: .16),
                    border: Border.all(
                      color: tone.withValues(alpha: .55),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _draw
                        ? Icons.handshake_rounded
                        : Icons.emoji_events_rounded,
                    size: 40,
                    color: _draw ? JoyTheme.ink : const Color(0xFFFFC16D),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  _draw ? 'Match tied!' : '${names[winner]} wins!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: JoyTheme.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$gameName • ${seconds}s',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: JoyTheme.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ready for another rivalry?',
                textAlign: TextAlign.center,
                style: TextStyle(color: JoyTheme.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < names.length; i++)
                    _PlayerBadge(
                      name: names[i],
                      color: playerColors[i % playerColors.length],
                      winner: !_draw && winner == i,
                      dimmed: !_draw && winner != i,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _ActionGrid(actions: ordered),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.topCenter,
                child:
                    status == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              status!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: JoyTheme.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerBadge extends StatelessWidget {
  final String name;
  final Color color;
  final bool winner, dimmed;
  const _PlayerBadge({
    required this.name,
    required this.color,
    required this.winner,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial =
        trimmed.isEmpty
            ? '?'
            : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return Opacity(
      opacity: dimmed ? .6 : 1,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: winner ? 46 : 40,
                    height: winner ? 46 : 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color:
                            winner ? const Color(0xFFFFC16D) : Colors.white24,
                        width: winner ? 3 : 1,
                      ),
                    ),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: JoyTheme.background,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (winner)
                    const Positioned(
                      top: 0,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 20,
                        color: Color(0xFFFFC16D),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: JoyTheme.ink,
                fontSize: 13,
                fontWeight: winner ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays the buttons out two per row, or one per row when space is tight.
///
/// A last odd button spans the full row instead of leaving a gap, and labels
/// shrink slightly rather than wrapping or truncating.
class _ActionGrid extends StatelessWidget {
  final List<ResultAction> actions;
  const _ActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 250 && scale <= 1.3 ? 2 : 1;
        final rows = <Widget>[];
        for (var i = 0; i < actions.length; i += columns) {
          final slice = actions.skip(i).take(columns).toList();
          if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
          rows.add(
            Row(
              children: [
                for (var j = 0; j < slice.length; j++) ...[
                  if (j > 0) const SizedBox(width: 8),
                  Expanded(child: _button(slice[j])),
                ],
              ],
            ),
          );
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }

  Widget _button(ResultAction action) {
    const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 14);
    final label = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(action.label, maxLines: 1),
    );
    final icon = Icon(action.icon, size: 18);
    if (action.primary) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(padding: padding),
        onPressed: action.onPressed,
        icon: icon,
        label: label,
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(padding: padding),
      onPressed: action.onPressed,
      icon: icon,
      label: label,
    );
  }
}

class _Piece {
  final double x, delay, fall, sway, swayCycles, spin, width, height;
  final Color color;
  const _Piece({
    required this.x,
    required this.delay,
    required this.fall,
    required this.sway,
    required this.swayCycles,
    required this.spin,
    required this.width,
    required this.height,
    required this.color,
  });
}

/// A single burst of confetti that falls once and then stops animating.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFF507CFF),
    Color(0xFFFF6F83),
    Color(0xFFFFC16D),
    Color(0xFF39B8A6),
    Color(0xFFB69CFF),
  ];
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward();
  late final List<_Piece> _pieces = _makePieces();

  static List<_Piece> _makePieces() {
    final random = Random(7);
    return [
      for (var i = 0; i < 64; i++)
        _Piece(
          x: random.nextDouble(),
          delay: random.nextDouble() * .35,
          fall: 1.05 + random.nextDouble() * .4,
          sway: 8 + random.nextDouble() * 22,
          swayCycles: 1 + random.nextDouble() * 2,
          spin: 4 + random.nextDouble() * 10,
          width: 4 + random.nextDouble() * 4,
          height: 7 + random.nextDouble() * 7,
          color: _colors[i % _colors.length],
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ConfettiPainter(_pieces, _controller));
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final Animation<double> progress;
  _ConfettiPainter(this.pieces, this.progress) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final piece in pieces) {
      final span = (progress.value - piece.delay) / (1 - piece.delay);
      final local = span.clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final fade = local < .8 ? 1.0 : (1 - local) / .2;
      final sway = sin(local * pi * 2 * piece.swayCycles) * piece.sway;
      paint.color = piece.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(
        piece.x * size.width + sway,
        (local * piece.fall - .06) * size.height,
      );
      canvas.rotate(local * piece.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.width,
            height: piece.height,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces || oldDelegate.progress != progress;
}
