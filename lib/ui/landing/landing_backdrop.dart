import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mascot_studio/ui/theme.dart';
import 'package:mascot_studio/ui/widgets/pip_mascot.dart';

class LandingBackdrop extends StatelessWidget {
  const LandingBackdrop({super.key, this.quiet = false});

  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: StudioColors.canvas),
          CustomPaint(painter: _PaperGrainPainter()),
          if (!quiet) const CustomPaint(painter: _StickerBlobPainter()),
          if (!quiet) const _StickerPips(),
        ],
      ),
    );
  }
}

class _StickerPips extends StatelessWidget {
  const _StickerPips();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            Positioned(
              left: w * 0.72,
              top: h * 0.08,
              child: Transform.rotate(
                angle: 0.18,
                child: Opacity(
                  opacity: 0.28,
                  child: PipMascotFigure(size: math.min(92, w * 0.12)),
                ),
              ),
            ),
            Positioned(
              left: w * 0.04,
              bottom: h * 0.08,
              child: Transform.rotate(
                angle: -0.22,
                child: Opacity(
                  opacity: 0.22,
                  child: PipMascotFigure(size: math.min(74, w * 0.1)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StickerBlobPainter extends CustomPainter {
  const _StickerBlobPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset c, double r, Color color, [double rot = 0]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r),
          Radius.circular(r * 0.42),
        ),
        Paint()..color = color,
      );
      canvas.restore();
    }

    blob(
      Offset(size.width * 0.12, size.height * 0.22),
      size.shortestSide * 0.11,
      StudioColors.coral.withValues(alpha: 0.16),
      -0.4,
    );
    blob(
      Offset(size.width * 0.88, size.height * 0.18),
      size.shortestSide * 0.09,
      StudioColors.butter.withValues(alpha: 0.28),
      0.35,
    );
    blob(
      Offset(size.width * 0.82, size.height * 0.78),
      size.shortestSide * 0.13,
      StudioColors.mint.withValues(alpha: 0.14),
      0.2,
    );
    blob(
      Offset(size.width * 0.08, size.height * 0.72),
      size.shortestSide * 0.08,
      StudioColors.lavender.withValues(alpha: 0.22),
      -0.15,
    );
    blob(
      Offset(size.width * 0.48, size.height * 0.06),
      size.shortestSide * 0.055,
      StudioColors.cobalt.withValues(alpha: 0.1),
      0.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaperGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(11);
    final paint = Paint()..color = const Color(0x1A171717);
    final count = (size.width * size.height / 3200).clamp(60, 180).toInt();
    for (var i = 0; i < count; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
          1.1,
          1.1,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
