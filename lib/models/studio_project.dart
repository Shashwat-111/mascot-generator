import 'package:mascot_studio/models/brand_brief.dart';
import 'package:mascot_studio/models/studio_step.dart';

class StoredCandidate {
  const StoredCandidate({
    required this.conceptName,
    required this.sheetBlobId,
    this.heroBlobId,
    this.poseBlobIds = const {},
    this.videoBlobIds = const {},
  });

  final String conceptName;
  final String sheetBlobId;
  final String? heroBlobId;
  final Map<String, String> poseBlobIds;
  final Map<String, String> videoBlobIds;

  int get stillCount => 1 + (heroBlobId == null ? 0 : 1) + poseBlobIds.length;

  int get clipCount => videoBlobIds.length;

  Iterable<String> get blobIds sync* {
    yield sheetBlobId;
    if (heroBlobId != null) yield heroBlobId!;
    yield* poseBlobIds.values;
    yield* videoBlobIds.values;
  }

  StoredCandidate copyWith({
    String? heroBlobId,
    Map<String, String>? poseBlobIds,
    Map<String, String>? videoBlobIds,
  }) {
    return StoredCandidate(
      conceptName: conceptName,
      sheetBlobId: sheetBlobId,
      heroBlobId: heroBlobId ?? this.heroBlobId,
      poseBlobIds: poseBlobIds ?? this.poseBlobIds,
      videoBlobIds: videoBlobIds ?? this.videoBlobIds,
    );
  }

  factory StoredCandidate.fromJson(Map<String, dynamic> json) {
    return StoredCandidate(
      conceptName: json['conceptName'] as String? ?? 'Pip',
      sheetBlobId: json['sheetBlobId'] as String? ?? '',
      heroBlobId: json['heroBlobId'] as String?,
      poseBlobIds: _stringMap(json['poseBlobIds']),
      videoBlobIds: _stringMap(json['videoBlobIds']),
    );
  }

  Map<String, dynamic> toJson() => {
    'conceptName': conceptName,
    'sheetBlobId': sheetBlobId,
    'heroBlobId': heroBlobId,
    'poseBlobIds': poseBlobIds,
    'videoBlobIds': videoBlobIds,
  };
}

class StudioProject {
  const StudioProject({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.prompt,
    required this.productUrl,
    required this.productNotes,
    required this.step,
    this.brief,
    this.selectedConceptName,
    this.activeVideoId,
    this.candidates = const [],
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String prompt;
  final String productUrl;
  final String productNotes;
  final StudioStep step;
  final BrandBrief? brief;
  final String? selectedConceptName;
  final String? activeVideoId;
  final List<StoredCandidate> candidates;

  String get productName => brief?.productName ?? '';

  String get displayName {
    final mascot = selectedConceptName ?? candidates.firstOrNull?.conceptName;
    final product = productName;
    if (mascot != null && mascot.isNotEmpty && product.isNotEmpty) {
      return '$mascot for $product';
    }
    if (product.isNotEmpty) return product;
    if (mascot != null && mascot.isNotEmpty) return mascot;
    final trimmed = prompt.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'Untitled mascot';
  }

  int get stillCount =>
      candidates.fold<int>(0, (sum, item) => sum + item.stillCount);

  int get clipCount =>
      candidates.fold<int>(0, (sum, item) => sum + item.clipCount);

  String get statsLabel {
    final stills = stillCount;
    final clips = clipCount;
    return '$stills ${stills == 1 ? 'still' : 'stills'} · $clips ${clips == 1 ? 'clip' : 'clips'}';
  }

  String? get thumbnailBlobId {
    if (selectedConceptName != null) {
      final selected = candidateNamed(selectedConceptName!);
      if (selected != null) {
        return selected.heroBlobId ?? selected.sheetBlobId;
      }
    }
    return candidates.firstOrNull?.heroBlobId ??
        candidates.firstOrNull?.sheetBlobId;
  }

  StoredCandidate? candidateNamed(String name) {
    for (final candidate in candidates) {
      if (candidate.conceptName == name) return candidate;
    }
    return null;
  }

  Iterable<String> get blobIds sync* {
    for (final candidate in candidates) {
      yield* candidate.blobIds;
    }
  }

  StudioProject copyWith({
    DateTime? updatedAt,
    String? prompt,
    String? productUrl,
    String? productNotes,
    StudioStep? step,
    BrandBrief? brief,
    String? selectedConceptName,
    String? activeVideoId,
    List<StoredCandidate>? candidates,
    bool clearSelected = false,
    bool clearActiveVideo = false,
  }) {
    return StudioProject(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      prompt: prompt ?? this.prompt,
      productUrl: productUrl ?? this.productUrl,
      productNotes: productNotes ?? this.productNotes,
      step: step ?? this.step,
      brief: brief ?? this.brief,
      selectedConceptName: clearSelected
          ? null
          : (selectedConceptName ?? this.selectedConceptName),
      activeVideoId: clearActiveVideo
          ? null
          : (activeVideoId ?? this.activeVideoId),
      candidates: candidates ?? this.candidates,
    );
  }

  factory StudioProject.fromJson(Map<String, dynamic> json) {
    return StudioProject(
      id: json['id'] as String? ?? '',
      createdAt:
          _date(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _date(json['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      prompt: json['prompt'] as String? ?? '',
      productUrl: json['productUrl'] as String? ?? '',
      productNotes: json['productNotes'] as String? ?? '',
      step: studioStepFromName(json['step'] as String?),
      brief: json['brief'] is Map
          ? BrandBrief.fromJson(_asMap(json['brief'])!)
          : null,
      selectedConceptName: json['selectedConceptName'] as String?,
      activeVideoId: json['activeVideoId'] as String?,
      candidates: [
        for (final item in json['candidates'] as List? ?? const [])
          if (item is Map) StoredCandidate.fromJson(_asMap(item)!),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'prompt': prompt,
    'productUrl': productUrl,
    'productNotes': productNotes,
    'step': step.name,
    'brief': brief?.toJson(),
    'selectedConceptName': selectedConceptName,
    'activeVideoId': activeVideoId,
    'candidates': [for (final candidate in candidates) candidate.toJson()],
  };
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key != null && entry.value != null)
        '${entry.key}': '${entry.value}',
  };
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry('$key', item));
  }
  return null;
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
