import 'dart:typed_data';

import 'package:idb_shim/idb.dart';
import 'package:mascot_studio/models/studio_project.dart';
import 'package:mascot_studio/service/studio_archive.dart';

class IdbStudioArchive implements StudioArchive {
  IdbStudioArchive(this._factory, {this.dbName = 'mascot_studio'});

  final IdbFactory _factory;
  final String dbName;
  Database? _db;
  var _blobSeq = 0;

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final db = await _factory.open(
      dbName,
      version: 1,
      onUpgradeNeeded: (event) {
        final database = event.database;
        if (!database.objectStoreNames.contains('projects')) {
          database.createObjectStore('projects', keyPath: 'id');
        }
        if (!database.objectStoreNames.contains('blobs')) {
          database.createObjectStore('blobs', keyPath: 'id');
        }
        if (!database.objectStoreNames.contains('meta')) {
          database.createObjectStore('meta', keyPath: 'key');
        }
      },
    );
    _db = db;
    return db;
  }

  Future<T> _run<T>(
    String storeName,
    String mode,
    Future<T> Function(ObjectStore store) body,
  ) async {
    try {
      final db = await _open();
      final txn = db.transaction(storeName, mode);
      final result = await body(txn.objectStore(storeName));
      await txn.completed;
      return result;
    } catch (error) {
      if (looksLikeQuotaError(error)) {
        throw const ArchiveException(
          'This browser is out of space. Delete a project to keep going.',
          quotaExceeded: true,
        );
      }
      throw ArchiveException('$error');
    }
  }

  @override
  Future<List<StudioProject>> listProjects() async {
    try {
      final db = await _open();
      final txn = db.transaction('projects', idbModeReadOnly);
      final rows = await txn.objectStore('projects').getAll();
      await txn.completed;
      return [
        for (final row in rows)
          if (row is Map) StudioProject.fromJson(_asMap(row)),
      ];
    } catch (error) {
      throw ArchiveException('$error');
    }
  }

  @override
  Future<StudioProject?> getProject(String id) async {
    final row = await _run<Object?>(
      'projects',
      idbModeReadOnly,
      (store) => store.getObject(id),
    );
    if (row is! Map) return null;
    return StudioProject.fromJson(_asMap(row));
  }

  @override
  Future<void> saveProject(StudioProject project) async {
    await _run<void>('projects', idbModeReadWrite, (store) async {
      await store.put(project.toJson());
    });
  }

  @override
  Future<void> deleteProject(String id) async {
    final project = await getProject(id);
    try {
      final db = await _open();
      final txn = db.transaction([
        'projects',
        'blobs',
        'meta',
      ], idbModeReadWrite);
      await txn.objectStore('projects').delete(id);
      if (project != null) {
        final blobs = txn.objectStore('blobs');
        for (final blobId in project.blobIds) {
          await blobs.delete(blobId);
        }
      }
      final last = await txn.objectStore('meta').getObject('lastSessionId');
      if (last is Map && last['value'] == id) {
        await txn.objectStore('meta').delete('lastSessionId');
      }
      await txn.completed;
    } catch (error) {
      if (looksLikeQuotaError(error)) {
        throw const ArchiveException(
          'This browser is out of space. Delete a project to keep going.',
          quotaExceeded: true,
        );
      }
      throw ArchiveException('$error');
    }
  }

  @override
  Future<String> putBlob(Uint8List bytes, {String? id}) async {
    final blobId =
        id ?? 'b_${DateTime.now().microsecondsSinceEpoch}_${_blobSeq++}';
    await _run<void>('blobs', idbModeReadWrite, (store) async {
      await store.put({'id': blobId, 'bytes': bytes});
    });
    return blobId;
  }

  @override
  Future<Uint8List?> getBlob(String id) async {
    final row = await _run<Object?>(
      'blobs',
      idbModeReadOnly,
      (store) => store.getObject(id),
    );
    if (row is! Map) return null;
    return _bytes(row['bytes']);
  }

  @override
  Future<void> deleteBlob(String id) async {
    await _run<void>('blobs', idbModeReadWrite, (store) async {
      await store.delete(id);
    });
  }

  @override
  Future<String?> lastSessionId() async {
    final row = await _run<Object?>(
      'meta',
      idbModeReadOnly,
      (store) => store.getObject('lastSessionId'),
    );
    if (row is Map) {
      final value = row['value'];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  Future<void> setLastSessionId(String? id) async {
    await _run<void>('meta', idbModeReadWrite, (store) async {
      if (id == null || id.isEmpty) {
        await store.delete('lastSessionId');
      } else {
        await store.put({'key': 'lastSessionId', 'value': id});
      }
    });
  }
}

Map<String, dynamic> _asMap(Map value) {
  if (value is Map<String, dynamic>) return value;
  return value.map((key, item) => MapEntry('$key', item));
}

Uint8List? _bytes(Object? value) {
  if (value is Uint8List) return Uint8List.fromList(value);
  if (value is List<int>) return Uint8List.fromList(value);
  if (value is List) {
    return Uint8List.fromList([
      for (final item in value)
        if (item is int) item,
    ]);
  }
  return null;
}
