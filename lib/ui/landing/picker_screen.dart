import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mascot_studio/models/brand_brief.dart';
import 'package:mascot_studio/models/mascot_candidate.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/landing/landing_backdrop.dart';
import 'package:mascot_studio/ui/landing/landing_chrome.dart';
import 'package:mascot_studio/ui/theme.dart';
import 'package:mascot_studio/ui/widgets/studio_shell.dart';

class PickerScreen extends StatelessWidget {
  const PickerScreen({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final drawing = controller.step == StudioStep.drawing;
    final product = controller.brief?.productName;
    final concepts = controller.brief?.concepts ?? const <MascotConcept>[];

    return Scaffold(
      backgroundColor: StudioColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LandingBackdrop(quiet: true),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LandingChrome(controller: controller),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drawing
                            ? 'Drawing four characters'
                            : 'Who should be the mascot?',
                        style: StudioType.title(
                          MediaQuery.sizeOf(context).width,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drawing
                            ? (controller.status.isEmpty
                                  ? 'Each one lands as soon as it is ready.'
                                  : controller.status)
                            : product == null || product.isEmpty
                            ? "Tap one — next you'll give them something to do."
                            : "Four takes on $product. Tap one — next you'll give them something to do.",
                        style: StudioType.status(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _CastLineup(
                    concepts: concepts,
                    controller: controller,
                    drawing: drawing,
                  ),
                ),
              ],
            ),
          ),
          ...studioFeedbackOverlays(
            controller,
            onRetry: controller.busy ? null : controller.drawPalettes,
          ),
        ],
      ),
    );
  }
}

class _CastLineup extends StatelessWidget {
  const _CastLineup({
    required this.concepts,
    required this.controller,
    required this.drawing,
  });

  final List<MascotConcept> concepts;
  final StudioController controller;
  final bool drawing;

  static const _wideBreakpoint = 900.0;
  static const _gap = 16.0;
  static const _caption = 72.0;
  static const _maxSheet = 340.0;
  static const _minSheet = 72.0;
  static const _tilts = [-0.03, 0.04, -0.02, 0.05];

  @override
  Widget build(BuildContext context) {
    if (concepts.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= _wideBreakpoint && concepts.length >= 3;
        final columns = wide
            ? math.min(4, concepts.length)
            : math.min(2, concepts.length);
        final rows = (concepts.length / columns).ceil();
        final padH = wide ? 28.0 : 16.0;
        const padV = 10.0;
        final innerW = math.max(0.0, constraints.maxWidth - padH * 2);
        final innerH = math.max(0.0, constraints.maxHeight - padV * 2);
        final cellW = (innerW - _gap * (columns - 1)) / columns;
        final cellH = (innerH - _gap * (rows - 1)) / rows;
        final sheet = cellW.isFinite && cellH.isFinite
            ? math.min(
                _maxSheet,
                math.min(cellW, math.max(_minSheet, cellH - _caption)),
              )
            : _minSheet;

        Widget tileAt(int index) {
          final concept = concepts[index];
          final candidate = index < controller.slots.length
              ? controller.slots[index]
              : null;
          return SizedBox(
            width: sheet,
            child: _MascotTile(
              concept: concept,
              candidate: candidate,
              sheetSize: sheet,
              tilt: _tilts[index % _tilts.length],
              waiting: candidate == null && drawing,
              enabled:
                  candidate != null && controller.step == StudioStep.gallery,
              inStudio:
                  candidate != null &&
                  controller.selected?.concept.name == concept.name,
              onChoose: candidate == null
                  ? null
                  : () => controller.selectCandidate(candidate),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var row = 0; row < rows; row++) ...[
                  if (row > 0) const SizedBox(height: _gap),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var col = 0; col < columns; col++) ...[
                        if (col > 0) const SizedBox(width: _gap),
                        if (row * columns + col < concepts.length)
                          tileAt(row * columns + col),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MascotTile extends StatefulWidget {
  const _MascotTile({
    required this.concept,
    required this.candidate,
    required this.sheetSize,
    required this.tilt,
    required this.waiting,
    required this.enabled,
    required this.inStudio,
    required this.onChoose,
  });

  final MascotConcept concept;
  final MascotCandidate? candidate;
  final double sheetSize;
  final double tilt;
  final bool waiting;
  final bool enabled;
  final bool inStudio;
  final VoidCallback? onChoose;

  @override
  State<_MascotTile> createState() => _MascotTileState();
}

class _MascotTileState extends State<_MascotTile>
    with SingleTickerProviderStateMixin {
  var _hovered = false;
  var _focused = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.waiting) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _MascotTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waiting && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.waiting && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.candidate != null;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final active = _focused || (_hovered && ready);
    final ring = _focused
        ? StudioColors.ink
        : _hovered && ready
        ? StudioColors.cobalt
        : StudioColors.border;
    final lift = !reduce && active ? -4.0 : 0.0;

    return Semantics(
      button: ready,
      enabled: widget.enabled,
      label: ready
          ? 'Choose ${widget.concept.name}'
          : 'Drawing ${widget.concept.name}',
      child: FocusableActionDetector(
        enabled: widget.enabled,
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (show) => setState(() => _hovered = show),
        onShowFocusHighlight: (show) => setState(() => _focused = show),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onChoose?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onChoose,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: reduce ? 0 : 180),
                curve: Curves.easeOut,
                width: widget.sheetSize,
                height: widget.sheetSize,
                transform: Matrix4.translationValues(0, lift, 0),
                transformAlignment: Alignment.center,
                child: Transform.rotate(
                  angle: widget.tilt,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(StudioRadii.card),
                      border: Border.all(color: ring, width: active ? 2 : 1),
                      color: StudioColors.paper,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(StudioRadii.card - 1),
                      child: ColoredBox(
                        color: StudioColors.felt,
                        child: ready
                            ? Image.memory(
                                widget.candidate!.sheetBytes,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              )
                            : reduce
                            ? const SizedBox.expand()
                            : _LoadingPlate(animation: _pulse),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.concept.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: StudioType.captionName().copyWith(
                  color: active ? StudioColors.cobalt : StudioColors.ink,
                ),
              ),
              Text(
                widget.concept.species,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: StudioType.captionMeta(),
              ),
              if (widget.inStudio)
                Text(
                  'In studio',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: StudioType.captionMeta().copyWith(
                    color: StudioColors.cobalt,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPlate extends StatelessWidget {
  const _LoadingPlate({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ColoredBox(
          color: Color.lerp(
            StudioColors.felt,
            StudioColors.lavender.withValues(alpha: 0.45),
            animation.value,
          )!,
        );
      },
    );
  }
}
