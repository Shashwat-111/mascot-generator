import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mascot_studio/models/mascot_action.dart';
import 'package:mascot_studio/service/dummy_studio_ai.dart';
import 'package:mascot_studio/service/generation_mode.dart';
import 'package:mascot_studio/service/memory_studio_archive.dart';
import 'package:mascot_studio/service/studio_controller.dart';

class _CountingAi extends DummyStudioAi {
  _CountingAi() : super(delay: Duration.zero);

  var animates = 0;

  @override
  Future<Uint8List> animateMascot({
    required String prompt,
    required Uint8List reference,
  }) async {
    animates += 1;
    return super.animateMascot(prompt: prompt, reference: reference);
  }
}

void main() {
  test('applyPrompt splits a mixed prompt into url and notes', () {
    final controller = StudioController(
      ai: DummyStudioAi(delay: Duration.zero),
    );
    addTearDown(controller.dispose);

    controller.applyPrompt('A workspace tool. https://linear.app Ship faster.');

    expect(controller.prompt, contains('linear.app'));
    expect(controller.productUrl, 'https://linear.app');
    expect(controller.productNotes, 'A workspace tool. Ship faster.');
  });

  test('dummy briefing reaches the gallery without a Gemini key', () async {
    final controller = StudioController(
      ai: DummyStudioAi(delay: Duration.zero),
    );
    addTearDown(controller.dispose);
    controller.applyPrompt('A calm budgeting app');

    await controller.startBriefing();

    expect(controller.step, StudioStep.gallery);
    expect(controller.error, isNull);
    expect(controller.candidates, hasLength(4));
    expect(controller.brief?.concepts.map((c) => c.name), contains('Pip'));
  });

  test('live Gemini is the default generation path', () {
    expect(kUseLiveGemini, isTrue);
    final controller = StudioController();
    addTearDown(controller.dispose);
    expect(controller.useLiveGemini, isTrue);
  });

  test('live Gemini without a key stays on welcome and reports it', () async {
    final controller = StudioController(useLiveGemini: true);
    addTearDown(controller.dispose);
    controller.applyPrompt('A calm budgeting app');

    await controller.startBriefing();

    expect(controller.step, StudioStep.welcome);
    expect(controller.error, contains('GEMINI_API_KEY'));
  });

  test('generations persist and reload from the archive', () async {
    final archive = MemoryStudioArchive();
    final ai = DummyStudioAi(delay: Duration.zero);
    final controller = StudioController(ai: ai, archive: archive);
    addTearDown(controller.dispose);
    controller.applyPrompt('A calm budgeting app');

    await controller.startBriefing();
    final pip = controller.candidates.firstWhere(
      (item) => item.concept.name == 'Pip',
    );
    await controller.selectCandidate(pip);
    await controller.animate(studioActions.first, remake: true);

    expect(archive.projects, isNotEmpty);
    expect(controller.videos.containsKey('greet'), isTrue);

    final restored = StudioController(ai: ai, archive: archive);
    addTearDown(restored.dispose);
    await restored.bootstrap();

    expect(restored.step, StudioStep.studio);
    expect(restored.selected?.concept.name, 'Pip');
    expect(restored.videos.containsKey('greet'), isTrue);
    expect(restored.library, isNotEmpty);
  });

  test('reopening the same character keeps clips', () async {
    final archive = MemoryStudioArchive();
    final controller = StudioController(
      ai: DummyStudioAi(delay: Duration.zero),
      archive: archive,
    );
    addTearDown(controller.dispose);
    controller.applyPrompt('A calm budgeting app');
    await controller.startBriefing();
    final pip = controller.candidates.firstWhere(
      (item) => item.concept.name == 'Pip',
    );
    await controller.selectCandidate(pip);
    await controller.animate(studioActions.first, remake: true);
    expect(controller.videos.containsKey('greet'), isTrue);

    controller.backToGallery();
    await controller.selectCandidate(pip);
    expect(controller.videos.containsKey('greet'), isTrue);
  });

  test('playing a ready clip does not regenerate it', () async {
    final ai = _CountingAi();
    final controller = StudioController(ai: ai);
    addTearDown(controller.dispose);
    controller.applyPrompt('A calm budgeting app');
    await controller.startBriefing();
    await controller.selectCandidate(controller.candidates.first);
    await controller.animate(studioActions.first, remake: true);
    expect(ai.animates, 1);

    await controller.animate(studioActions.first);
    expect(ai.animates, 1);
    expect(controller.activeVideoId, studioActions.first.id);

    await controller.animate(studioActions[1], remake: true);
    expect(ai.animates, 2);
    await controller.animate(studioActions.first);
    expect(ai.animates, 2);
    expect(controller.videos.keys, containsAll(['greet', 'celebrate']));
    expect(controller.activeVideoId, studioActions.first.id);
  });

  test('quota errors keep in-memory clips and surface a banner', () async {
    final archive = MemoryStudioArchive();
    final controller = StudioController(
      ai: DummyStudioAi(delay: Duration.zero),
      archive: archive,
    );
    addTearDown(controller.dispose);
    controller.applyPrompt('A calm budgeting app');
    await controller.startBriefing();
    await controller.selectCandidate(controller.candidates.first);
    archive.quotaExceeded = true;
    await controller.animate(studioActions.first, remake: true);

    expect(controller.videos.containsKey('greet'), isTrue);
    expect(controller.error, contains('out of space'));
  });

  test('new mascot keeps the library', () async {
    final archive = MemoryStudioArchive();
    final controller = StudioController(
      ai: DummyStudioAi(delay: Duration.zero),
      archive: archive,
    );
    addTearDown(controller.dispose);
    controller.applyPrompt('A calm budgeting app');
    await controller.startBriefing();
    await controller.newMascot();

    expect(controller.step, StudioStep.welcome);
    expect(controller.brief, isNull);
    expect(controller.library, isNotEmpty);
  });
}
