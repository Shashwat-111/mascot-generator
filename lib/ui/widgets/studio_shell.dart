import 'package:flutter/material.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/landing/landing_backdrop.dart';
import 'package:mascot_studio/ui/landing/landing_chrome.dart';
import 'package:mascot_studio/ui/theme.dart';

class StudioShell extends StatelessWidget {
  const StudioShell({super.key, required this.controller, required this.child});

  final StudioController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudioColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LandingBackdrop(quiet: true),
          SafeArea(
            child: Column(
              children: [
                LandingChrome(controller: controller),
                Expanded(child: child),
              ],
            ),
          ),
          ...studioFeedbackOverlays(controller),
        ],
      ),
    );
  }
}

List<Widget> studioFeedbackOverlays(
  StudioController controller, {
  VoidCallback? onRetry,
}) {
  return [
    if (controller.busy) const _TopProgress(),
    if (controller.error != null && controller.error!.isNotEmpty)
      _ErrorToast(
        message: controller.error!,
        onDismiss: controller.clearError,
        onRetry: onRetry,
      ),
  ];
}

class _TopProgress extends StatelessWidget {
  const _TopProgress();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: LinearProgressIndicator(
          minHeight: 2,
          backgroundColor: Colors.transparent,
          color: StudioColors.ink,
        ),
      ),
    );
  }
}

class _ErrorToast extends StatelessWidget {
  const _ErrorToast({
    required this.message,
    required this.onDismiss,
    this.onRetry,
  });

  final String message;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 24,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: StudioColors.errorWash,
                borderRadius: BorderRadius.circular(StudioRadii.sticker),
                border: Border.all(color: StudioColors.coral),
                boxShadow: [
                  BoxShadow(
                    color: StudioColors.ink.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: StudioColors.coral,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    IconButton(
                      tooltip: 'Dismiss',
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close_rounded, size: 18),
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
