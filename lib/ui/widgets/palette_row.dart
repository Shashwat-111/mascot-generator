import 'package:flutter/material.dart';
import 'package:mascot_studio/models/brand_brief.dart';
import 'package:mascot_studio/ui/theme.dart';

class PaletteRow extends StatelessWidget {
  const PaletteRow({super.key, required this.palette});

  final List<ColorSwatchInfo> palette;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final swatch in palette)
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _parse(swatch.normalizedHex),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: StudioColors.border),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                swatch.role,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: StudioColors.muted,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Color _parse(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse(value, radix: 16));
  }
}
