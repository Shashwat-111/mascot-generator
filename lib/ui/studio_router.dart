import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/app.dart';

String locationFor(StudioController controller) {
  switch (controller.step) {
    case StudioStep.welcome:
    case StudioStep.analyzing:
      return '/';
    case StudioStep.library:
      return '/work';
    case StudioStep.drawing:
    case StudioStep.gallery:
      if (controller.projectId == null) return '/';
      return '/work/${controller.projectId}';
    case StudioStep.studio:
      if (controller.projectId == null) return '/';
      return '/work/${controller.projectId}/studio';
  }
}

GoRouter buildStudioRouter(StudioController controller) {
  var lastSynced = locationFor(controller);

  return GoRouter(
    initialLocation: lastSynced,
    refreshListenable: controller,
    redirect: (context, state) {
      final path = state.uri.path.isEmpty ? '/' : state.uri.path;
      final desired = locationFor(controller);
      if (path == desired) {
        lastSynced = path;
        return null;
      }
      if (desired != lastSynced) {
        return desired;
      }
      Future<void>.microtask(() => controller.applyPath(path));
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => const MascotStudioApp(),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/work',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/work/:id',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/work/:id/studio',
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      ),
    ],
  );
}
