import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One decoded atlas shared by every card. Each of the 30 tiles has its own
/// artwork; decoding a separate full-size image for every grid cell is avoided.
class GameArt extends StatelessWidget {
  final int id;
  final double size;
  const GameArt({super.key, required this.id, this.size = 100});
  static Future<ui.Image>? _image;
  static Future<ui.Image> _load() async {
    final data = await rootBundle.load('assets/art/game_atlas.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ExcludeSemantics(
      child: FutureBuilder<ui.Image>(
        future: _image ??= _load(),
        builder:
            (context, snapshot) =>
                snapshot.hasData
                    ? RepaintBoundary(
                      child: CustomPaint(
                        painter: _TilePainter(snapshot.data!, id),
                      ),
                    )
                    : const Center(
                      child: Icon(
                        Icons.sports_esports_rounded,
                        color: Color(0xFF709AFF),
                        size: 36,
                      ),
                    ),
      ),
    ),
  );
}

class _TilePainter extends CustomPainter {
  final ui.Image image;
  final int id;
  _TilePainter(this.image, this.id);
  @override
  void paint(Canvas canvas, Size size) {
    final w = image.width / 5, h = image.height / 6;
    // Inset half a pixel so linear filtering never bleeds adjacent artwork.
    final source = Rect.fromLTWH(
      id % 5 * w + .5,
      id ~/ 5 * h + .5,
      w - 1,
      h - 1,
    );
    final edge = min(size.width, size.height);
    final target = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: edge,
      height: edge,
    );
    canvas.drawImageRect(
      image,
      source,
      target,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _TilePainter oldDelegate) =>
      image != oldDelegate.image || id != oldDelegate.id;
}
