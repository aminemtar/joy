import 'package:flutter/material.dart';

const playerColors = [Color(0xFF507CFF), Color(0xFFFF6F83)];

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            for (var p = 0; p < 2; p++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: EdgeInsets.only(
                    left: p == 1 ? 6 : 0,
                    right: p == 0 ? 6 : 0,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: playerColors[p].withValues(
                      alpha: turn == p ? .22 : .07,
                    ),
                    borderRadius: BorderRadius.circular(18),
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
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: child,
            ),
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
