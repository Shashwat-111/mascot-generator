import 'package:flutter/material.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/landing/landing_backdrop.dart';
import 'package:mascot_studio/ui/landing/landing_chrome.dart';
import 'package:mascot_studio/ui/landing/prompt_composer.dart';
import 'package:mascot_studio/ui/theme.dart';
import 'package:mascot_studio/ui/widgets/pip_mascot.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key, required this.controller});

  final StudioController controller;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late final TextEditingController _prompt;

  static const _examples = <({String label, String prompt})>[
    (
      label: 'Budgeting app',
      prompt:
          'A calm budgeting app for first-time renters. Soft greens, honest tone, not childish.',
    ),
    (label: 'Linear', prompt: 'https://linear.app'),
    (
      label: 'Noisy frog',
      prompt: 'A noisy crypto exchange that needs a friendly frog.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _prompt = TextEditingController(text: widget.controller.prompt);
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  void _submit() {
    widget.controller.applyPrompt(_prompt.text);
    widget.controller.startBriefing();
  }

  void _fillExample(String value) {
    _prompt.text = value;
    _prompt.selection = TextSelection.collapsed(offset: value.length);
    widget.controller.applyPrompt(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final analyzing = controller.step == StudioStep.analyzing;

    return Scaffold(
      backgroundColor: StudioColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LandingBackdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LandingChrome(controller: controller),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gutter = constraints.maxWidth >= 720 ? 32.0 : 20.0;
                      return Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 20),
                        child: _HeroCopy(
                          controller: controller,
                          width: constraints.maxWidth - gutter * 2,
                          height: constraints.maxHeight - 28,
                          analyzing: analyzing,
                          prompt: _prompt,
                          error: controller.error,
                          status: controller.status,
                          onChanged: controller.applyPrompt,
                          onSubmit: _submit,
                          onExample: analyzing ? null : _fillExample,
                          examples: _examples,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.controller,
    required this.width,
    required this.height,
    required this.analyzing,
    required this.prompt,
    required this.error,
    required this.status,
    required this.onChanged,
    required this.onSubmit,
    required this.onExample,
    required this.examples,
  });

  final StudioController controller;
  final double width;
  final double height;
  final bool analyzing;
  final TextEditingController prompt;
  final String? error;
  final String status;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final ValueChanged<String>? onExample;
  final List<({String label, String prompt})> examples;

  static const _accents = [
    StudioColors.coral,
    StudioColors.cobalt,
    StudioColors.mint,
  ];

  @override
  Widget build(BuildContext context) {
    final compact = height < 560;
    final columnWidth = width.clamp(0, 640).toDouble();
    final composerWidth = columnWidth.clamp(0, 520).toDouble();
    final pipSize = compact
        ? (height < 480 ? 88.0 : 112.0)
        : width >= 900
        ? 148.0
        : 124.0;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: columnWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PipMascot(size: pipSize),
              SizedBox(height: compact ? 10 : 16),
              Text(
                'Give your product\na face',
                textAlign: TextAlign.center,
                style: StudioType.headline(width),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  'One sentence. A character you can actually\u00A0use.',
                  textAlign: TextAlign.center,
                  style: StudioType.subhead(width),
                ),
              ),
              SizedBox(height: compact ? 24 : 32),
              SizedBox(
                width: composerWidth,
                child: PromptComposer(
                  controller: prompt,
                  enabled: !analyzing,
                  analyzing: analyzing,
                  onChanged: onChanged,
                  onSubmit: onSubmit,
                ),
              ),
              if (analyzing) ...[
                const SizedBox(height: 14),
                Text(
                  status.isEmpty ? 'Reading the brand…' : status,
                  textAlign: TextAlign.center,
                  style: StudioType.status(),
                ),
              ],
              if (error != null && error!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: StudioType.status().copyWith(
                    color: StudioColors.coral,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < examples.length; i++)
                    _ExampleChip(
                      label: examples[i].label,
                      accent: _accents[i % _accents.length],
                      tilt: i == 0
                          ? -0.04
                          : i == 1
                          ? 0.035
                          : -0.02,
                      enabled: onExample != null,
                      onTap: onExample == null
                          ? null
                          : () => onExample!(examples[i].prompt),
                    ),
                ],
              ),
              if (controller.latestProject != null && !analyzing) ...[
                const SizedBox(height: 18),
                _ContinueChip(
                  label: 'Continue ${controller.latestProject!.displayName}',
                  onTap: () =>
                      controller.openProject(controller.latestProject!.id),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleChip extends StatefulWidget {
  const _ExampleChip({
    required this.label,
    required this.accent,
    required this.tilt,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final double tilt;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_ExampleChip> createState() => _ExampleChipState();
}

class _ExampleChipState extends State<_ExampleChip> {
  var _hovered = false;
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final ring = _focused
        ? StudioColors.ink
        : _hovered
        ? widget.accent
        : widget.accent.withValues(alpha: 0.7);

    return Transform.rotate(
      angle: widget.tilt,
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
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: widget.enabled ? 1 : 0.45,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: StudioColors.paper,
                borderRadius: BorderRadius.circular(StudioRadii.sticker),
                border: Border.all(color: ring),
              ),
              child: Text(widget.label, style: StudioType.chip()),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueChip extends StatefulWidget {
  const _ContinueChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_ContinueChip> createState() => _ContinueChipState();
}

class _ContinueChipState extends State<_ContinueChip> {
  var _hovered = false;
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final ring = _focused
        ? StudioColors.ink
        : _hovered
        ? StudioColors.cobalt
        : StudioColors.cobalt.withValues(alpha: 0.7);

    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (show) => setState(() => _hovered = show),
      onShowFocusHighlight: (show) => setState(() => _focused = show),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: StudioColors.paper,
            borderRadius: BorderRadius.circular(StudioRadii.sticker),
            border: Border.all(color: ring),
          ),
          child: Text(widget.label, style: StudioType.chip()),
        ),
      ),
    );
  }
}
