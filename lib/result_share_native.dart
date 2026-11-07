import 'package:flutter/services.dart';

Future<String> shareText(String text) async {
  await const MethodChannel('joy/share').invokeMethod<void>('text', {
    'text': text,
  });
  return 'Ready to share';
}
