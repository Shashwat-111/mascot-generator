import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:googleai_dart/googleai_dart.dart';
import 'package:mascot_studio/models/brand_brief.dart';
import 'package:mascot_studio/models/mascot_action.dart';
import 'package:mascot_studio/models/mascot_candidate.dart';
import 'package:mascot_studio/models/studio_project.dart';
import 'package:mascot_studio/models/studio_step.dart';
import 'package:mascot_studio/service/dummy_studio_ai.dart';
import 'package:mascot_studio/service/gemini_service.dart';
import 'package:mascot_studio/service/generation_mode.dart';
import 'package:mascot_studio/service/memory_studio_archive.dart';
import 'package:mascot_studio/service/studio_ai.dart';
import 'package:mascot_studio/service/studio_archive.dart';
import 'package:mascot_studio/utils/pack.dart';
import 'package:mascot_studio/utils/prompt_input.dart';
import 'package:mascot_studio/utils/prompts.dart';

export 'package:mascot_studio/models/studio_step.dart';

class StudioController extends ChangeNotifier {
  StudioController({
    String? initialApiKey,
    StudioAi? ai,
    bool? useLiveGemini,
    StudioArchive? archive,
  }) : apiKey = initialApiKey ?? '',
       useLiveGemini = useLiveGemini ?? kUseLiveGemini,
       archive = archive ?? MemoryStudioArchive(),
       _injectedAi = ai != null {
    _ai = ai ?? _createAi();
  }

  final bool useLiveGemini;
  final StudioArchive archive;
  String apiKey;
  String prompt = '';
  String productUrl = '';
  String productNotes = '';
  StudioStep step = StudioStep.welcome;
  String status = '';
  String? error;
  bool busy = false;
  String? pendingActionId;

  BrandBrief? brief;
  final List<MascotCandidate?> slots = [];
  MascotCandidate? selected;
  final Map<String, Uint8List> videos = {};
  String? activeVideoId;
  String? projectId;
  DateTime? projectCreatedAt;
  List<StudioProject> library = [];
  final Map<String, Uint8List> thumbnails = {};

  List<MascotCandidate> get candidates => [for (final slot in slots) ?slot];

  StudioProject? get latestProject {
    if (library.isEmpty) return null;
    return library.first;
  }

  StudioAi? _ai;
  final bool _injectedAi;
  var _projectSeq = 0;
  var _closed = false;

  bool get hasKey => apiKey.trim().isNotEmpty;

  StudioAi? _createAi() {
    if (!useLiveGemini) return DummyStudioAi();
    if (hasKey) return GeminiService(apiKey);
    return null;
  }

  void _prepareAi() {
    if (_injectedAi) return;
    _ai?.close();
    _ai = _createAi();
  }

  Future<void> bootstrap() async {
    await refreshLibrary();
    final last = await archive.lastSessionId();
    if (last == null) return;
    final saved = library.where((item) => item.id == last).firstOrNull;
    if (saved == null) return;
    if (saved.step == StudioStep.welcome ||
        saved.step == StudioStep.analyzing) {
      return;
    }
    await openProject(last);
  }

  Future<void> refreshLibrary() async {
    final items = await archive.listProjects();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    library = items;
    thumbnails.clear();
    for (final project in library) {
      final blobId = project.thumbnailBlobId;
      if (blobId == null) continue;
      final bytes = await archive.getBlob(blobId);
      if (bytes != null) thumbnails[project.id] = bytes;
    }
    notifyListeners();
  }

  void applyPrompt(String value) {
    prompt = value;
    final (:url, :notes) = parseProductPrompt(value);
    productUrl = url;
    productNotes = notes;
  }

