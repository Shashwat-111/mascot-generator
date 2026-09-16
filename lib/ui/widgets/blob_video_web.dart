// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mascot_studio/ui/theme.dart';
import 'package:mascot_studio/utils/download.dart';

class BlobVideoPlayer extends StatefulWidget {
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
  State<BlobVideoPlayer> createState() => _BlobVideoPlayerState();
}

class _BlobVideoPlayerState extends State<BlobVideoPlayer> {
  html.VideoElement? _element;
  late String _url;
  late Uint8List _heldBytes;

  @override
  void initState() {
    super.initState();
    _heldBytes = widget.bytes;
    _url = retainBlobUrl(_heldBytes, mime: _videoMime(_heldBytes));
  }

  @override
  void didUpdateWidget(covariant BlobVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      final previousBytes = _heldBytes;
      _heldBytes = widget.bytes;
      _url = retainBlobUrl(_heldBytes, mime: _videoMime(_heldBytes));
      final element = _element;
      if (element != null) {
        element.src = _url;
        element.load();
      }
      releaseBlobUrl(previousBytes);
    }
    _syncElement();
  }

  @override
  void dispose() {
    final element = _element;
    _element = null;
    if (element != null) {
      element.pause();
      element.removeAttribute('src');
      element.load();
    }
    releaseBlobUrl(_heldBytes);
    super.dispose();
  }

  void _onElementCreated(Object created) {
    if (!mounted) return;
    final element = created as html.VideoElement;
    _element = element
      ..controls = false
      ..preload = 'auto'
      ..setAttribute('playsinline', 'true')
      ..setAttribute('disablepictureinpicture', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain'
      ..style.backgroundColor = 'transparent'
      ..style.border = 'none'
      ..style.borderRadius = '${StudioRadii.sticker}px';
    element.src = _url;
    _syncElement();
  }

  void _syncElement() {
    final element = _element;
    if (element == null) return;
    element
      ..loop = widget.loop
      ..muted = widget.muted
      ..autoplay = widget.playing;
    if (widget.playing) {
      unawaited(
        element.play().then<void>(
          (_) {},
          onError: (Object _, StackTrace __) {},
        ),
      );
    } else {
      element.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      key: ValueKey(widget.viewId),
      tagName: 'video',
      onElementCreated: _onElementCreated,
    );
  }
}

String _videoMime(Uint8List bytes) {
  if (bytes.length >= 4 &&
      bytes[0] == 0x1A &&
      bytes[1] == 0x45 &&
      bytes[2] == 0xDF &&
      bytes[3] == 0xA3) {
    return 'video/webm';
  }
  return 'video/mp4';
}
