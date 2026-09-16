import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mascot_studio/models/brand_brief.dart';
import 'package:mascot_studio/models/mascot_candidate.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/landing/picker_screen.dart';

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

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

StudioController _readyPicker() {
  final controller = StudioController();
  final brief = BrandBrief.fallback(notes: 'A calm budgeting app');
  controller.brief = brief;
  controller.step = StudioStep.gallery;
  controller.slots.addAll([
    for (final concept in brief.concepts)
      MascotCandidate(concept: concept, sheetBytes: _png),
  ]);
  return controller;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('drawing picker skips the brand recap', (tester) async {
    final controller = StudioController();
    addTearDown(controller.dispose);
    controller.brief = BrandBrief.fallback(notes: 'A calm budgeting app');
    controller.slots.addAll(List<MascotCandidate?>.filled(4, null));
    controller.step = StudioStep.drawing;
    controller.status = 'Drawing Pip…';

    await tester.pumpWidget(
      MaterialApp(home: PickerScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.text('This is the brand we heard'), findsNothing);
    expect(find.text('Draw these four'), findsNothing);
    expect(find.text('Drawing four characters'), findsOneWidget);
    expect(find.text('Pip'), findsOneWidget);
    expect(find.text('New mascot'), findsOneWidget);
  });

  testWidgets('ready picker selects a character', (tester) async {
    final controller = _readyPicker();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: PickerScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.text('Who should be the mascot?'), findsOneWidget);
    expect(find.text('Choose'), findsNothing);
    await tester.tap(find.text('Pip'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(controller.selected?.concept.name, 'Pip');
    expect(controller.step, StudioStep.studio);
  });

  for (final size in const [Size(1280, 720), Size(1440, 900)]) {
    testWidgets('picker fits ${size.width.toInt()}x${size.height.toInt()}', (
      tester,
    ) async {
      final controller = _readyPicker();
      addTearDown(controller.dispose);
      _setSurface(tester, size);

      await tester.pumpWidget(
        MaterialApp(home: PickerScreen(controller: controller)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(Scrollable), findsNothing);
      expect(find.text('Who should be the mascot?'), findsOneWidget);
      expect(find.text('Pip'), findsOneWidget);
      expect(find.text('Nori'), findsOneWidget);
      expect(find.text('Bolt'), findsOneWidget);
      expect(find.text('Pebble'), findsOneWidget);
    });
  }
}
