import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<String> shareImage(Uint8List bytes, String text) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final link =
      web.HTMLAnchorElement()
        ..href = url
        ..download = 'joy-scorecard.png';
  web.document.body!.appendChild(link);
  link.click();
  link.remove();
  // Let the browser acquire the download before releasing its blob URL.
  Future<void>.delayed(
    const Duration(seconds: 30),
    () => web.URL.revokeObjectURL(url),
  );
  return 'Scorecard downloaded';
}
