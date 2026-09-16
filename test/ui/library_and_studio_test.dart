import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mascot_studio/models/brand_brief.dart';
import 'package:mascot_studio/models/mascot_action.dart';
import 'package:mascot_studio/models/mascot_candidate.dart';
import 'package:mascot_studio/models/studio_project.dart';
import 'package:mascot_studio/service/dummy_studio_ai.dart';
import 'package:mascot_studio/service/memory_studio_archive.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/library/library_screen.dart';
import 'package:mascot_studio/ui/studio_screen.dart';
import 'package:mascot_studio/ui/theme.dart';

final _png = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Widget _app(Widget home) {
  return MaterialApp(theme: buildStudioTheme(), home: home);
}

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
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('empty library invites a new mascot', (tester) async {
    final controller = StudioController();
    addTearDown(controller.dispose);
    controller.step = StudioStep.library;

    await tester.pumpWidget(_app(LibraryScreen(controller: controller)));
    await tester.pump();

    expect(find.text('Nothing on the shelf yet'), findsOneWidget);
    expect(find.byKey(const Key('library-empty-cta')), findsOneWidget);
    expect(find.byKey(const Key('library-shelf')), findsNothing);
  });

  testWidgets('full library shows saved work', (tester) async {
    final controller = StudioController();
    addTearDown(controller.dispose);
    controller.step = StudioStep.library;
    controller.library = [
      StudioProject(
        id: 'p1',
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 16),
        prompt: 'A calm budgeting app',
        productUrl: '',
        productNotes: 'A calm budgeting app',
        step: StudioStep.gallery,
        brief: BrandBrief.fallback(notes: 'A calm budgeting app'),
        selectedConceptName: 'Pip',
        candidates: const [
          StoredCandidate(conceptName: 'Pip', sheetBlobId: 'sheet'),
        ],
      ),
    ];

    await tester.pumpWidget(_app(LibraryScreen(controller: controller)));
    await tester.pump();

    expect(find.text('Nothing on the shelf yet'), findsNothing);
    expect(find.byKey(const Key('library-shelf')), findsOneWidget);
    expect(find.textContaining('Pip'), findsWidgets);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('ready clip plays instead of regenerating', (tester) async {
    final ai = _CountingAi();
    final archive = MemoryStudioArchive();
    final controller = StudioController(ai: ai, archive: archive);
    addTearDown(controller.dispose);
    final brief = BrandBrief.fallback(notes: 'A calm budgeting app');
    final candidate = MascotCandidate(
      concept: brief.concepts.first,
      sheetBytes: _png,
      heroBytes: _png,
    );
    controller
      ..brief = brief
      ..projectId = 'p1'
      ..projectCreatedAt = DateTime.now()
      ..step = StudioStep.studio
      ..selected = candidate
      ..slots.add(candidate)
      ..videos[studioActions.first.id] = _png
      ..activeVideoId = studioActions.first.id;

    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(StudioScreen(controller: controller)));
    await tester.pump();

    expect(find.text('What do you want Pip to do?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('clip-greet')));
    await tester.pump();
    expect(ai.animates, 0);
    expect(find.text('Nice. Your clip is ready.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('remake-greet')));
    await tester.pumpAndSettle();
    expect(find.text('Make this one again?'), findsOneWidget);
    await tester.tap(find.text('Make it again'));
    await tester.pumpAndSettle();
    expect(ai.animates, 1);
  });

  testWidgets('empty clip waits for create before generating', (tester) async {
    final ai = _CountingAi();
    final archive = MemoryStudioArchive();
    final controller = StudioController(ai: ai, archive: archive);
    addTearDown(controller.dispose);
    final brief = BrandBrief.fallback(notes: 'A calm budgeting app');
    final candidate = MascotCandidate(
      concept: brief.concepts.first,
      sheetBytes: _png,
      heroBytes: _png,
    );
    controller
      ..brief = brief
      ..projectId = 'p1'
      ..projectCreatedAt = DateTime.now()
      ..step = StudioStep.studio
      ..selected = candidate
      ..slots.add(candidate);

    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(StudioScreen(controller: controller)));
    await tester.pump();

    expect(find.text('What do you want Pip to do?'), findsOneWidget);
    final export = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Take them with you'),
    );
    expect(export.onPressed, isNull);

    await tester.tap(find.byKey(const Key('clip-greet')));
    await tester.pump();
    expect(ai.animates, 0);
    expect(find.text('Like it?'), findsOneWidget);
    expect(find.text('Create this clip to keep it.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-clip')));
    await tester.pumpAndSettle();
    expect(ai.animates, 1);
    expect(find.text('Nice. Your clip is ready.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Take them with you'),
          )
          .onPressed,
      isNotNull,
    );
  });
}
