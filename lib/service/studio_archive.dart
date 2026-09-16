import 'dart:typed_data';

import 'package:mascot_studio/models/studio_project.dart';

class ArchiveException implements Exception {
  const ArchiveException(this.message, {this.quotaExceeded = false});

  final String message;
  final bool quotaExceeded;

  @override
  String toString() => message;
}

abstract class StudioArchive {
  Future<List<StudioProject>> listProjects();

  Future<StudioProject?> getProject(String id);

  Future<void> saveProject(StudioProject project);

  Future<void> deleteProject(String id);

  Future<String> putBlob(Uint8List bytes, {String? id});

  Future<Uint8List?> getBlob(String id);

  Future<void> deleteBlob(String id);

  Future<String?> lastSessionId();

  Future<void> setLastSessionId(String? id);
}

bool looksLikeQuotaError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('quota') ||
      text.contains('exceeded') ||
      text.contains('noroomerror');
}
