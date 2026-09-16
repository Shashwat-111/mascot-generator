import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mascot_studio/main.dart';
import 'package:mascot_studio/service/dummy_studio_ai.dart';
import 'package:mascot_studio/service/studio_controller.dart';

MascotStudioRoot dummyStudioApp() {
  final controller = StudioController(
    ai: DummyStudioAi(delay: const Duration(milliseconds: 260)),
  );
  addTearDown(controller.dispose);
  return MascotStudioRoot(controller: controller);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('landing fits a laptop window without scrolling', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dummyStudioApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Give your product\na face'), findsOneWidget);

    final headline = tester.widget<Text>(
      find.text('Give your product\na face'),
    );
    expect(headline.textAlign, TextAlign.center);
    expect(
      tester.getRect(find.text('Give your product\na face')).center.dx,
      closeTo(640, 48),
    );
    expect(
      tester.getRect(find.byKey(const Key('landing-prompt'))).center.dx,
      closeTo(640, 48),
    );
    expect(tester.getRect(find.text('Linear')).center.dx, closeTo(640, 80));
  });

  testWidgets('landing stays centered on a phone window', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dummyStudioApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.text('Give your product\na face')).center.dx,
      closeTo(195, 36),
    );
    expect(
      tester.getRect(find.byKey(const Key('landing-prompt'))).center.dx,
      closeTo(195, 36),
    );
  });

  testWidgets('home is a single-prompt landing', (tester) async {
    await tester.pumpWidget(dummyStudioApp());
    await tester.pump();

    expect(find.text('Mascot Studio'), findsOneWidget);
    expect(find.text('Give your product\na face'), findsOneWidget);
    expect(find.byKey(const Key('landing-prompt')), findsOneWidget);
    expect(find.text('Product URL'), findsNothing);
    expect(find.text('Or describe it'), findsNothing);
    expect(find.text('Make a mascot'), findsNothing);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });

  testWidgets('example chip fills the prompt', (tester) async {
    await tester.pumpWidget(dummyStudioApp());
    await tester.pump();

    await tester.tap(find.text('Linear'));
    await tester.pump();

    expect(find.text('https://linear.app'), findsOneWidget);
  });

  testWidgets('submitting a prompt starts generation', (tester) async {
    await tester.pumpWidget(dummyStudioApp());
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('landing-prompt')),
      'A calm budgeting app for first-time renters.',
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    expect(find.textContaining('GEMINI_API_KEY'), findsNothing);
    expect(find.text('Reading the brand…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('Drawing four characters'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Who should be the mascot?'), findsOneWidget);
    expect(find.text('Pip'), findsOneWidget);
  });

  testWidgets('laptop window can pick a character without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dummyStudioApp());
    await tester.pump();
    expect(find.byType(SingleChildScrollView), findsNothing);

    await tester.enterText(
      find.byKey(const Key('landing-prompt')),
      'A calm budgeting app for first-time renters.',
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Who should be the mascot?'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);

    await tester.tap(find.text('Pip'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('What do you want Pip to do?'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
