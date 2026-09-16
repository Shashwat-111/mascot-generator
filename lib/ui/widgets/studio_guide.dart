import 'package:flutter/material.dart';
import 'package:mascot_studio/models/mascot_action.dart';
import 'package:mascot_studio/service/dummy_png.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/theme.dart';
import 'package:mascot_studio/ui/widgets/studio_confirm.dart';
import 'package:mascot_studio/utils/download.dart';

class StudioGuide extends StatefulWidget {
  const StudioGuide({super.key, required this.controller});

  final StudioController controller;

  @override
  State<StudioGuide> createState() => _StudioGuideState();
}

class _StudioGuideState extends State<StudioGuide> {
  MascotAction? _focused;

  StudioController get _controller => widget.controller;

  String get _name {
    final name = _controller.selected?.concept.name.trim() ?? '';
    return name.isEmpty ? 'your mascot' : name;
  }

  MascotAction? get _creating => mascotActionById(_controller.pendingActionId);

  bool _ready(MascotAction action) => _controller.videos.containsKey(action.id);

  void _focus(MascotAction action) {
    if (_controller.busy) return;
    setState(() => _focused = action);
    if (_ready(action)) {
      _controller.playClip(action.id);
    } else {
      _controller.showStill();
    }
  }

  Future<void> _create() async {
    final action = _focused;
    if (action == null || _controller.busy) return;
    await _controller.animate(action);
  }

  Future<void> _remake(MascotAction action) async {
    final confirmed = await showStudioConfirm(
      context,
      title: 'Make this one again?',
      body:
          'We will create a new ${action.label}. The current clip is replaced when the new one lands.',
      confirmLabel: 'Make it again',
    );
    if (!confirmed || !mounted) return;
    await _controller.animate(action, remake: true);
  }

  void _download(MascotAction action) {
    final bytes = _controller.videos[action.id];
    final name = _controller.selected?.concept.name ?? 'mascot';
    if (bytes == null) return;
    downloadBytes(
      bytes: bytes,
      filename: '$name-${action.id}.mp4',
      mime: looksLikePng(bytes) ? 'image/png' : 'video/mp4',
    );
  }

  @override
  Widget build(BuildContext context) {
    final creating = _creating;
    final focused = creating ?? _focused;
    final ready = focused != null && _ready(focused);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you want $_name to do?',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Pick a motion to preview, or create a clip to keep.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: StudioColors.muted),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, pane) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: pane.maxWidth),
                  child: _ChooseList(
                    controller: _controller,
                    focusedId: focused?.id,
                    enabled: !_controller.busy,
                    onChoose: _focus,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 168,
          width: double.infinity,
          child: _ActionDock(
            name: _name,
            creating: creating,
            focused: focused,
            ready: ready,
            busy: _controller.busy,
            onCreate: _create,
            onPlay: focused == null
                ? null
                : () => _controller.playClip(focused.id),
            onDownload: focused == null ? null : () => _download(focused),
            onRemake: focused == null ? null : () => _remake(focused),
          ),
        ),
      ],
    );
  }
}

class _ChooseList extends StatelessWidget {
  const _ChooseList({
    required this.controller,
    required this.focusedId,
    required this.enabled,
    required this.onChoose,
  });

  final StudioController controller;
  final String? focusedId;
  final bool enabled;
  final ValueChanged<MascotAction> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < studioActions.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _MotionOption(
            action: studioActions[i],
            ready: controller.videos.containsKey(studioActions[i].id),
            selected: focusedId == studioActions[i].id,
            generating: controller.pendingActionId == studioActions[i].id,
            enabled: enabled,
            onTap: () => onChoose(studioActions[i]),
          ),
        ],
      ],
    );
  }
}

class _MotionOption extends StatefulWidget {
  const _MotionOption({
    required this.action,
    required this.ready,
    required this.selected,
    required this.generating,
    required this.enabled,
    required this.onTap,
  });

  final MascotAction action;
  final bool ready;
  final bool selected;
  final bool generating;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_MotionOption> createState() => _MotionOptionState();
}

class _MotionOptionState extends State<_MotionOption> {
  var _hovered = false;
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final ring = widget.selected || _focused
        ? StudioColors.ink
        : _hovered
        ? StudioColors.cobalt
        : StudioColors.border;
    final fill = widget.generating
        ? StudioColors.lavender.withValues(alpha: 0.28)
        : StudioColors.paper;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      selected: widget.selected,
      label: '${widget.action.label}. ${widget.action.hint}',
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
              if (widget.enabled) widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          key: Key('clip-${widget.action.id}'),
          onTap: widget.enabled ? widget.onTap : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(StudioRadii.sticker),
              border: Border.all(color: ring),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      widget.action.emoji,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, height: 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 16),
                        ),
                        Text(
                          widget.action.hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 13,
                                height: 1.3,
                                color: StudioColors.muted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.generating)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: StudioColors.ink,
                      ),
                    )
                  else if (widget.ready)
                    Icon(
                      Icons.play_circle_outline_rounded,
                      size: 20,
                      color: StudioColors.muted,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionDock extends StatelessWidget {
  const _ActionDock({
    required this.name,
    required this.creating,
    required this.focused,
    required this.ready,
    required this.busy,
    required this.onCreate,
    required this.onPlay,
    required this.onDownload,
    required this.onRemake,
  });

  final String name;
  final MascotAction? creating;
  final MascotAction? focused;
  final bool ready;
  final bool busy;
  final VoidCallback onCreate;
  final VoidCallback? onPlay;
  final VoidCallback? onDownload;
  final VoidCallback? onRemake;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontSize: 18);
    final supportStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: StudioColors.muted);

    late final String title;
    late final String support;
    late final Widget actions;

    if (creating != null) {
      title = creating!.label;
      support = 'This takes a moment.';
      actions = Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: StudioColors.ink,
            ),
          ),
          const SizedBox(width: 10),
          Text('Creating…', style: supportStyle),
        ],
      );
    } else if (focused != null && ready) {
      title = 'Nice. Your clip is ready.';
      support = '${focused!.emoji}  ${focused!.label}';
      actions = Row(
        children: [
          FilledButton(
            key: const Key('play-clip'),
            onPressed: busy ? null : onPlay,
            child: const Text('Play'),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            key: const Key('download-clip'),
            onPressed: busy ? null : onDownload,
            child: const Text('Download'),
          ),
        ],
      );
    } else if (focused != null) {
      title = 'Like it?';
      support = 'Create this clip to keep it.';
      actions = FilledButton(
        key: const Key('create-clip'),
        onPressed: busy ? null : onCreate,
        child: const Text('Create clip'),
      );
    } else {
      title = 'Select a motion';
      support = 'The stage will preview $name.';
      actions = const SizedBox(height: 44);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StudioColors.paper,
        borderRadius: BorderRadius.circular(StudioRadii.card),
        border: Border.all(color: StudioColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
                if (focused != null && ready && creating == null)
                  TextButton(
                    key: Key('remake-${focused!.id}'),
                    onPressed: busy ? null : onRemake,
                    child: const Text('Make this one again'),
                  ),
              ],
            ),
            Text(
              support,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: supportStyle,
            ),
            const SizedBox(height: 12),
            actions,
          ],
        ),
      ),
    );
  }
}
