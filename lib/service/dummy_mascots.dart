import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mascot_studio/service/dummy_png.dart';

enum DummyPose {
  sheet,
  hero,
  wave,
  celebrate,
  think,
  empty,
  error,
  present,
  peek,
  idle,
}

const _studioSweep = 0xFFF4EFE6;
const _ink = 0xFF24183A;
const _white = 0xFFFFFFFF;
const _grape = 0xFF6B4EFF;
const _butter = 0xFFFFD56A;
const _mint = 0xFF47C9A0;
const _apricot = 0xFFFFB27A;
const _cream = 0xFFFFF6EA;
const _sage = 0xFF9AA39A;

Uint8List paintDummyMascot({
  required String name,
  required DummyPose pose,
  int size = 512,
}) {
  if (pose == DummyPose.sheet) {
    return _paintSheet(name, size);
  }
  final canvas = PixelCanvas(size, size, fill: _studioSweep);
  _paintCharacter(
    canvas,
    name: name,
    pose: pose,
    cx: size * 0.5,
    cy: size * 0.56,
    scale: size / 360,
  );
  return canvas.toPng();
}

Uint8List _paintSheet(String name, int size) {
  const gutter = 8;
  final panel = ((size - gutter * 3) / 2).floor();
  final canvas = PixelCanvas(size, size, fill: 0xFFEDE6D8);
  const poses = [
    DummyPose.hero,
    DummyPose.wave,
    DummyPose.celebrate,
    DummyPose.think,
  ];
  for (var i = 0; i < 4; i++) {
    final cell = PixelCanvas(panel, panel, fill: _studioSweep);
    _paintCharacter(
      cell,
      name: name,
      pose: poses[i],
      cx: panel * 0.5,
      cy: panel * 0.56,
      scale: panel / 280,
    );
    final col = i % 2;
    final row = i ~/ 2;
    canvas.blit(
      cell,
      gutter + col * (panel + gutter),
      gutter + row * (panel + gutter),
    );
  }
  return canvas.toPng();
}

void _paintCharacter(
  PixelCanvas canvas, {
  required String name,
  required DummyPose pose,
  required double cx,
  required double cy,
  required double scale,
}) {
  switch (name) {
    case 'Nori':
      _nori(canvas, pose: pose, cx: cx, cy: cy, scale: scale);
    case 'Bolt':
      _bolt(canvas, pose: pose, cx: cx, cy: cy, scale: scale);
    case 'Pebble':
      _pebble(canvas, pose: pose, cx: cx, cy: cy, scale: scale);
    default:
      _pip(canvas, pose: pose, cx: cx, cy: cy, scale: scale);
  }
}

({double cx, double cy, _Arms arms}) _layout(
  DummyPose pose,
  double cx,
  double cy,
) {
  var x = cx;
  var y = cy;
  var arms = _Arms.rest;
  switch (pose) {
    case DummyPose.wave:
      arms = _Arms.waveRight;
    case DummyPose.celebrate:
      y -= 8;
      arms = _Arms.bothUp;
    case DummyPose.think:
      arms = _Arms.think;
    case DummyPose.empty:
      arms = _Arms.shrug;
    case DummyPose.error:
      arms = _Arms.worry;
    case DummyPose.present:
      arms = _Arms.presentRight;
    case DummyPose.peek:
      x += 42;
    case DummyPose.idle:
      y += 6;
    case DummyPose.hero:
    case DummyPose.sheet:
      break;
  }
  return (cx: x, cy: y, arms: arms);
}

void _pip(
  PixelCanvas c, {
  required DummyPose pose,
  required double cx,
  required double cy,
  required double scale,
}) {
  final layout = _layout(pose, cx, cy);
  final s = scale;
  _shadow(c, layout.cx, layout.cy + 78 * s, 58 * s, 16 * s);
  _sprout(c, layout.cx, layout.cy - 78 * s, s);
  c.fillCircle(layout.cx, layout.cy, 72 * s, _grape);
  _drawArms(c, layout.cx, layout.cy, s, _grape, layout.arms);
  _face(
    c,
    layout.cx,
    layout.cy - 6 * s,
    s,
    worried: pose == DummyPose.error,
    thinking: pose == DummyPose.think,
  );
  if (pose == DummyPose.celebrate) {
    _confetti(c, layout.cx, layout.cy - 90 * s, s);
  }
}

