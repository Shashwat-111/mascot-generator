import 'dart:typed_data';

import 'package:mascot_studio/models/brand_brief.dart';
import 'package:mascot_studio/service/dummy_mascots.dart';
import 'package:mascot_studio/service/studio_ai.dart';

class DummyStudioAi implements StudioAi {
  DummyStudioAi({this.delay = const Duration(milliseconds: 260)});

  final Duration delay;
  var _drawCount = 0;

  @override
  Future<BrandBrief> analyzeBrand({String? url, required String notes}) async {
    await _pause();
    return BrandBrief.fallback(notes: notes, url: url);
  }

  @override
  Future<Uint8List> generateImage({
    required String prompt,
    List<Uint8List> references = const [],
    String aspectRatio = '1:1',
  }) async {
    await _pause(stagger: true);
    return paintDummyMascot(
      name: nameFromDummyPrompt(prompt),
      pose: poseFromDummyPrompt(prompt),
    );
  }

  @override
  Future<Uint8List> animateMascot({
    required String prompt,
    required Uint8List reference,
  }) async {
    await _pause();
    return paintDummyMascot(
      name: nameFromDummyPrompt(prompt),
      pose: poseFromDummyPrompt(prompt),
    );
  }

  @override
  void close() {}

  Future<void> _pause({bool stagger = false}) async {
    if (delay == Duration.zero && !stagger) return;
    final extra = stagger
        ? Duration(milliseconds: 80 * (_drawCount++ % 4))
        : Duration.zero;
    final wait = delay + extra;
    if (wait == Duration.zero) return;
    await Future<void>.delayed(wait);
  }
}

String nameFromDummyPrompt(String prompt) {
  for (final name in const ['Nori', 'Bolt', 'Pebble', 'Pip']) {
    if (RegExp('\\b$name\\b').hasMatch(prompt)) return name;
  }
  return 'Pip';
}

DummyPose poseFromDummyPrompt(String prompt) {
  final lower = prompt.toLowerCase();
  if (lower.contains('four equal panels') || lower.contains('palette sheet')) {
    return DummyPose.sheet;
  }
  if (lower.contains('waving hello') || lower.contains('waves one')) {
    return DummyPose.wave;
  }
  if (lower.contains('celebrat') || lower.contains('hops once')) {
    return DummyPose.celebrate;
  }
  if (lower.contains('think') ||
      lower.contains('taps its chin') ||
      lower.contains('looking at a simple product')) {
    return DummyPose.think;
  }
  if (lower.contains('empty state') || lower.contains('shrug')) {
    return DummyPose.empty;
  }
  if (lower.contains('concerned') || lower.contains('error')) {
    return DummyPose.error;
  }
  if (lower.contains('present') || lower.contains('open-palm')) {
    return DummyPose.present;
  }
  if (lower.contains('peek')) {
    return DummyPose.peek;
  }
  if (lower.contains('idle') || lower.contains('breathing bounce')) {
    return DummyPose.idle;
  }
  return DummyPose.hero;
}
