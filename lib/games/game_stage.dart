import 'package:flutter/material.dart';

export '../players.dart' show playerColors;
import '../players.dart';

class GameStage extends StatelessWidget {
  final List<String> names;
  final List<int> scores;
  final int turn;
  final String message;
  final Widget child;
  const GameStage({
    super.key,
    required this.names,
    required this.scores,
    required this.turn,
    required this.message,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Column(
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
                          color: turn == p ? playerColors[p] : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              names[p],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: playerColors[p],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${scores[p]}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
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
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth.clamp(0.0, 540.0);
              // Measure the content once at a known width, then scale the whole game
              // into the remaining viewport. The canvas and its controls never scroll.
              return SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(width: width, child: child),
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
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