void _nori(
  PixelCanvas c, {
  required DummyPose pose,
  required double cx,
  required double cy,
  required double scale,
}) {
  final layout = _layout(pose, cx, cy);
  final s = scale;
  _shadow(c, layout.cx, layout.cy + 82 * s, 60 * s, 16 * s);
  c.fillEllipse(
    layout.cx - 32 * s,
    layout.cy - 78 * s,
    18 * s,
    28 * s,
    _apricot,
  );
  c.fillEllipse(
    layout.cx + 32 * s,
    layout.cy - 78 * s,
    18 * s,
    28 * s,
    _apricot,
  );
  c.fillCircle(layout.cx, layout.cy, 70 * s, _apricot);
  c.fillEllipse(layout.cx, layout.cy + 10 * s, 38 * s, 28 * s, _cream);
  c.fillEllipse(layout.cx, layout.cy + 46 * s, 42 * s, 16 * s, _grape);
  _drawArms(c, layout.cx, layout.cy + 8 * s, s, _apricot, layout.arms);
  _face(
    c,
    layout.cx,
    layout.cy - 8 * s,
    s,
    worried: pose == DummyPose.error,
    thinking: pose == DummyPose.think,
  );
  c.fillCircle(layout.cx, layout.cy + 8 * s, 6 * s, _ink);
  if (pose == DummyPose.celebrate) {
    _confetti(c, layout.cx, layout.cy - 96 * s, s);
  }
}

void _bolt(
  PixelCanvas c, {
  required DummyPose pose,
  required double cx,
  required double cy,
  required double scale,
}) {
  final layout = _layout(pose, cx, cy);
  final s = scale;
  _shadow(c, layout.cx, layout.cy + 80 * s, 62 * s, 16 * s);
  c.fillCircle(layout.cx, layout.cy - 92 * s, 10 * s, _butter);
  c.fillEllipse(layout.cx, layout.cy - 78 * s, 5 * s, 16 * s, _grape);
  c.fillRoundRect(
    layout.cx - 68 * s,
    layout.cy - 62 * s,
    136 * s,
    128 * s,
    42 * s,
    _cream,
  );
  c.fillRoundRect(
    layout.cx - 48 * s,
    layout.cy - 38 * s,
    96 * s,
    40 * s,
    16 * s,
    _grape,
  );
  _drawArms(c, layout.cx, layout.cy + 10 * s, s, _cream, layout.arms);
  _face(
    c,
    layout.cx,
    layout.cy - 18 * s,
    s * 0.86,
    onDark: true,
    worried: pose == DummyPose.error,
    thinking: pose == DummyPose.think,
  );
  if (pose == DummyPose.celebrate) {
    _confetti(c, layout.cx, layout.cy - 108 * s, s);
  }
}

void _pebble(
  PixelCanvas c, {
  required DummyPose pose,
  required double cx,
  required double cy,
  required double scale,
}) {
  final layout = _layout(pose, cx, cy);
  final s = scale;
  _shadow(c, layout.cx, layout.cy + 84 * s, 64 * s, 16 * s);
  c.fillEllipse(layout.cx, layout.cy, 78 * s, 70 * s, _sage);
  c.fillEllipse(layout.cx, layout.cy + 12 * s, 42 * s, 36 * s, _mint);
  c.fillCircle(layout.cx - 22 * s, layout.cy - 10 * s, 22 * s, _grape);
  c.fillCircle(layout.cx + 22 * s, layout.cy - 10 * s, 22 * s, _grape);
  _drawArms(c, layout.cx, layout.cy + 18 * s, s * 0.92, _sage, layout.arms);
  _face(
    c,
    layout.cx,
    layout.cy - 8 * s,
    s,
    worried: pose == DummyPose.error,
    thinking: pose == DummyPose.think,
  );
  c.fillEllipse(layout.cx, layout.cy + 14 * s, 10 * s, 7 * s, _butter);
  if (pose == DummyPose.celebrate) {
    _confetti(c, layout.cx, layout.cy - 96 * s, s);
  }
}

