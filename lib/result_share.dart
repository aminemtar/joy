import 'package:flutter/services.dart';

Future<String> shareResultsText(
  String title,
  List<String> names,
  List<int> scores, {
  Map<int, String> awards = const {},
}) async {
  final text =
      'JOY • $title\n${[for (var i = 0; i < names.length; i++) '${names[i]}: ${scores[i]}${awards[i] != null ? ' • ${awards[i]}' : ''}'].join('\n')}\nOne phone. Up to four friends. Instant fun. Offline.';
  try {
    await const MethodChannel('joy/share').invokeMethod<void>('text', {
      'text': text,
    });
    return 'Ready to share';
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: text));
    return 'Results copied to clipboard';
  }
}
