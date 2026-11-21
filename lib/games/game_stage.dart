import 'dart:math';

import 'package:flutter/material.dart';

export '../players.dart' show playerColors;
import '../catalog.dart';
import '../lobby_widgets.dart' show categoryColor;
import '../party_data.dart';
import '../players.dart';

class GameStage extends StatelessWidget {
  /// The game being played; gives the screen its category colour and the
  /// faint emblem behind the board. Optional so the stage can be used alone.
  final int? id;
  final List<String> names;
  final List<int> scores;
  final int turn;
  final String message;
  final Widget child;
  const GameStage({
    super.key,
    this.id,
    required this.names,
    required this.scores,
    required this.turn,
    required this.message,
    required this.child,
  });

  /// Width the games are laid out at before being scaled to fit.
  static const _layoutWidth = 540.0;

  /// Largest enlargement on wide screens (1.6 × 540 ≈ 864 logical pixels).
  static const _maxEnlarge = 1.6;
  @override
  Widget build(BuildContext context) {
    final report = MatchOptions.of(context)?.onScores;
    if (report != null) {
      final snapshot = List<int>.of(scores);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) report(snapshot);
      });
    }
    return _Backdrop(
      id: id,
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: LayoutBuilder(
            builder: (context, box) {
              final columns =
                  names.length > 2 && box.maxWidth < 520 ? 2 : names.length;
              final width = (box.maxWidth - (columns - 1) * 6) / columns;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var p = 0; p < names.length; p++)
                    SizedBox(
                      width: width,
                      child: Semantics(
                        label:
                            '${names[p]}, ${scores[p]} '
                            '${scores[p] == 1 ? 'point' : 'points'}'
                            '${turn == p ? ', your turn' : ''}',
                        excludeSemantics: true,
                        child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: playerColors[p].withValues(
                            alpha: turn == p ? .22 : .07,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                turn == p
                                    ? playerColors[p]
                                    : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                PartyData.instance.colorSymbols
                                    ? 'P${p + 1} ${names[p]}'
                                    : names[p],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.light
                                          ? const [
                                            Color(0xFF3659C8),
                                            Color(0xFFBF405B),
                                            Color(0xFF986000),
                                            Color(0xFF7350B5),
                                          ][p]
                                          : playerColors[p],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _ScoreNumber(
                              value: scores[p],
                              color: playerColors[p],
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth.clamp(0.0, _layoutWidth);
                // Measure the content once at a known width, then scale the
                // whole game into the remaining viewport. Phones only shrink
                // it; tablets may enlarge it up to _maxEnlarge so the board is
                // not a small island. Nothing here ever scrolls.
                final stageWidth = box.maxWidth.clamp(
                  0.0,
                  _layoutWidth * _maxEnlarge,
                );
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: stageWidth,
                    height: box.maxHeight,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      child: SizedBox(width: width, child: child),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
    );
  }
}

Widget boardGrid(
  int count,
  int columns,
  Widget Function(int) tile, {
  double spacing = 5,
}) => GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: count,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing,
  ),
  itemBuilder: (_, i) => tile(i),
);
Widget gameTile({
  required Widget child,
  VoidCallback? onTap,
  Color color = const Color(0xFF1C294A),
  bool selected = false,
}) => Material(
  color: color,
  borderRadius: BorderRadius.circular(10),
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? Colors.amber : Colors.white10,
          width: selected ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    ),
  ),
);

/// The score of one player. When it goes up the number swells and a "+N"
/// floats away, so every game gets scoring feedback without extra code.
class _ScoreNumber extends StatefulWidget {
  final int value;
  final Color color;
  const _ScoreNumber({required this.value, required this.color});
  @override
  State<_ScoreNumber> createState() => _ScoreNumberState();
}

class _ScoreNumberState extends State<_ScoreNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: 1,
  );
  int gained = 0;

  @override
  void didUpdateWidget(_ScoreNumber old) {
    super.didUpdateWidget(old);
    if (widget.value > old.value) {
      gained = widget.value - old.value;
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = still ? 1.0 : controller.value;
        final swell = 1 + .5 * sin(pi * t);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: swell,
              child: Text(
                '${widget.value}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (t < 1)
              Positioned(
                top: -18 * t - 6,
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Text(
                    '+$gained',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The tinted backdrop behind every board: a wash of the game category's
/// colour from the top, and the game's emblem as a faint watermark.
class _Backdrop extends StatelessWidget {
  final int? id;
  final Widget child;
  const _Backdrop({required this.id, required this.child});

  @override
  Widget build(BuildContext context) {
    final game = id == null ? null : games[id!];
    if (game == null) return child;
    final color = categoryColor(game.category);
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: .16),
                      color.withValues(alpha: .04),
                      Colors.transparent,
                    ],
                    stops: const [0, .45, 1],
                  ),
                ),
                child: Align(
                  alignment: const Alignment(1.15, .85),
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: .07,
                      child: Text(game.icon, style: const TextStyle(fontSize: 230)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
