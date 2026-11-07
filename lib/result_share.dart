import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'result_share_native.dart'
    if (dart.library.js_interop) 'result_share_web.dart'
    as platform;

Future<Uint8List> scorecardImage(
  String title,
  List<String> names,
  List<int> scores, {
  Map<int, String> awards = const {},
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final height = 310.0 + names.length * 100;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, 900, height),
    Paint()..color = const Color(0xFF0B1128),
  );
  canvas.drawCircle(
    const Offset(810, 20),
    240,
    Paint()..color = const Color(0xFF152A5B),
  );
  void label(
    String text,
    double x,
    double y,
    double size,
    Color color, {
    bool bold = false,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: 760);
    p.paint(canvas, Offset(x, y));
  }

  label('JOY', 54, 34, 44, const Color(0xFF91ACFF), bold: true);
  label(title, 54, 105, 32, Colors.white, bold: true);
  for (var i = 0; i < names.length; i++) {
    final y = 180.0 + i * 100;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(42, y, 816, 88),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFF182441),
    );
    label('${i + 1}. ${names[i]}', 64, y + 10, 25, Colors.white, bold: true);
    if (awards[i] != null) {
      label(awards[i]!, 64, y + 47, 17, const Color(0xFFB3C3EB));
    }
    label('${scores[i]}', 772, y + 20, 32, const Color(0xFFFFC16D), bold: true);
  }
  label(
    'One phone. Up to four friends. Instant fun. Offline.',
    54,
    height - 65,
    20,
    const Color(0xFFA2ADCA),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(900, height.toInt());
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<String> shareScorecard(
  String title,
  List<String> names,
  List<int> scores, {
  Map<int, String> awards = const {},
}) async {
  final text =
      'JOY • $title\n${[for (var i = 0; i < names.length; i++) '${names[i]}: ${scores[i]}${awards[i] != null ? ' • ${awards[i]}' : ''}'].join('\n')}\nOne phone. Up to four friends. Instant fun. Offline.';
  try {
    final bytes = await scorecardImage(title, names, scores, awards: awards);
    return await platform.shareImage(bytes, text);
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: text));
    return 'Results copied. Image sharing is unavailable on this device.';
  }
}
