import 'dart:math';
import 'package:flutter/material.dart';
import '../game_art.dart';

class FlipMatchCard extends StatefulWidget {
  final bool faceUp, matched, enabled;
  final int artId, index;
  final VoidCallback onTap;
  const FlipMatchCard({
    super.key,
    required this.faceUp,
    required this.matched,
    required this.enabled,
    required this.artId,
    required this.index,
    required this.onTap,
  });
  @override
  State<FlipMatchCard> createState() => _FlipMatchCardState();
}

class _FlipMatchCardState extends State<FlipMatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
      value: widget.faceUp ? 1 : 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.duration =
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 440);
  }

  @override
  void didUpdateWidget(covariant FlipMatchCard old) {
    super.didUpdateWidget(old);
    if (old.faceUp != widget.faceUp) {
      widget.faceUp ? controller.forward() : controller.reverse();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        'Card ${widget.index + 1}, ${widget.matched
            ? 'matched'
            : widget.faceUp
            ? 'revealed'
            : 'face down'}',
    enabled: widget.enabled,
    child: AnimatedScale(
      duration: const Duration(milliseconds: 250),
      scale: widget.matched ? .94 : 1,
      child: AnimatedBuilder(
        animation: controller,
        builder: (c, child) {
          final angle = Curves.easeInOutCubic.transform(controller.value) * pi,
              front = angle >= pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.identity()
                  ..setEntry(3, 2, .0018)
                  ..rotateY(angle),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(front ? pi : 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.matched
                              ? Colors.amber
                              : const Color(0xFF507CFF))
                          .withValues(alpha: widget.matched ? .2 : .12),
                      blurRadius: widget.matched ? 14 : 7,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.enabled ? widget.onTap : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              widget.matched
                                  ? Colors.amber
                                  : front
                                  ? const Color(0xFF7F9DE5)
                                  : const Color(0xFFCEBCFF),
                          width: widget.matched ? 2 : 1.3,
                        ),
                        gradient:
                            front
                                ? null
                                : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFB89BFF),
                                    Color(0xFF7555CF),
                                  ],
                                ),
                        color: front ? const Color(0xFF111C37) : null,
                      ),
                      child:
                          front
                              ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: GameArt(id: widget.artId, size: 100),
                                  ),
                                  if (widget.matched)
                                    const Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        size: 17,
                                        color: Colors.amber,
                                      ),
                                    ),
                                ],
                              )
                              : CustomPaint(painter: _CardBack()),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _CardBack extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p =
        Paint()
          ..color = Colors.white.withValues(alpha: .09)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    for (var d = -s.height; d < s.width + s.height; d += 13) {
      c.drawLine(Offset(d, 0), Offset(d + s.height, s.height), p);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & s).deflate(6),
        const Radius.circular(10),
      ),
      p..color = Colors.white.withValues(alpha: .22),
    );
    final cx = s.width / 2, cy = s.height / 2, r = min(s.width, s.height) * .22;
    final bolt =
        Path()
          ..moveTo(cx + r * .2, cy - r)
          ..lineTo(cx - r * .65, cy + r * .1)
          ..lineTo(cx - r * .05, cy + r * .1)
          ..lineTo(cx - r * .2, cy + r)
          ..lineTo(cx + r * .7, cy - r * .2)
          ..lineTo(cx + r * .05, cy - r * .2)
          ..close();
    c.drawShadow(bolt, Colors.black.withValues(alpha: .35), 3, false);
    c.drawPath(
      bolt,
      p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFE8EFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _CardBack old) => false;
}
