enum StudioStep { welcome, analyzing, drawing, gallery, studio, library }

StudioStep studioStepFromName(String? name) {
  for (final step in StudioStep.values) {
    if (step.name == name) return step;
  }
  return StudioStep.welcome;
}
