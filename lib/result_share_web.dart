import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> shareText(String text) async {
  try {
    await web.window.navigator.share(web.ShareData(text: text)).toDart;
    return 'Ready to share';
  } catch (_) {
    await web.window.navigator.clipboard.writeText(text).toDart;
    return 'Results copied to clipboard';
  }
}
