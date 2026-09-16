import 'package:flutter/material.dart';
import 'package:mascot_studio/ui/theme.dart';

class PipMascot extends StatefulWidget {
  const PipMascot({super.key, this.size = 160, this.animate = true});

  final double size;
  final bool animate;

  @override
  State<PipMascot> createState() => _PipMascotState();
}

class _PipMascotState extends State<PipMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final figure = PipMascotFigure(size: widget.size);
    if (!widget.animate || reduce) {
      return figure;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Transform.translate(
          offset: Offset(0, -6 * (t - 0.5) * 2),
          child: child,
        );
      },
      child: figure,
    );
  }
}

class PipMascotFigure extends StatelessWidget {
  const PipMascotFigure({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: const _PipPainter());
  }
}

class _PipPainter extends CustomPainter {
  const _PipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.56),
      width: size.width * 0.72,
      height: size.height * 0.62,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(size.width * 0.28)),
      Paint()..color = StudioColors.cobalt,
    );

    final cheekPaint = Paint()..color = StudioColors.coral;
    canvas.drawCircle(
      Offset(body.left + body.width * 0.22, body.top + body.height * 0.55),
      size.width * 0.07,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(body.right - body.width * 0.22, body.top + body.height * 0.55),
      size.width * 0.07,
      cheekPaint,
    );

    final eyePaint = Paint()..color = StudioColors.paper;
    final pupil = Paint()..color = StudioColors.ink;
    canvas.drawCircle(
      Offset(body.left + body.width * 0.34, body.top + body.height * 0.38),
      size.width * 0.08,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(body.right - body.width * 0.34, body.top + body.height * 0.38),
      size.width * 0.08,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(body.left + body.width * 0.36, body.top + body.height * 0.4),
      size.width * 0.035,
      pupil,
    );
    canvas.drawCircle(
      Offset(body.right - body.width * 0.32, body.top + body.height * 0.4),
      size.width * 0.035,
      pupil,
    );

    final smile = Paint()
      ..color = StudioColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(body.left + body.width * 0.38, body.top + body.height * 0.64)
      ..quadraticBezierTo(
        body.center.dx,
        body.top + body.height * 0.74,
        body.right - body.width * 0.38,
        body.top + body.height * 0.64,
      );
    canvas.drawPath(smilePath, smile);

    final leaf = Path()
      ..moveTo(body.center.dx, body.top - size.height * 0.02)
      ..quadraticBezierTo(
        body.center.dx + size.width * 0.16,
        body.top - size.height * 0.12,
        body.center.dx + size.width * 0.02,
        body.top + size.height * 0.08,
      )
      ..quadraticBezierTo(
        body.center.dx - size.width * 0.04,
        body.top,
        body.center.dx,
        body.top - size.height * 0.02,
      );
    canvas.drawPath(leaf, Paint()..color = StudioColors.mint);

    canvas.drawCircle(
      Offset(body.center.dx, body.top + 6),
      7,
      Paint()..color = StudioColors.butter,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
