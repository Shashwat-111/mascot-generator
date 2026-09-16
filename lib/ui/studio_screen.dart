import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mascot_studio/models/mascot_action.dart';
import 'package:mascot_studio/service/dummy_png.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/theme.dart';
import 'package:mascot_studio/ui/widgets/blob_video.dart';
import 'package:mascot_studio/ui/widgets/felt_stage.dart';
import 'package:mascot_studio/ui/widgets/studio_guide.dart';
import 'package:mascot_studio/utils/download.dart';

class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final selected = controller.selected;
    if (selected == null) return const SizedBox.shrink();
    final videoId = controller.activeVideoId;
    final videoBytes = videoId == null ? null : controller.videos[videoId];
    final generating = controller.pendingActionId;
    final generatingAction = mascotActionById(generating);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      child: Column(
        children: [
          _StudioToolbar(controller: controller),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Expanded(
                        child: _Stage(
                          stillBytes: selected.referenceBytes,
                          videoId: videoId,
                          videoBytes: videoBytes,
                          generatingLabel: generatingAction == null
                              ? null
                              : '${generatingAction.label}… this takes a moment.',
                          onDownload: videoBytes == null
                              ? null
                              : () => downloadBytes(
                                  bytes: videoBytes,
                                  filename:
                                      '${selected.concept.name}-$videoId.mp4',
                                  mime: looksLikePng(videoBytes)
                                      ? 'image/png'
                                      : 'video/mp4',
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        selected.concept.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        selected.concept.personality,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: StudioColors.muted,
                        ),
                      ),
                      _PoseRow(controller: controller),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(flex: 4, child: StudioGuide(controller: controller)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioToolbar extends StatelessWidget {
  const _StudioToolbar({required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final hasClips = controller.videos.isNotEmpty;
    final hasStills = (controller.selected?.poses ?? const {}).isNotEmpty;

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          TextButton(
            onPressed: controller.busy ? null : controller.backToGallery,
            child: const Text('Choose a different character'),
          ),
          const Spacer(),
          Visibility(
            visible: hasClips && !hasStills,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: TextButton(
              onPressed: controller.busy ? null : controller.generatePosePack,
              child: const Text('Want stills too?'),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: controller.busy || !hasClips
                ? null
                : controller.downloadPack,
            child: const Text('Take them with you'),
          ),
        ],
      ),
    );
  }
}

class _Stage extends StatefulWidget {
  const _Stage({
    required this.stillBytes,
    required this.videoId,
    required this.videoBytes,
    required this.generatingLabel,
    required this.onDownload,
  });

  final Uint8List stillBytes;
  final String? videoId;
  final Uint8List? videoBytes;
  final String? generatingLabel;
  final VoidCallback? onDownload;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  var _playing = true;
  var _muted = true;
  var _looping = true;

  bool get _isVideo {
    final bytes = widget.videoBytes;
    return bytes != null && !looksLikePng(bytes);
  }

  @override
  void didUpdateWidget(covariant _Stage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId ||
        oldWidget.videoBytes != widget.videoBytes) {
      final reduce = MediaQuery.disableAnimationsOf(context);
      _playing = !reduce && _isVideo;
      _muted = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final overlay = widget.generatingLabel == null
        ? null
        : _GeneratingOverlay(label: widget.generatingLabel!);

    return Semantics(
      liveRegion: widget.generatingLabel != null,
      child: FeltStage.board(
        overlay: overlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _PreviewMedia(
              stillBytes: widget.stillBytes,
              videoId: widget.videoId,
              videoBytes: widget.videoBytes,
              playing: _playing && !reduce,
              muted: _muted,
              loop: _looping,
            ),
            if (_isVideo)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: _PlayerChrome(
                  playing: _playing && !reduce,
                  muted: _muted,
                  looping: _looping,
                  onPlayPause: () => setState(() => _playing = !_playing),
                  onMute: () => setState(() => _muted = !_muted),
                  onLoop: () => setState(() => _looping = !_looping),
                  onDownload: widget.onDownload,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GeneratingOverlay extends StatelessWidget {
  const _GeneratingOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StudioColors.paper.withValues(alpha: 0.62),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: StudioColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(label, style: StudioType.status()),
          ],
        ),
      ),
    );
  }
}

class _PlayerChrome extends StatelessWidget {
  const _PlayerChrome({
    required this.playing,
    required this.muted,
    required this.looping,
    required this.onPlayPause,
    required this.onMute,
    required this.onLoop,
    required this.onDownload,
  });

  final bool playing;
  final bool muted;
  final bool looping;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;
  final VoidCallback onLoop;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StudioColors.paper.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(StudioRadii.sticker),
        border: Border.all(color: StudioColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          children: [
            _ChromeButton(
              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: playing ? 'Pause' : 'Play',
              onPressed: onPlayPause,
            ),
            _ChromeButton(
              icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              label: muted ? 'Unmute' : 'Mute',
              onPressed: onMute,
            ),
            _ChromeButton(
              icon: Icons.loop_rounded,
              label: looping ? 'Loop on' : 'Loop off',
              selected: looping,
              onPressed: onLoop,
            ),
            const Spacer(),
            if (onDownload != null)
              _ChromeButton(
                icon: Icons.download_rounded,
                label: 'Download',
                onPressed: onDownload!,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      color: selected ? StudioColors.cobalt : StudioColors.ink,
      icon: Icon(icon, size: 22),
    );
  }
}

class _PreviewMedia extends StatelessWidget {
  const _PreviewMedia({
    required this.stillBytes,
    required this.videoId,
    required this.videoBytes,
    required this.playing,
    required this.muted,
    required this.loop,
  });

  final Uint8List stillBytes;
  final String? videoId;
  final Uint8List? videoBytes;
  final bool playing;
  final bool muted;
  final bool loop;

  @override
  Widget build(BuildContext context) {
    final bytes = videoBytes;
    if (bytes != null && !looksLikePng(bytes)) {
      return BlobVideoPlayer(
        key: ValueKey(videoId),
        bytes: bytes,
        viewId: 'mascot-video-$videoId',
        playing: playing,
        muted: muted,
        loop: loop,
      );
    }
    return Image.memory(
      bytes ?? stillBytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}

class _PoseRow extends StatelessWidget {
  const _PoseRow({required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final poses = controller.selected?.poses ?? const {};
    if (poses.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in poses.entries)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => downloadBytes(
                  bytes: entry.value,
                  filename: '${entry.key}.png',
                  mime: 'image/png',
                ),
                child: Tooltip(
                  message: 'Download ${entry.key}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(StudioRadii.sticker),
                    child: Image.memory(
                      entry.value,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
