// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

void downloadBytes({
  required Uint8List bytes,
  required String filename,
  String mime = 'application/octet-stream',
}) {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
}

void downloadUrl(String url, {required String filename}) {
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
}

String createBlobUrl(Uint8List bytes, {required String mime}) {
  final blob = html.Blob([bytes], mime);
  return html.Url.createObjectUrlFromBlob(blob);
}

void revokeBlobUrl(String url) {
  html.Url.revokeObjectUrl(url);
}

final Map<int, _CachedBlob> _blobCache = {};

class _CachedBlob {
  _CachedBlob(this.url);
  final String url;
  var refs = 0;
}

String retainBlobUrl(Uint8List bytes, {required String mime}) {
  final key = identityHashCode(bytes);
  final cached = _blobCache.putIfAbsent(key, () {
    return _CachedBlob(
      html.Url.createObjectUrlFromBlob(html.Blob([bytes], mime)),
    );
  });
  cached.refs += 1;
  return cached.url;
}

void releaseBlobUrl(Uint8List bytes) {
  final key = identityHashCode(bytes);
  final cached = _blobCache[key];
  if (cached == null) return;
  cached.refs -= 1;
  if (cached.refs > 0) return;
  html.Url.revokeObjectUrl(cached.url);
  _blobCache.remove(key);
}