void _sprout(PixelCanvas c, double x, double y, double s) {
  c.fillEllipse(x, y, 8 * s, 22 * s, _mint);
  c.fillCircle(x, y - 20 * s, 14 * s, _butter);
}

void _shadow(PixelCanvas c, double x, double y, double rx, double ry) {
  c.fillEllipse(x, y, rx, ry, 0x3324183A);
}

void _confetti(PixelCanvas c, double x, double y, double s) {
  c.fillCircle(x - 48 * s, y + 8 * s, 6 * s, _butter);
  c.fillCircle(x + 52 * s, y + 2 * s, 5 * s, _mint);
  c.fillCircle(x - 10 * s, y - 18 * s, 5 * s, 0xFFFF7B62);
  c.fillCircle(x + 18 * s, y - 8 * s, 4 * s, _grape);
}

void _face(
  PixelCanvas c,
  double x,
  double y,
  double s, {
  bool onDark = false,
  bool worried = false,
  bool thinking = false,
}) {
  final eye = onDark ? _white : _ink;
  final shine = onDark ? 0xAAFFFFFF : _white;
  c.fillCircle(x - 18 * s, y, 10 * s, eye);
  c.fillCircle(x + 18 * s, y, 10 * s, eye);
  c.fillCircle(x - 15 * s, y - 3 * s, 3.4 * s, shine);
  c.fillCircle(x + 21 * s, y - 3 * s, 3.4 * s, shine);
  if (worried) {
    c.fillEllipse(x - 18 * s, y - 16 * s, 8 * s, 3 * s, eye);
    c.fillEllipse(x + 18 * s, y - 16 * s, 8 * s, 3 * s, eye);
    c.fillCircle(x + 40 * s, y + 8 * s, 4 * s, 0xFF8EC8FF);
  } else if (thinking) {
    c.fillEllipse(x + 6 * s, y + 18 * s, 10 * s, 4 * s, eye);
  } else {
    c.fillEllipse(x, y + 16 * s, 12 * s, 5 * s, eye);
  }
}

enum _Arms { rest, waveRight, bothUp, think, shrug, worry, presentRight }

void _drawArms(
  PixelCanvas c,
  double cx,
  double cy,
  double s,
  int color,
  _Arms arms,
) {
  switch (arms) {
    case _Arms.rest:
      c.fillCircle(cx - 70 * s, cy + 18 * s, 16 * s, color);
      c.fillCircle(cx + 70 * s, cy + 18 * s, 16 * s, color);
    case _Arms.waveRight:
      c.fillCircle(cx - 70 * s, cy + 18 * s, 16 * s, color);
      c.fillCircle(cx + 62 * s, cy - 56 * s, 17 * s, color);
    case _Arms.bothUp:
      c.fillCircle(cx - 58 * s, cy - 58 * s, 17 * s, color);
      c.fillCircle(cx + 58 * s, cy - 58 * s, 17 * s, color);
    case _Arms.think:
      c.fillCircle(cx - 70 * s, cy + 18 * s, 16 * s, color);
      c.fillCircle(cx + 42 * s, cy + 8 * s, 16 * s, color);
    case _Arms.shrug:
      c.fillCircle(cx - 86 * s, cy - 4 * s, 16 * s, color);
      c.fillCircle(cx + 86 * s, cy - 4 * s, 16 * s, color);
    case _Arms.worry:
      c.fillCircle(cx - 42 * s, cy + 28 * s, 16 * s, color);
      c.fillCircle(cx + 42 * s, cy + 28 * s, 16 * s, color);
    case _Arms.presentRight:
      c.fillCircle(cx - 70 * s, cy + 18 * s, 16 * s, color);
      c.fillCircle(cx + 92 * s, cy + 4 * s, 17 * s, color);
  }
}

