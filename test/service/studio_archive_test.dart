import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:mascot_studio/models/brand_brief.dart';
import 'package:mascot_studio/models/studio_project.dart';
import 'package:mascot_studio/models/studio_step.dart';
import 'package:mascot_studio/service/idb_studio_archive.dart';
import 'package:mascot_studio/service/memory_studio_archive.dart';
import 'package:mascot_studio/service/studio_archive.dart';

final _png = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
]);

StudioProject _sample({String id = 'p1'}) {
  return StudioProject(
    id: id,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
    prompt: 'A calm budgeting app',
    productUrl: '',
    productNotes: 'A calm budgeting app',
    step: StudioStep.gallery,
    brief: BrandBrief.fallback(notes: 'A calm budgeting app'),
    selectedConceptName: 'Pip',
    candidates: [
      StoredCandidate(conceptName: 'Pip', sheetBlobId: '$id/pip/sheet'),
    ],
  );
}

void main() {
  test('memory archive roundtrips projects and blobs', () async {
    final archive = MemoryStudioArchive();
    final project = _sample();
    final blobId = await archive.putBlob(_png, id: 'p1/pip/sheet');
    await archive.saveProject(project);
    await archive.setLastSessionId(project.id);

    final listed = await archive.listProjects();
    expect(listed, hasLength(1));
    expect(listed.first.displayName, contains('Pip'));
    expect(await archive.getBlob(blobId), _png);
    expect(await archive.lastSessionId(), 'p1');

    await archive.deleteProject('p1');
    expect(await archive.listProjects(), isEmpty);
    expect(await archive.getBlob(blobId), isNull);
    expect(await archive.lastSessionId(), isNull);
  });

  test('memory archive reports quota errors', () async {
    final archive = MemoryStudioArchive(quotaExceeded: true);
    expect(
      () => archive.putBlob(_png),
      throwsA(
        isA<ArchiveException>().having(
          (error) => error.quotaExceeded,
          'quotaExceeded',
          isTrue,
        ),
      ),
    );
  });

  test('idb memory factory roundtrips projects and blobs', () async {
    final archive = IdbStudioArchive(
      newIdbFactoryMemory(),
      dbName: 'archive-test',
    );
    final project = _sample(id: 'p2');
    await archive.putBlob(_png, id: 'p2/pip/sheet');
    await archive.saveProject(project);
    await archive.setLastSessionId('p2');

    final loaded = await archive.getProject('p2');
    expect(loaded?.prompt, 'A calm budgeting app');
    expect(await archive.getBlob('p2/pip/sheet'), _png);
    expect(await archive.lastSessionId(), 'p2');

    final listed = await archive.listProjects();
    expect(listed.single.id, 'p2');
  });
}
