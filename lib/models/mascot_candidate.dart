import 'dart:typed_data';

import 'package:mascot_studio/models/brand_brief.dart';

class MascotCandidate {
  const MascotCandidate({
    required this.concept,
    required this.sheetBytes,
    this.heroBytes,
    this.poses = const {},
  });

  final MascotConcept concept;
  final Uint8List sheetBytes;
  final Uint8List? heroBytes;
  final Map<String, Uint8List> poses;

  MascotCandidate copyWith({
    Uint8List? heroBytes,
    Map<String, Uint8List>? poses,
  }) {
    return MascotCandidate(
      concept: concept,
      sheetBytes: sheetBytes,
      heroBytes: heroBytes ?? this.heroBytes,
      poses: poses ?? this.poses,
    );
  }

  Uint8List get referenceBytes => heroBytes ?? sheetBytes;
}