class PixelCanvas {
  PixelCanvas(this.width, this.height, {int fill = 0xFFFFFFFF})
    : pixels = Uint8List(width * height * 4) {
    clear(fill);
  }

  final int width;
  final int height;
  final Uint8List pixels;

  void clear(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    final a = (argb >> 24) & 0xFF;
    for (var i = 0; i < pixels.length; i += 4) {
      pixels[i] = r;
      pixels[i + 1] = g;
      pixels[i + 2] = b;
      pixels[i + 3] = a;
    }
  }

  void fillCircle(double cx, double cy, double radius, int argb) {
    fillEllipse(cx, cy, radius, radius, argb);
  }

  void fillEllipse(double cx, double cy, double rx, double ry, int argb) {
    if (rx <= 0 || ry <= 0) return;
    final minX = math.max(0, (cx - rx - 1).floor());
    final maxX = math.min(width - 1, (cx + rx + 1).ceil());
    final minY = math.max(0, (cy - ry - 1).floor());
    final maxY = math.min(height - 1, (cy + ry + 1).ceil());
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final nx = (x + 0.5 - cx) / rx;
        final ny = (y + 0.5 - cy) / ry;
        final cover = (1.15 - math.sqrt(nx * nx + ny * ny)).clamp(0.0, 1.0);
        if (cover > 0) _blend(x, y, argb, cover);
      }
    }
  }

  void fillRoundRect(
    double left,
    double top,
    double w,
    double h,
    double radius,
    int argb,
  ) {
    final right = left + w;
    final bottom = top + h;
    final rad = math.min(radius, math.min(w, h) / 2);
    fillEllipse(left + rad, top + rad, rad, rad, argb);
    fillEllipse(right - rad, top + rad, rad, rad, argb);
    fillEllipse(left + rad, bottom - rad, rad, rad, argb);
    fillEllipse(right - rad, bottom - rad, rad, rad, argb);
    _fillRect(left + rad, top, right - rad, bottom, argb);
    _fillRect(left, top + rad, right, bottom - rad, argb);
  }

  void blit(PixelCanvas src, int dx, int dy) {
    for (var y = 0; y < src.height; y++) {
      final destY = dy + y;
      if (destY < 0 || destY >= height) continue;
      for (var x = 0; x < src.width; x++) {
        final destX = dx + x;
        if (destX < 0 || destX >= width) continue;
        final si = (y * src.width + x) * 4;
        final di = (destY * width + destX) * 4;
        pixels[di] = src.pixels[si];
        pixels[di + 1] = src.pixels[si + 1];
        pixels[di + 2] = src.pixels[si + 2];
        pixels[di + 3] = src.pixels[si + 3];
      }
    }
  }

  Uint8List toPng() {
    return encodeRgbaPng(width: width, height: height, rgba: pixels);
  }

  void _fillRect(
    double left,
    double top,
    double right,
    double bottom,
    int argb,
  ) {
    final minX = math.max(0, left.floor());
    final maxX = math.min(width - 1, right.ceil() - 1);
    final minY = math.max(0, top.floor());
    final maxY = math.min(height - 1, bottom.ceil() - 1);
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        _blend(x, y, argb, 1);
      }
    }
  }

  void _blend(int x, int y, int argb, double cover) {
    final srcA = ((argb >> 24) & 0xFF) / 255.0 * cover;
    if (srcA <= 0) return;
    final i = (y * width + x) * 4;
    final sr = (argb >> 16) & 0xFF;
    final sg = (argb >> 8) & 0xFF;
    final sb = argb & 0xFF;
    if (srcA >= 0.997) {
      pixels[i] = sr;
      pixels[i + 1] = sg;
      pixels[i + 2] = sb;
      pixels[i + 3] = 255;
      return;
    }
    final inv = 1 - srcA;
    pixels[i] = (pixels[i] * inv + sr * srcA).round();
    pixels[i + 1] = (pixels[i + 1] * inv + sg * srcA).round();
    pixels[i + 2] = (pixels[i + 2] * inv + sb * srcA).round();
    pixels[i + 3] = 255;
  }
}
