import 'dart:convert';
import 'dart:typed_data';

import 'package:googleai_dart/googleai_dart.dart';
import 'package:http/http.dart' as http;
import 'package:mascot_studio/models/brand_brief.dart';
import 'package:mascot_studio/service/studio_ai.dart';
import 'package:mascot_studio/utils/prompts.dart';

class GeminiService implements StudioAi {
  GeminiService(this.apiKey)
    : _client = GoogleAIClient(
        config: GoogleAIConfig.googleAI(
          authProvider: ApiKeyProvider(apiKey),
          timeout: const Duration(minutes: 8),
        ),
      );

  final String apiKey;
  final GoogleAIClient _client;

  static const textModels = [
    'gemini-3.5-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ];

  static const imageModels = [
    'gemini-3.1-flash-image',
    'gemini-2.5-flash-image',
    'gemini-3-pro-image',
  ];

  static const videoModels = [
    'gemini-omni-1.1-flash',
    'gemini-omni-flash-preview',
  ];

  static const veoModels = [
    'veo-3.1-fast-generate-preview',
    'veo-3.1-lite-generate-preview',
    'veo-3.1-generate-preview',
  ];

  @override
  void close() => _client.close();

  @override
  Future<BrandBrief> analyzeBrand({String? url, required String notes}) async {
    final pageNotes = await _readPage(url: url, notes: notes);
    final json = await _structuredBrief(notes: pageNotes, url: url);
    if (!_hasFourConcepts(json)) {
      throw StateError('Gemini did not return four mascot concepts.');
    }
    return BrandBrief.fromJson(json, notes: pageNotes, url: url);
  }

  Future<String> _readPage({String? url, required String notes}) async {
    if (url == null || url.trim().isEmpty) return notes;
    try {
      final summary = await _firstText(
        prompt: websiteSummaryPrompt(url: url, notes: notes),
        tools: const [Tool(urlContext: UrlContext())],
      );
      if (summary.trim().isEmpty) return notes;
      return [
        notes.trim(),
        'Website notes:',
        summary.trim(),
      ].where((part) => part.isNotEmpty).join('\n\n');
    } catch (_) {
      return notes;
    }
  }

  Future<Map<String, dynamic>> _structuredBrief({
    required String notes,
    String? url,
  }) async {
    Object? lastError;
    for (final model in textModels) {
      try {
        final response = await _client.models.generateContent(
          model: model,
          request: GenerateContentRequest(
            contents: [
              Content.text(brandAnalysisPrompt(notes: notes, url: url)),
            ],
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
              responseSchema: brandBriefSchema.toJson(),
            ),
          ),
        );
        final json = _jsonFromResponse(response);
        if (json != null && _hasFourConcepts(json)) return json;
        lastError = StateError('Structured brief was empty.');
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? StateError('Could not build a brand brief.');
  }

  @override
  Future<Uint8List> generateImage({
    required String prompt,
    List<Uint8List> references = const [],
    String aspectRatio = '1:1',
  }) async {
    Object? lastError;
    for (final model in imageModels) {
      try {
        final response = await _client.models.generateContent(
          model: model,
          request: GenerateContentRequest(
            contents: [
              Content.fromParts([
                prompt,
                for (final bytes in references) Part.bytes(bytes, 'image/png'),
              ]),
            ],
            generationConfig: GenerationConfig(
              responseModalities: const [
                ResponseModality.text,
                ResponseModality.image,
              ],
              imageConfig: ImageConfig(aspectRatio: aspectRatio),
            ),
          ),
        );
        final bytes = _imageFromResponse(response);
        if (bytes != null) return bytes;
        lastError = StateError('The image model returned text only.');
      } catch (error) {
        lastError = error;
        if (_isQuotaError(error)) break;
      }
    }
    throw lastError ?? StateError('No image model available.');
  }

  bool _isQuotaError(Object error) {
    final text = error.toString();
    return text.contains('RESOURCE_EXHAUSTED') ||
        text.contains('429') ||
        text.contains('quota');
  }

  @override
  Future<Uint8List> animateMascot({
    required String prompt,
    required Uint8List reference,
  }) async {
    try {
      return await _animateWithOmni(prompt: prompt, reference: reference);
    } catch (_) {
      return _animateWithVeo(prompt: prompt, reference: reference);
    }
  }

  Future<Uint8List> _animateWithOmni({
    required String prompt,
    required Uint8List reference,
  }) async {
    Object? lastError;
    for (final model in videoModels) {
      try {
        var interaction = await _client.interactions.create(
          model: model,
          input: InteractionInput.contentList([
            ImageContent(data: base64Encode(reference), mimeType: 'image/png'),
            TextContent(text: prompt),
          ]),
          generationConfig: const InteractionGenerationConfig(
            videoConfig: InteractionVideoConfig(
              task: InteractionVideoConfigTask.imageToVideo,
            ),
          ),
          responseFormat: const InteractionResponseFormatConfig.single(
            InteractionVideoResponseFormat(
              aspectRatio: InteractionVideoResponseFormatAspectRatio.ratio9x16,
              delivery: InteractionVideoResponseFormatDelivery.inline,
              duration: '${mascotClipDurationSeconds}s',
            ),
          ),
          background: true,
        );
        interaction = await _awaitInteraction(interaction);
        final video = interaction.outputVideo;
        if (video?.data != null) {
          return Uint8List.fromList(base64Decode(video!.data!));
        }
        if (video?.uri != null) {
          return _downloadBinary(video!.uri!);
        }
        lastError = StateError('Omni returned no video.');
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? StateError('Omni video failed.');
  }

  Future<Uint8List> _animateWithVeo({
    required String prompt,
    required Uint8List reference,
  }) async {
    Object? lastError;
    for (final model in veoModels) {
      try {
        var operation = await _client.models.predictLongRunning(
          model: model,
          instances: [
            {
              'prompt': prompt,
              'image': {
                'bytesBase64Encoded': base64Encode(reference),
                'mimeType': 'image/png',
              },
            },
          ],
          parameters: {
            'aspectRatio': '9:16',
            'durationSeconds': mascotClipDurationSeconds,
          },
        );

        final name = operation.name;
        var attempts = 0;
        while (!operation.done && name != null && attempts < 40) {
          await Future<void>.delayed(const Duration(seconds: 5));
          final raw = await _client.getOperation(name: name);
          operation = PredictLongRunningOperation.fromJson({
            'name': raw.name,
            'done': raw.done,
            if (raw.error != null) 'error': raw.error!.toJson(),
            if (raw.response != null) 'response': raw.response,
          });
          attempts++;
        }
        if (!operation.done) {
          throw StateError('Video is still rendering. Try again in a moment.');
        }
        if (operation.error != null) {
          throw StateError(operation.error!.message);
        }

        final samples =
            operation.response?.generateVideoResponse?.generatedSamples ?? [];
        for (final sample in samples) {
          final video = sample.video;
          if (video?.video != null) {
            return Uint8List.fromList(base64Decode(video!.video!));
          }
          if (video?.uri != null) {
            return _downloadBinary(video!.uri!);
          }
        }
        lastError = StateError('Veo returned no video bytes.');
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? StateError('Video generation failed.');
  }

  Future<String> _firstText({required String prompt, List<Tool>? tools}) async {
    Object? lastError;
    for (final model in textModels) {
      try {
        final response = await _client.models.generateContent(
          model: model,
          request: GenerateContentRequest(
            contents: [Content.text(prompt)],
            tools: tools,
            generationConfig: const GenerationConfig(),
          ),
        );
        final text = _visibleText(response);
        if (text == null || text.trim().isEmpty) {
          throw StateError('Empty model response.');
        }
        return text;
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? StateError('No text model available.');
  }

  Future<Interaction> _awaitInteraction(Interaction interaction) async {
    var current = interaction;
    var attempts = 0;
    while (current.status == InteractionStatus.inProgress && attempts < 40) {
      await Future<void>.delayed(const Duration(seconds: 5));
      current = await _client.interactions.get(current.id);
      attempts++;
    }
    if (current.status == InteractionStatus.failed) {
      throw StateError('Omni video failed.');
    }
    if (current.status != InteractionStatus.completed) {
      throw StateError('Video is still rendering. Try again in a moment.');
    }
    return current;
  }

  bool _hasFourConcepts(Map<String, dynamic> json) {
    final raw = [
      ..._asList(json['concepts']),
      ..._asList(json['candidates']),
      ..._asList(json['mascots']),
    ];
    return raw.length >= 4;
  }

  List<dynamic> _asList(Object? value) {
    if (value is List) return value;
    if (value is Map) return [value];
    return const [];
  }

  Future<Uint8List> _downloadBinary(String uri) async {
    final parsed = Uri.parse(uri);
    final withKey = parsed.replace(
      queryParameters: {...parsed.queryParameters, 'key': apiKey},
    );
    final response = await http.get(
      withKey,
      headers: {'x-goog-api-key': apiKey},
    );
    if (response.statusCode >= 400) {
      throw StateError('Could not download generated media.');
    }
    return response.bodyBytes;
  }

  Map<String, dynamic>? _jsonFromResponse(GenerateContentResponse response) {
    final text = _visibleText(response);
    if (text == null) return null;
    return _parseJson(text);
  }

  String? _visibleText(GenerateContentResponse response) {
    final buffer = StringBuffer();
    for (final part in response.allParts) {
      if (part is TextPart &&
          part.thought != true &&
          part.text.trim().isNotEmpty) {
        buffer.write(part.text);
      }
    }
    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  Uint8List? _imageFromResponse(GenerateContentResponse response) {
    final data = response.data;
    if (data != null && data.isNotEmpty) {
      return Uint8List.fromList(base64Decode(data));
    }
    for (final part in response.allParts) {
      if (part is InlineDataPart && part.inlineData.data.isNotEmpty) {
        return Uint8List.fromList(base64Decode(part.inlineData.data));
      }
    }
    return null;
  }

  Map<String, dynamic>? _parseJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text
          .replaceFirst(RegExp(r'^```(?:json)?'), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {}
    return null;
  }
}
