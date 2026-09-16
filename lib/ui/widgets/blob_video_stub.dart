import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mascot_studio/ui/theme.dart';

class BlobVideoPlayer extends StatelessWidget {
  const BlobVideoPlayer({
    super.key,
    required this.bytes,
    required this.viewId,
    this.playing = true,
    this.muted = true,
    this.loop = true,
  });

  final Uint8List bytes;
  final String viewId;
  final bool playing;
  final bool muted;
  final bool loop;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: StudioColors.felt,
      child: Center(child: Text('Video preview is available on web.')),
    );
  }
}
