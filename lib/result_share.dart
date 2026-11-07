import 'package:flutter/services.dart';
import 'result_share_native.dart'
    if (dart.library.js_interop) 'result_share_web.dart'
    as platform;

Future<String> shareResultsText(
  String title,
  List<String> names,
  List<int> scores, {
  Map<int, String> awards = const {},
}) async {
  final text =
      'JOY • $title\n${[for (var i = 0; i < names.length; i++) '${names[i]}: ${scores[i]}${awards[i] != null ? ' • ${awards[i]}' : ''}'].join('\n')}\nOne phone. Up to four friends. Instant fun. Offline.';
  try {
    return await platform.shareText(text);
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: text));
    return 'Results copied to clipboard';
  }
}
