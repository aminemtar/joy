import 'package:flutter/material.dart';

export '../players.dart' show playerColors;
import '../players.dart';
import '../party_data.dart';
import '../joy_theme.dart';

class GameStage extends StatelessWidget {
  final List<String> names;
  final List<int> scores;
  final int turn;
  final String message;
  final Widget child;
  const GameStage({super.key, required this.names, required this.scores, required this.turn, required this.message, required this.child});

  @override
  Widget build(BuildContext context) {
    final report = MatchOptions.of(context)?.onScores;
    if (report != null) {
      final snapshot = List<int>.of(scores);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) report(snapshot);
      });
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
        child: LayoutBuilder(builder: (context, box) {
          final columns = names.length > 2 && box.maxWidth < 520 ? 2 : names.length;
          final width = (box.maxWidth - (columns - 1) * 7) / columns;
          return Wrap(spacing: 7, runSpacing: 7, children: [
            for (var p = 0; p < names.length; p++)
              SizedBox(width: width, child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  gradient: turn == p
                    ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
                        playerColors[p].withValues(alpha: .17),
                        Colors.white,
                      ])
                    : const LinearGradient(colors: [Colors.white, Color(0xFFF5F9FF)]),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: turn == p ? playerColors[p] : JoyTheme.border, width: turn == p ? 1.7 : 1),
                  boxShadow: [
                    BoxShadow(color: playerColors[p].withValues(alpha: turn == p ? .13 : .04), blurRadius: turn == p ? 10 : 5, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(children: [
                  Expanded(child: Text(
                    PartyData.instance.colorSymbols ? 'P${p + 1} ${names[p]}' : names[p],
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: const [Color(0xFF2457B5), Color(0xFFB83D5A), Color(0xFF956000), Color(0xFF7050B4)][p], fontWeight: FontWeight.w800, fontSize: 12),
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                    child: Text('${scores[p]}', style: const TextStyle(color: JoyTheme.ink, fontSize: 17, fontWeight: FontWeight.w900)),
                  ),
                ]),
              )),
          ]);
        }),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F0FF),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFBBD9F8)),
          ),
          child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF315B86), fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ),
      Expanded(child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: LayoutBuilder(builder: (context, box) {
          final width = box.maxWidth.clamp(0.0, 540.0);
          return SizedBox.expand(child: FittedBox(
            fit: BoxFit.scaleDown, alignment: Alignment.topCenter,
            child: SizedBox(width: width, child: child),
          ));
        }),
      )),
    ]);
  }
}

Widget boardGrid(int count, int columns, Widget Function(int) tile, {double spacing = 5}) => GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: count,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: spacing, mainAxisSpacing: spacing),
  itemBuilder: (_, i) => tile(i),
);

Widget gameTile({
  required Widget child,
  VoidCallback? onTap,
  Color color = const Color(0xFFE5F1FF),
  bool selected = false,
}) => Material(
  color: color,
  elevation: selected ? 4 : 1,
  shadowColor: const Color(0x220B4F8A),
  borderRadius: BorderRadius.circular(10),
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? const Color(0xFF087BFF) : const Color(0xFFC5DCF4), width: selected ? 2.2 : 1),
        gradient: selected ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD8ECFF), Color(0xFFBBDFFF)]) : null,
      ),
      alignment: Alignment.center,
      child: child,
    ),
  ),
);
