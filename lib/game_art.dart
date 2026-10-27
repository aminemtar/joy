import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared decoded illustration atlases. Each game has appropriate
/// artwork; decoding a separate full-size image for every grid cell is avoided.
class GameArt extends StatelessWidget {
  final int id;
  final double size;
  const GameArt({super.key, required this.id, this.size = 100});
  static final _images = <bool, Future<ui.Image>>{};
  static Future<ui.Image> _load(bool extra) async {
    final data = await rootBundle.load(
      extra ? 'assets/art/strategy_atlas.png' : 'assets/art/game_atlas.png',
    );
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final extraIndex =
        id == 1
            ? 0
            : id == 16
            ? 1
            : id >= 30
            ? id - 28
            : null;
    final extra = extraIndex != null;
    final index = extraIndex ?? (id == 4 ? 16 : id);
    return SizedBox.square(
      dimension: size,
      child: ExcludeSemantics(
        child: FutureBuilder<ui.Image>(
          future: _images.putIfAbsent(extra, () => _load(extra)),
          builder:
              (context, snapshot) =>
                  snapshot.hasData
                      ? RepaintBoundary(
                        child: CustomPaint(
                          painter: _TilePainter(
                            snapshot.data!,
                            index,
                            extra ? 4 : 5,
                            extra ? 2 : 6,
                          ),
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
}

class _TilePainter extends CustomPainter {
  final ui.Image image;
  final int id, columns, rows;
  _TilePainter(this.image, this.id, this.columns, this.rows);
  @override
  void paint(Canvas canvas, Size size) {
    final w = image.width / columns, h = image.height / rows;
    // Inset half a pixel so linear filtering never bleeds adjacent artwork.
    final source = Rect.fromLTWH(
      id % columns * w + .5,
      id ~/ columns * h + .5,
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
