import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> shareText(String text) async {
  try {
    if (web.window.navigator.canShare(web.ShareData(text: text))) {
      await web.window.navigator.share(web.ShareData(text: text)).toDart;
      return 'Ready to share';
    }
  } catch (_) {
    // Fall back to clipboard when the browser share sheet is unavailable.
  }
  await web.window.navigator.clipboard.writeText(text).toDart;
  return 'Results copied to clipboard';
}
