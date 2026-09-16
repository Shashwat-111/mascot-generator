import 'dart:typed_data';

import 'package:mascot_studio/models/studio_project.dart';
import 'package:mascot_studio/service/studio_archive.dart';

class MemoryStudioArchive implements StudioArchive {
  MemoryStudioArchive({this.quotaExceeded = false});

  final Map<String, StudioProject> projects = {};
  final Map<String, Uint8List> blobs = {};
  String? sessionId;
  bool quotaExceeded;
  var _blobSeq = 0;

  void _guardWrite() {
    if (quotaExceeded) {
      throw const ArchiveException(
        'This browser is out of space. Delete a project to keep going.',
        quotaExceeded: true,
      );
    }
  }

  @override
  Future<List<StudioProject>> listProjects() async {
    return projects.values.toList();
  }

  @override
  Future<StudioProject?> getProject(String id) async => projects[id];

  @override
  Future<void> saveProject(StudioProject project) async {
    _guardWrite();
    projects[project.id] = project;
  }

  @override
  Future<void> deleteProject(String id) async {
    final project = projects.remove(id);
    if (project == null) return;
    for (final blobId in project.blobIds) {
      blobs.remove(blobId);
    }
    if (sessionId == id) sessionId = null;
  }

  @override
  Future<String> putBlob(Uint8List bytes, {String? id}) async {
    _guardWrite();
    final blobId = id ?? 'mem_${_blobSeq++}';
    blobs[blobId] = Uint8List.fromList(bytes);
    return blobId;
  }

  @override
  Future<Uint8List?> getBlob(String id) async {
    final bytes = blobs[id];
    if (bytes == null) return null;
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> deleteBlob(String id) async {
    blobs.remove(id);
  }

  @override
  Future<String?> lastSessionId() async => sessionId;

  @override
  Future<void> setLastSessionId(String? id) async {
    sessionId = id;
  }
}
