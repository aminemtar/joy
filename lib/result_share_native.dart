import 'package:flutter/services.dart';

Future<String> shareImage(Uint8List bytes, String text) async {
  await const MethodChannel(
    'joy/share',
  ).invokeMethod<void>('scorecard', {'image': bytes, 'text': text});
  return 'Scorecard ready to share';
}