  Future<void> startBriefing() async {
    if (prompt.trim().isNotEmpty) {
      applyPrompt(prompt);
    }
    if (!_injectedAi && useLiveGemini && !hasKey) {
      error = 'Missing GEMINI_API_KEY in .env.';
      notifyListeners();
      return;
    }
    if (productUrl.trim().isEmpty && productNotes.trim().isEmpty) {
      error = 'Paste a landing page or tell us what the product does.';
      notifyListeners();
      return;
    }

    if (projectId != null && brief != null) {
      await persist();
    }
    _clearSession(keepPrompt: true);

    busy = true;
    error = null;
    status = 'Reading the brand…';
    step = StudioStep.analyzing;
    notifyListeners();

    try {
      _prepareAi();
      brief = await _ai!.analyzeBrand(
        url: productUrl.trim().isEmpty ? null : productUrl.trim(),
        notes: productNotes,
      );
      projectId = _newProjectId();
      projectCreatedAt = DateTime.now();
      await persist();
    } catch (err) {
      error = _friendly(err);
      step = StudioStep.welcome;
      busy = false;
      notifyListeners();
      return;
    }

    await drawPalettes();
  }

  Future<void> drawPalettes() async {
    final current = brief;
    if (current == null || _ai == null) return;

    busy = true;
    error = null;
    slots
      ..clear()
      ..addAll(List<MascotCandidate?>.filled(current.concepts.length, null));
    step = StudioStep.drawing;
    notifyListeners();

    try {
      await Future.wait([
        for (var i = 0; i < current.concepts.length; i++) _drawSlot(current, i),
      ]);
      if (candidates.isEmpty) {
        throw StateError('None of the palettes rendered. Try again.');
      }
      step = StudioStep.gallery;
      await persist();
    } catch (err) {
      error = _friendly(err);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _drawSlot(BrandBrief current, int index) async {
    final concept = current.concepts[index];
    status = 'Drawing ${concept.name}…';
    notifyListeners();
    final result = await _drawOne(current, concept);
    if (index < slots.length) {
      slots[index] = result;
      notifyListeners();
      await persist();
    }
  }

  Future<MascotCandidate?> _drawOne(
    BrandBrief current,
    MascotConcept concept,
  ) async {
    try {
      final sheet = await _ai!.generateImage(
        prompt: paletteSheetPrompt(brief: current, concept: concept),
        aspectRatio: '1:1',
      );
      return MascotCandidate(concept: concept, sheetBytes: sheet);
    } catch (_) {
      return null;
    }
  }

  Future<void> selectCandidate(MascotCandidate candidate) async {
    final same = selected?.concept.name == candidate.concept.name;
    selected = candidate;
    step = StudioStep.studio;
    if (!same) {
      videos.clear();
      activeVideoId = null;
      await _loadVideosFor(candidate.concept.name);
    }
    notifyListeners();
    if (selected?.heroBytes == null) {
      await isolateHero();
    } else {
      await persist();
    }
  }

  Future<void> isolateHero() async {
    final current = brief;
    final pick = selected;
    if (current == null || pick == null || _ai == null) return;
    if (pick.heroBytes != null) return;

    busy = true;
    status = 'Locking ${pick.concept.name} as the hero…';
    notifyListeners();
    try {
      final hero = await _ai!.generateImage(
        prompt: isolatedHeroPrompt(brief: current, concept: pick.concept),
        references: [pick.sheetBytes],
        aspectRatio: '1:1',
      );
      selected = pick.copyWith(heroBytes: hero);
      _replaceSelectedSlot();
    } catch (err) {
      error = _friendly(err);
    } finally {
      busy = false;
      notifyListeners();
      await persist();
    }
  }

  Future<void> generatePosePack() async {
    final current = brief;
    final pick = selected;
    if (current == null || pick == null || _ai == null) return;

    busy = true;
    error = null;
    status = 'Making a few stills…';
    notifyListeners();
    try {
      final poses = <String, Uint8List>{};
      for (final entry in posePack.entries) {
        status = 'Posing: ${entry.key}…';
        notifyListeners();
        poses[entry.key] = await _ai!.generateImage(
          prompt: posePrompt(
            brief: current,
            concept: pick.concept,
            pose: entry.value,
          ),
          references: [pick.referenceBytes],
          aspectRatio: '1:1',
        );
      }
      selected = pick.copyWith(poses: poses, heroBytes: pick.heroBytes);
      _replaceSelectedSlot();
    } catch (err) {
      error = _friendly(err);
    } finally {
      busy = false;
      notifyListeners();
      await persist();
    }
  }

  void playClip(String actionId) {
    if (!videos.containsKey(actionId)) return;
    activeVideoId = actionId;
    notifyListeners();
    unawaited(persist());
  }

  void showStill() {
    if (activeVideoId == null) return;
    activeVideoId = null;
    notifyListeners();
  }

  Future<void> animate(MascotAction action, {bool remake = false}) async {
    if (videos.containsKey(action.id) && !remake) {
      playClip(action.id);
      return;
    }

    final current = brief;
    final pick = selected;
    if (current == null || pick == null || _ai == null) return;

    busy = true;
    error = null;
    pendingActionId = action.id;
    status = '${action.label}… this takes a moment.';
    notifyListeners();
    try {
      final bytes = await _ai!.animateMascot(
        prompt: videoPrompt(
          brief: current,
          concept: pick.concept,
          motion: action.motionPrompt,
        ),
        reference: pick.referenceBytes,
      );
      videos[action.id] = bytes;
      activeVideoId = action.id;
    } catch (err) {
      error = _friendly(err);
    } finally {
      pendingActionId = null;
      busy = false;
      notifyListeners();
      await persist();
    }
  }

  Future<void> downloadPack() async {
    final current = brief;
    final pick = selected;
    if (current == null || pick == null) return;
    await downloadMascotPack(brief: current, candidate: pick, videos: videos);
  }

  void backToGallery() {
    if (step == StudioStep.drawing) return;
    step = StudioStep.gallery;
    notifyListeners();
    unawaited(persist());
  }

  void showLanding() {
    if (step == StudioStep.analyzing) return;
    step = StudioStep.welcome;
    notifyListeners();
  }

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  void showLibrary() {
    if (step == StudioStep.analyzing) return;
    step = StudioStep.library;
    notifyListeners();
    unawaited(refreshLibrary());
    unawaited(persist());
  }

  Future<void> newMascot() async {
    await persist();
    _clearSession();
    step = StudioStep.welcome;
    error = null;
    status = '';
    await archive.setLastSessionId(null);
    await refreshLibrary();
    notifyListeners();
  }

  void reset() {
    _clearSession();
    step = StudioStep.welcome;
    error = null;
    status = '';
    notifyListeners();
  }

  Future<void> openProject(String id, {StudioStep? toStep}) async {
    final project = await archive.getProject(id);
    if (project == null) {
      step = StudioStep.library;
      notifyListeners();
      return;
    }

    _clearSession();
    projectId = project.id;
    projectCreatedAt = project.createdAt;
    prompt = project.prompt;
    productUrl = project.productUrl;
    productNotes = project.productNotes;
    brief = project.brief;
    activeVideoId = project.activeVideoId;

    final concepts = project.brief?.concepts ?? const <MascotConcept>[];
    slots.addAll(List<MascotCandidate?>.filled(concepts.length, null));
    for (var i = 0; i < concepts.length; i++) {
      final concept = concepts[i];
      final stored = project.candidateNamed(concept.name);
      if (stored == null) continue;
      final sheet = await archive.getBlob(stored.sheetBlobId);
      if (sheet == null) continue;
      Uint8List? hero;
      if (stored.heroBlobId != null) {
        hero = await archive.getBlob(stored.heroBlobId!);
      }
      final poses = <String, Uint8List>{};
      for (final entry in stored.poseBlobIds.entries) {
        final bytes = await archive.getBlob(entry.value);
        if (bytes != null) poses[entry.key] = bytes;
      }
      slots[i] = MascotCandidate(
        concept: concept,
        sheetBytes: sheet,
        heroBytes: hero,
        poses: poses,
      );
    }

    if (project.selectedConceptName != null) {
      selected = candidates
          .where((item) => item.concept.name == project.selectedConceptName)
          .firstOrNull;
    }

    var next = toStep ?? project.step;
    if (next == StudioStep.analyzing || next == StudioStep.drawing) {
      next = candidates.isEmpty ? StudioStep.welcome : StudioStep.gallery;
    }
    if (next == StudioStep.studio && selected == null) {
      next = StudioStep.gallery;
    }
    if (next == StudioStep.studio && selected != null) {
      await _loadVideosFor(selected!.concept.name);
    }
    step = next;
    await archive.setLastSessionId(project.id);
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    await archive.deleteProject(id);
    if (projectId == id) {
      _clearSession();
      step = StudioStep.library;
    }
    await refreshLibrary();
  }

  Future<void> applyPath(String path) async {
    final normalized = path.isEmpty ? '/' : path;
    if (normalized == '/') {
      showLanding();
      return;
    }
    if (normalized == '/work') {
      showLibrary();
      return;
    }
    final studioMatch = RegExp(
      r'^/work/([^/]+)/studio/?$',
    ).firstMatch(normalized);
    if (studioMatch != null) {
      final id = studioMatch.group(1)!;
      if (projectId != id) {
        await openProject(id, toStep: StudioStep.studio);
      } else if (selected != null) {
        step = StudioStep.studio;
        notifyListeners();
      } else {
        backToGallery();
      }
      return;
    }
    final workMatch = RegExp(r'^/work/([^/]+)/?$').firstMatch(normalized);
    if (workMatch != null) {
      final id = workMatch.group(1)!;
      if (projectId != id) {
        await openProject(id, toStep: StudioStep.gallery);
      } else {
        backToGallery();
      }
    }
  }

  Future<void> persist() async {
    final currentBrief = brief;
    final id = projectId;
    if (currentBrief == null || id == null) return;

    try {
      final previous = await archive.getProject(id);
      final stored = <StoredCandidate>[];
      for (final slot in slots) {
        if (slot == null) continue;
        final concept = slot.concept.name;
        final sheetId = _blobKey(id, concept, 'sheet');
        await archive.putBlob(slot.sheetBytes, id: sheetId);
        String? heroId;
        if (slot.heroBytes != null) {
          heroId = _blobKey(id, concept, 'hero');
          await archive.putBlob(slot.heroBytes!, id: heroId);
        }
        final poses = <String, String>{};
        for (final entry in slot.poses.entries) {
          final poseId = _blobKey(id, concept, 'pose/${entry.key}');
          await archive.putBlob(entry.value, id: poseId);
          poses[entry.key] = poseId;
        }
        var videoIds =
            previous?.candidateNamed(concept)?.videoBlobIds ??
            const <String, String>{};
        if (selected?.concept.name == concept) {
          videoIds = {};
          for (final entry in videos.entries) {
            final videoId = _blobKey(id, concept, 'video/${entry.key}');
            await archive.putBlob(entry.value, id: videoId);
            videoIds[entry.key] = videoId;
          }
        }
        stored.add(
          StoredCandidate(
            conceptName: concept,
            sheetBlobId: sheetId,
            heroBlobId: heroId,
            poseBlobIds: poses,
            videoBlobIds: videoIds,
          ),
        );
      }

      final persistStep = switch (step) {
        StudioStep.welcome ||
        StudioStep.analyzing ||
        StudioStep.library => previous?.step ?? StudioStep.gallery,
        _ => step,
      };

      final project = StudioProject(
        id: id,
        createdAt: projectCreatedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: prompt,
        productUrl: productUrl,
        productNotes: productNotes,
        step: persistStep,
        brief: currentBrief,
        selectedConceptName: selected?.concept.name,
        activeVideoId: activeVideoId,
        candidates: stored,
      );
      await archive.saveProject(project);
      await archive.setLastSessionId(id);
      library = [
        project,
        for (final item in library)
          if (item.id != project.id) item,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final thumbId = project.thumbnailBlobId;
      if (thumbId != null) {
        final bytes = await archive.getBlob(thumbId);
        if (bytes != null) thumbnails[project.id] = bytes;
      }
      if (_closed) return;
      notifyListeners();
    } on ArchiveException catch (err) {
      if (_closed) return;
      error = err.message;
      notifyListeners();
    } catch (err) {
      if (_closed) return;
      if (looksLikeQuotaError(err)) {
        error = 'This browser is out of space. Delete a project to keep going.';
      } else {
        error = _friendly(err);
      }
      notifyListeners();
    }
  }

  Future<void> _loadVideosFor(String conceptName) async {
    final id = projectId;
    if (id == null) return;
    final project = await archive.getProject(id);
    final stored = project?.candidateNamed(conceptName);
    if (stored == null) return;
    videos.clear();
    for (final entry in stored.videoBlobIds.entries) {
      final bytes = await archive.getBlob(entry.value);
      if (bytes != null) videos[entry.key] = bytes;
    }
    if (activeVideoId == null || !videos.containsKey(activeVideoId)) {
      activeVideoId = videos.keys.firstOrNull;
    }
  }

  void _replaceSelectedSlot() {
    final pick = selected;
    if (pick == null) return;
    for (var i = 0; i < slots.length; i++) {
      if (slots[i]?.concept.name == pick.concept.name) {
        slots[i] = pick;
        return;
      }
    }
  }

  void _clearSession({bool keepPrompt = false}) {
    if (!keepPrompt) {
      prompt = '';
      productUrl = '';
      productNotes = '';
    }
    brief = null;
    selected = null;
    slots.clear();
    videos.clear();
    activeVideoId = null;
    projectId = null;
    projectCreatedAt = null;
    pendingActionId = null;
    busy = false;
    status = '';
  }

  String _newProjectId() {
    return 'p_${DateTime.now().microsecondsSinceEpoch}_${_projectSeq++}';
  }

  String _blobKey(String id, String concept, String kind) {
    final slug = concept
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return '$id/$slug/$kind';
  }

  String _friendly(Object err) {
    if (err is ArchiveException) return err.message;
    if (err is ApiException) {
      return _shortApiMessage(err.message, err.statusCode);
    }
    final text = err.toString();
    if (text.contains('{') || text.contains('```')) {
      return 'Gemini returned extra text instead of a clean result. Try that step again.';
    }
    if (text.contains('API_KEY') ||
        text.contains('403') ||
        text.contains('401')) {
      return 'The Gemini key in .env was rejected. Check it in AI Studio.';
    }
    if (text.contains('CORS') || text.contains('Failed to fetch')) {
      return 'The browser blocked a Google API call. Try a restart, or we can add a tiny proxy.';
    }
    return text
        .replaceFirst(RegExp(r'^Exception: '), '')
        .replaceFirst(RegExp(r'^StateError: '), '')
        .replaceFirst(RegExp(r'^ApiException\(\d+\): '), '');
  }

  String _shortApiMessage(String message, int statusCode) {
    if (message.contains('JSON') ||
        message.contains('parse') ||
        message.contains('schema') ||
        message.contains('MALFORMED')) {
      return 'Gemini did not return a full mascot brief, so we completed the missing parts.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'The Gemini key in .env was rejected. Check it in AI Studio.';
    }
    final firstLine = message.split('\n').first.trim();
    if (firstLine.length > 160) {
      return 'Gemini hit a $statusCode error. Try again with a short product description.';
    }
    return firstLine;
  }

  @override
  void dispose() {
    _closed = true;
    _ai?.close();
    super.dispose();
  }
}
