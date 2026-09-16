import 'package:mascot_studio/models/brand_brief.dart';

const mascotArtDirection = '''
Cute 3D clay / plush toy render, rounded forms, soft global illumination, felt-like surfaces, tiny catchlights in the eyes, premium collectible figurine look.
Centered character, isolated on a pale studio sweep, no text, no logo, no watermark, no UI chrome, no photoreal humans.
Simple enough to read at 64px, charming enough for a landing hero.
''';

String websiteSummaryPrompt({required String url, required String notes}) {
  return '''
Read this landing page and write a short product brief in plain sentences, not JSON and not a chat transcript:
$url

${notes.trim().isEmpty ? '' : 'Founder notes: ${notes.trim()}'}

Cover: product name, what it does, who it is for, tone of voice, and any visible brand colors with hex if you can see them.
If the page cannot be read, say so in one sentence and infer a reasonable product from the URL.
''';
}

String brandAnalysisPrompt({required String notes, String? url}) {
  final source = StringBuffer();
  if (url != null && url.trim().isNotEmpty) {
    source.writeln('Product URL: ${url.trim()}');
  }
  if (notes.trim().isNotEmpty) {
    source.writeln(notes.trim());
  }

  return '''
You are a character art director for product mascots.
Fill the JSON schema. Invent 4 distinct mascot contenders that could become a shippable brand character.

$source

Rules:
- Each mascot must be original, cute, and product-appropriate. No copyrighted characters.
- Vary species and silhouette so the four options feel different, not recolors of one idea.
- Prefer creatures, objects, or friendly robots over realistic people.
- identityLock must be a reusable paragraph: species, silhouette, materials, exact colors (hex), face, signature accessory.
- Palette: 4 to 6 colors with roles such as primary, accent, background, ink.
- If details are missing, invent a complete, usable brief anyway. Never return empty concepts.
''';
}

String paletteSheetPrompt({
  required BrandBrief brief,
  required MascotConcept concept,
}) {
  return '''
Create a mascot palette sheet for a product character.

Product: ${brief.productName}
What it does: ${brief.oneLiner}
Tone: ${brief.tone}
Brand colors: ${brief.palette.map((c) => '${c.role} ${c.normalizedHex}').join(', ')}

IDENTITY LOCK (do not violate):
${concept.identityLock}

Name: ${concept.name}
Species: ${concept.species}
Personality: ${concept.personality}

Layout: one image, four equal panels in a 2x2 grid, thin cream gutters, same character in every panel, consistent proportions.
Panel 1: front-facing hero, friendly smile, standing.
Panel 2: three-quarter view, waving hello.
Panel 3: celebrating with a small hop.
Panel 4: thinking pose, looking at a simple product-shaped prop that matches the app.

$mascotArtDirection
The four panels must clearly be the SAME mascot. No extra characters. No captions.
''';
}

String isolatedHeroPrompt({
  required BrandBrief brief,
  required MascotConcept concept,
}) {
  return '''
Create a single isolated hero portrait of this exact mascot.

IDENTITY LOCK (preserve exactly, do not redesign):
${concept.identityLock}

Name: ${concept.name}
Product: ${brief.productName}

Front-facing, knees-up or full body, centered, plenty of margin, pale studio sweep.
$mascotArtDirection
This image is the canonical reference for later poses and animation. Keep markings, colors, and silhouette identical to the attached reference sheet.
''';
}

String posePrompt({
  required BrandBrief brief,
  required MascotConcept concept,
  required String pose,
}) {
  return '''
Same mascot as the attached reference. Preserve identity, proportions, palette, markings, materials, and style exactly. Change only the pose.

IDENTITY LOCK:
${concept.identityLock}

Product: ${brief.productName}
Pose: $pose

Isolated on a pale studio sweep.
$mascotArtDirection
''';
}

/// Hard cap for generated mascot clips. Omni accepts 3–10s; Veo 3.1 accepts 4, 6, or 8.
const mascotClipDurationSeconds = 4;

String videoPrompt({
  required BrandBrief brief,
  required MascotConcept concept,
  required String motion,
}) {
  return '''
Animate the attached mascot. It is the only character. Keep identity, colors, silhouette, and materials identical to the reference image. No morphing, no extra limbs, no face swap.

IDENTITY LOCK:
${concept.identityLock}

Product mood: ${brief.tone}
Action: $motion

Duration: exactly $mascotClipDurationSeconds seconds. One beat of motion only — start, do the action, settle. No extra scenes, no story, no lingering hold, no camera moves.
Soft studio lighting. Camera locked. Cute, premium, product-ready.
Negative: realistic humans, text, logos, identity drift, extra characters, horror, uncanny faces, long idle, slow cinematic pacing.
''';
}

const posePack = {
  'hero': 'Centered hero standing, gentle smile, ready for a landing page.',
  'wave': 'Waving hello with one raised arm, weight on one foot.',
  'empty': 'Friendly shrug or open-hands empty state, still cute, not sad.',
  'error': 'Soft concerned look, tiny sweat drop optional, still brand-safe.',
};
