import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mascot_studio/ui/theme.dart';

class PromptComposer extends StatefulWidget {
  const PromptComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.analyzing,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool analyzing;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  State<PromptComposer> createState() => _PromptComposerState();
}

class _PromptComposerState extends State<PromptComposer>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focus;
  late final AnimationController _pulse;
  var _hovered = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode(onKeyEvent: _onKey);
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.analyzing) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PromptComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.analyzing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.analyzing && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _pulse.dispose();
    super.dispose();
  }

  bool get _canSend {
    return widget.enabled &&
        !widget.analyzing &&
        widget.controller.text.trim().isNotEmpty;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    if (_canSend) widget.onSubmit();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final borderColor = widget.analyzing
        ? StudioColors.ink.withValues(alpha: 0.55)
        : focused
        ? StudioColors.ink
        : _hovered
        ? StudioColors.ink.withValues(alpha: 0.45)
        : StudioColors.border;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: StudioColors.paper,
          borderRadius: BorderRadius.circular(StudioRadii.card),
          border: Border.all(color: borderColor, width: focused ? 1.6 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('landing-prompt'),
                  focusNode: _focus,
                  controller: widget.controller,
                  enabled: widget.enabled && !widget.analyzing,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: StudioType.body(),
                  cursorColor: StudioColors.ink,
                  onChanged: (value) {
                    widget.onChanged(value);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Paste a URL or describe your product',
                    hintStyle: StudioType.hint(),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.fromLTRB(2, 12, 8, 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              widget.analyzing ? _reading() : _sendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reading() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 4),
      child: SizedBox(
        width: 44,
        height: 44,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            return Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Opacity(
                      opacity:
                          0.35 + (0.65 * (1 - ((_pulse.value + i / 3) % 1))),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: i.isEven
                              ? StudioColors.ink
                              : StudioColors.butter,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(width: 6, height: 6),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sendButton() {
    return Tooltip(
      message: 'Make a mascot',
      child: FocusableActionDetector(
        mouseCursor: _canSend
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        enabled: _canSend,
        onShowFocusHighlight: (_) => setState(() {}),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (_canSend) widget.onSubmit();
              return null;
            },
          ),
        },
        child: Semantics(
          button: true,
          enabled: _canSend,
          label: 'Make a mascot',
          child: GestureDetector(
            onTap: _canSend ? widget.onSubmit : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _canSend ? 1 : 0.38,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: StudioColors.ink,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: StudioColors.paper,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
