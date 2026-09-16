import 'package:flutter/material.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/theme.dart';
import 'package:mascot_studio/ui/widgets/pip_mascot.dart';

class LandingChrome extends StatelessWidget {
  const LandingChrome({super.key, this.controller, this.trailing});

  final StudioController? controller;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final studio = controller;
    final count = studio?.library.length ?? 0;
    final showNew =
        studio != null &&
        studio.step != StudioStep.welcome &&
        studio.step != StudioStep.analyzing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _Wordmark(onTap: studio?.showLanding),
              ),
            ),
          ),
          if (studio != null) ...[
            _TextAction(
              label: count == 0 ? 'Your work' : 'Your work ($count)',
              onPressed: studio.busy && studio.step == StudioStep.analyzing
                  ? null
                  : studio.showLibrary,
            ),
            if (showNew)
              _TextAction(
                label: 'New mascot',
                onPressed: studio.busy ? null : studio.newMascot,
              ),
          ],
          ?trailing,
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mark = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ExcludeSemantics(child: PipMascot(size: 28)),
        const SizedBox(width: 10),
        Text('Mascot Studio', style: StudioType.wordmark()),
      ],
    );

    if (onTap == null) return mark;

    return Semantics(
      button: true,
      label: 'Mascot Studio home',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: mark,
          ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}
