import 'package:flutter/material.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/landing/landing_screen.dart';
import 'package:mascot_studio/ui/landing/picker_screen.dart';
import 'package:mascot_studio/ui/library/library_screen.dart';
import 'package:mascot_studio/ui/studio_screen.dart';
import 'package:mascot_studio/ui/widgets/studio_shell.dart';
import 'package:provider/provider.dart';

class MascotStudioApp extends StatelessWidget {
  const MascotStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudioController>(
      builder: (context, controller, _) {
        final onLanding =
            controller.step == StudioStep.welcome ||
            controller.step == StudioStep.analyzing;
        final onPicker =
            controller.step == StudioStep.drawing ||
            controller.step == StudioStep.gallery;

        if (onLanding) {
          return LandingScreen(controller: controller);
        }
        if (controller.step == StudioStep.library) {
          return LibraryScreen(controller: controller);
        }
        if (onPicker) {
          return PickerScreen(controller: controller);
        }

        return StudioShell(
          controller: controller,
          child: StudioScreen(controller: controller),
        );
      },
    );
  }
}
