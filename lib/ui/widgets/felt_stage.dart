import 'package:flutter/material.dart';
import 'package:mascot_studio/ui/theme.dart';
import 'package:mascot_studio/ui/widgets/pip_mascot.dart';

class FeltStage extends StatelessWidget {
  const FeltStage({super.key, this.child, this.size = 280, this.caption})
    : overlay = null,
      expand = false;

  const FeltStage.board({super.key, this.overlay, required Widget this.child})
    : size = 0,
      caption = null,
      expand = true;

  final Widget? child;
  final double size;
  final String? caption;
  final Widget? overlay;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    if (expand) {
      return _Board(overlay: overlay, child: child!);
    }
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size * 0.72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: StudioColors.felt,
                ),
              ),
              Positioned(
                bottom: size * 0.16,
                child: Container(
                  width: size * 0.52,
                  height: 18,
                  decoration: BoxDecoration(
                    color: StudioColors.ink.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              child ?? const PipMascot(size: 168),
            ],
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 8),
          Text(
            caption!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: StudioColors.muted),
          ),
        ],
      ],
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({this.overlay, required this.child});

  final Widget child;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StudioColors.paper,
        borderRadius: BorderRadius.circular(StudioRadii.card),
        border: Border.all(color: StudioColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(StudioRadii.sticker),
          child: ColoredBox(
            color: StudioColors.felt,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x14F5D15A),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
                child,
                ?overlay,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
