import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mascot_studio/service/dummy_mascots.dart';
import 'package:mascot_studio/service/dummy_png.dart';
import 'package:mascot_studio/service/dummy_studio_ai.dart';

void main() {
  test('dummy prompts pick the matching mascot and pose', () {
    expect(nameFromDummyPrompt('Name: Nori\nSpecies: fox'), 'Nori');
    expect(
      poseFromDummyPrompt('Layout: one image, four equal panels'),
      DummyPose.sheet,
    );
    expect(
      poseFromDummyPrompt('The mascot hops once and throws both arms'),
      DummyPose.celebrate,
    );
    expect(
      poseFromDummyPrompt('Waving hello with one raised arm'),
      DummyPose.wave,
    );
  });

  testWidgets('dummy mascot pngs decode in Flutter', (tester) async {
    final bytes = paintDummyMascot(name: 'Pip', pose: DummyPose.hero, size: 96);
    expect(looksLikePng(bytes), isTrue);

    await tester.pumpWidget(
      MaterialApp(home: Image.memory(bytes, width: 96, height: 96)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('dummy studio ai returns a four-mascot brief', () async {
    final ai = DummyStudioAi(delay: Duration.zero);
    final brief = await ai.analyzeBrand(notes: 'A calm budgeting app');
    expect(brief.concepts, hasLength(4));
    expect(brief.productName, isNotEmpty);

    final sheet = await ai.generateImage(prompt: paletteSheetPromptLike('Pip'));
    expect(looksLikePng(sheet), isTrue);
  });
}

String paletteSheetPromptLike(String name) {
  return 'Create a mascot palette sheet.\nName: $name\nfour equal panels in a 2x2 grid';
}
