import 'package:flutter/material.dart';
import 'package:mascot_studio/ui/theme.dart';

class StitchCard extends StatelessWidget {
  const StitchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = StudioColors.paper,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(StudioRadii.card),
        border: Border.all(color: StudioColors.border),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}
