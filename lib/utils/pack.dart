import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:mascot_studio/models/brand_brief.dart';
import 'package:mascot_studio/models/mascot_candidate.dart';
import 'package:mascot_studio/utils/download.dart';

Future<void> downloadMascotPack({
  required BrandBrief brief,
  required MascotCandidate candidate,
  required Map<String, Uint8List> videos,
}) async {
  final archive = Archive();

  void addFile(String name, List<int> bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  addFile(
    'brief.json',
    utf8.encode(
      const JsonEncoder.withIndent('  ').convert({
        'product': brief.productName,
        'oneLiner': brief.oneLiner,
        'audience': brief.audience,
        'tone': brief.tone,
        'palette': [
          for (final color in brief.palette)
            {'hex': color.normalizedHex, 'role': color.role},
        ],
        'mascot': {
          'name': candidate.concept.name,
          'species': candidate.concept.species,
          'personality': candidate.concept.personality,
          'identityLock': candidate.concept.identityLock,
        },
      }),
    ),
  );

  addFile('palette-sheet.png', candidate.sheetBytes);
  if (candidate.heroBytes != null) {
    addFile('hero.png', candidate.heroBytes!);
  }
  for (final entry in candidate.poses.entries) {
    addFile('poses/${entry.key}.png', entry.value);
  }
  for (final entry in videos.entries) {
    addFile('videos/${entry.key}.mp4', entry.value);
  }

  final zipped = ZipEncoder().encode(archive);
  downloadBytes(
    bytes: Uint8List.fromList(zipped),
    filename: '${_slug(candidate.concept.name)}-mascot-pack.zip',
    mime: 'application/zip',
  );
}

String _slug(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
