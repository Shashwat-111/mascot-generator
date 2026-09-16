import 'dart:typed_data';

void downloadBytes({
  required Uint8List bytes,
  required String filename,
  String mime = 'application/octet-stream',
}) {
  throw UnsupportedError('Downloads are only available on web.');
}

void downloadUrl(String url, {required String filename}) {
  throw UnsupportedError('Downloads are only available on web.');
}

String createBlobUrl(Uint8List bytes, {required String mime}) {
  throw UnsupportedError('Blob URLs are only available on web.');
}

void revokeBlobUrl(String url) {}

String retainBlobUrl(Uint8List bytes, {required String mime}) {
  throw UnsupportedError('Blob URLs are only available on web.');
}

void releaseBlobUrl(Uint8List bytes) {}
