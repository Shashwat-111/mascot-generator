import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mascot_studio/models/studio_project.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/landing/landing_backdrop.dart';
import 'package:mascot_studio/ui/landing/landing_chrome.dart';
import 'package:mascot_studio/ui/theme.dart';
import 'package:mascot_studio/ui/widgets/studio_confirm.dart';
import 'package:mascot_studio/ui/widgets/studio_shell.dart';
import 'package:mascot_studio/utils/relative_time.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final projects = controller.library;

    return Scaffold(
      backgroundColor: StudioColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LandingBackdrop(quiet: true),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LandingChrome(controller: controller),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your work',
                        style: StudioType.title(
                          MediaQuery.sizeOf(context).width,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pick up where you left off.',
                        style: StudioType.status(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: projects.isEmpty
                      ? _EmptyShelf(onCreate: controller.newMascot)
                      : _Shelf(controller: controller, projects: projects),
                ),
              ],
            ),
          ),
          ...studioFeedbackOverlays(controller),
        ],
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nothing on the shelf yet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Prompts, mascots, and clips stay on this device after you make one.',
                textAlign: TextAlign.center,
                style: StudioType.status(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('library-empty-cta'),
                onPressed: onCreate,
                child: const Text('Make a mascot'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.controller, required this.projects});

  final StudioController controller;
  final List<StudioProject> projects;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return GridView.builder(
          key: const Key('library-shelf'),
          padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 12, wide ? 28 : 16, 24),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: wide ? 320 : 420,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.86,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return _ProjectCard(
              project: project,
              thumbnail: controller.thumbnails[project.id],
              tilt: index.isEven ? -0.02 : 0.03,
              onOpen: () => controller.openProject(project.id),
              onDelete: () => _confirmDelete(context, project),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StudioProject project,
  ) async {
    final clips = project.clipCount;
    final confirmed = await showStudioConfirm(
      context,
      title: 'Remove ${project.displayName} from this browser?',
      body: clips == 0
          ? 'This cannot be undone.'
          : '$clips ${clips == 1 ? 'clip' : 'clips'} will be deleted on this device. This cannot be undone.',
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;
    await controller.deleteProject(project.id);
  }
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({
    required this.project,
    required this.thumbnail,
    required this.tilt,
    required this.onOpen,
    required this.onDelete,
  });

  final StudioProject project;
  final Uint8List? thumbnail;
  final double tilt;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  var _hovered = false;
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final active = _hovered || _focused;
    final ring = _focused
        ? StudioColors.ink
        : _hovered
        ? StudioColors.cobalt
        : StudioColors.border;

    return Semantics(
      button: true,
      label: 'Open ${project.displayName}',
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (show) => setState(() => _hovered = show),
        onShowFocusHighlight: (show) => setState(() => _focused = show),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onOpen();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onOpen,
          child: Transform.rotate(
            angle: widget.tilt,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: StudioColors.paper,
                borderRadius: BorderRadius.circular(StudioRadii.card),
                border: Border.all(color: ring, width: active ? 2 : 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          StudioRadii.sticker,
                        ),
                        child: ColoredBox(
                          color: StudioColors.felt,
                          child: widget.thumbnail == null
                              ? const SizedBox.expand()
                              : Image.memory(
                                  widget.thumbnail!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      project.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StudioType.captionName(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project.prompt.trim().isEmpty
                          ? project.productName
                          : project.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StudioType.captionMeta(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${relativeTime(project.updatedAt)} · ${project.statsLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StudioType.captionMeta(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: widget.onOpen,
                          child: const Text('Open'),
                        ),
                        TextButton(
                          key: Key('library-delete-${project.id}'),
                          onPressed: widget.onDelete,
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
