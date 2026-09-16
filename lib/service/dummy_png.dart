import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

bool looksLikePng(Uint8List bytes) {
  return bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
}

Uint8List encodeRgbaPng({
  required int width,
  required int height,
  required Uint8List rgba,
}) {
  if (rgba.length != width * height * 4) {
    throw ArgumentError('RGBA buffer does not match width x height.');
  }

  final raw = Uint8List(height * (1 + width * 4));
  var dest = 0;
  var src = 0;
  for (var y = 0; y < height; y++) {
    raw[dest++] = 0;
    raw.setRange(dest, dest + width * 4, rgba, src);
    dest += width * 4;
    src += width * 4;
  }

  final compressed = Uint8List.fromList(const ZLibEncoder().encode(raw));
  final out = BytesBuilder(copy: false);
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _pngChunk(out, 'IHDR', _ihdr(width, height));
  _pngChunk(out, 'IDAT', compressed);
  _pngChunk(out, 'IEND', Uint8List(0));
  return Uint8List.fromList(out.takeBytes());
}

Uint8List _ihdr(int width, int height) {
  final data = ByteData(13);
  data.setUint32(0, width);
  data.setUint32(4, height);
  data.setUint8(8, 8);
  data.setUint8(9, 6);
  data.setUint8(10, 0);
  data.setUint8(11, 0);
  data.setUint8(12, 0);
  return data.buffer.asUint8List();
}

void _pngChunk(BytesBuilder out, String type, Uint8List data) {
  final typeBytes = ascii.encode(type);
  final length = ByteData(4)..setUint32(0, data.length);
  out.add(length.buffer.asUint8List());
  out.add(typeBytes);
  out.add(data);
  final crcInput = Uint8List(typeBytes.length + data.length)
    ..setAll(0, typeBytes)
    ..setAll(typeBytes.length, data);
  final crc = ByteData(4)..setUint32(0, getCrc32(crcInput));
  out.add(crc.buffer.asUint8List());
}
