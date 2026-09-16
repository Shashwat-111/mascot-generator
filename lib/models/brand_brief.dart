import 'package:googleai_dart/googleai_dart.dart';

class ColorSwatchInfo {
  const ColorSwatchInfo({required this.hex, required this.role});

  final String hex;
  final String role;

  String get normalizedHex {
    var value = hex.trim();
    if (value.isEmpty) return '#6B4EFF';
    if (!value.startsWith('#')) value = '#$value';
    if (value.length == 4) {
      final r = value[1];
      final g = value[2];
      final b = value[3];
      value = '#$r$r$g$g$b$b';
    }
    return value.toUpperCase();
  }

  factory ColorSwatchInfo.fromJson(Map<String, dynamic> json) {
    return ColorSwatchInfo(
      hex: _string(json['hex']) ?? '#6B4EFF',
      role: _string(json['role']) ?? 'accent',
    );
  }

  Map<String, dynamic> toJson() => {'hex': normalizedHex, 'role': role};
}

class MascotConcept {
  const MascotConcept({
    required this.name,
    required this.species,
    required this.personality,
    required this.identityLock,
    required this.whyItFits,
  });

  final String name;
  final String species;
  final String personality;
  final String identityLock;
  final String whyItFits;

  factory MascotConcept.fromJson(Map<String, dynamic> json) {
    final name = _string(json['name']) ?? 'Pip';
    final species = _string(json['species']) ?? 'round clay creature';
    final personality = _string(json['personality']) ?? 'warm and helpful';
    final lock =
        _string(json['identityLock']) ??
        _string(json['identity_lock']) ??
        'A cute 3D clay mascot named $name. Species: $species. Personality: $personality. Rounded forms, soft studio lighting, no text.';
    return MascotConcept(
      name: name,
      species: species,
      personality: personality,
      identityLock: lock,
      whyItFits:
          _string(json['whyItFits']) ??
          _string(json['why_it_fits']) ??
          personality,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'species': species,
    'personality': personality,
    'identityLock': identityLock,
    'whyItFits': whyItFits,
  };
}

class BrandBrief {
  const BrandBrief({
    required this.productName,
    required this.oneLiner,
    required this.audience,
    required this.tone,
    required this.palette,
    required this.concepts,
  });

  final String productName;
  final String oneLiner;
  final String audience;
  final String tone;
  final List<ColorSwatchInfo> palette;
  final List<MascotConcept> concepts;

  factory BrandBrief.fromJson(
    Map<String, dynamic> json, {
    String notes = '',
    String? url,
  }) {
    final productName =
        _string(json['productName']) ??
        _string(json['product_name']) ??
        _guessName(notes, url);

    final palette = <ColorSwatchInfo>[];
    for (final item in _asList(json['palette'])) {
      final map = _asMap(item);
      if (map != null) palette.add(ColorSwatchInfo.fromJson(map));
    }

    final concepts = <MascotConcept>[];
    final rawConcepts = [
      ..._asList(json['concepts']),
      ..._asList(json['candidates']),
      ..._asList(json['mascots']),
    ];
    for (final item in rawConcepts) {
      final map = _asMap(item);
      if (map != null) concepts.add(MascotConcept.fromJson(map));
    }

    return BrandBrief(
      productName: productName,
      oneLiner:
          _string(json['oneLiner']) ??
          _string(json['one_liner']) ??
          (notes.trim().isEmpty
              ? 'A friendly product mascot for $productName.'
              : notes.trim()),
      audience: _string(json['audience']) ?? 'people who use $productName',
      tone: _string(json['tone']) ?? 'friendly',
      palette: palette,
      concepts: concepts,
    ).completed();
  }

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'oneLiner': oneLiner,
    'audience': audience,
    'tone': tone,
    'palette': [for (final color in palette) color.toJson()],
    'concepts': [for (final concept in concepts) concept.toJson()],
  };

  factory BrandBrief.fallback({String notes = '', String? url}) {
    return BrandBrief.fromJson(const {}, notes: notes, url: url);
  }

  BrandBrief completed() {
    final name = productName.trim().isEmpty ? 'Your app' : productName.trim();
    return BrandBrief(
      productName: name,
      oneLiner: oneLiner.trim().isEmpty
          ? 'A friendly product mascot for $name.'
          : oneLiner,
      audience: audience.trim().isEmpty ? 'people who use $name' : audience,
      tone: tone.trim().isEmpty ? 'friendly' : tone,
      palette: palette.isEmpty ? _defaultPalette : palette.take(6).toList(),
      concepts: _fillConcepts(name, concepts),
    );
  }
}

const brandBriefSchema = Schema(
  type: SchemaType.object,
  properties: {
    'productName': Schema(type: SchemaType.string),
    'oneLiner': Schema(type: SchemaType.string),
    'audience': Schema(type: SchemaType.string),
    'tone': Schema(type: SchemaType.string),
    'palette': Schema(
      type: SchemaType.array,
      items: Schema(
        type: SchemaType.object,
        properties: {
          'hex': Schema(type: SchemaType.string),
          'role': Schema(type: SchemaType.string),
        },
        required: ['hex', 'role'],
      ),
    ),
    'concepts': Schema(
      type: SchemaType.array,
      items: Schema(
        type: SchemaType.object,
        properties: {
          'name': Schema(type: SchemaType.string),
          'species': Schema(type: SchemaType.string),
          'personality': Schema(type: SchemaType.string),
          'identityLock': Schema(type: SchemaType.string),
          'whyItFits': Schema(type: SchemaType.string),
        },
        required: [
          'name',
          'species',
          'personality',
          'identityLock',
          'whyItFits',
        ],
      ),
    ),
  },
  required: [
    'productName',
    'oneLiner',
    'audience',
    'tone',
    'palette',
    'concepts',
  ],
);

const _defaultPalette = [
  ColorSwatchInfo(hex: '#6B4EFF', role: 'primary'),
  ColorSwatchInfo(hex: '#FFD56A', role: 'accent'),
  ColorSwatchInfo(hex: '#24183A', role: 'ink'),
  ColorSwatchInfo(hex: '#F3EEFF', role: 'background'),
];

List<MascotConcept> _fillConcepts(String productName, List<MascotConcept> raw) {
  final unique = <String, MascotConcept>{};
  for (final concept in raw) {
    final key = concept.name.trim().toLowerCase();
    if (key.isEmpty) continue;
    unique.putIfAbsent(key, () => concept);
  }
  final filled = unique.values.toList();
  for (final fallback in _fallbackConcepts(productName)) {
    if (filled.length >= 4) break;
    final key = fallback.name.toLowerCase();
    if (unique.containsKey(key)) continue;
    filled.add(fallback);
  }
  return filled.take(4).toList();
}

List<MascotConcept> _fallbackConcepts(String productName) {
  return [
    MascotConcept(
      name: 'Pip',
      species: 'round clay dumpling',
      personality: 'warm, helpful, a little proud',
      identityLock:
          'Pip is a small round dumpling mascot for $productName. Grape-purple clay body #6B4EFF, butter-yellow sprout #FFD56A, mint leaf, huge glossy eyes, tiny smile, no text, 3D clay render.',
      whyItFits:
          'Reads instantly at icon size and feels friendly without being childish.',
    ),
    MascotConcept(
      name: 'Nori',
      species: 'plush fox with rounded ears',
      personality: 'clever, calm, a bit mischievous',
      identityLock:
          'Nori is a compact plush fox mascot for $productName. Soft apricot fur #FFB27A, cream muzzle, ink-navy nose #24183A, one grape scarf #6B4EFF, short rounded snout, 3D clay/plush render, no text.',
      whyItFits:
          'A fox silhouette is distinctive and still cute in empty states.',
    ),
    MascotConcept(
      name: 'Bolt',
      species: 'friendly rounded robot',
      personality: 'eager, tidy, slightly clumsy',
      identityLock:
          'Bolt is a squat rounded robot mascot for $productName. Cream ceramic shell, grape visor #6B4EFF, butter antenna orb #FFD56A, two stubby arms, soft clay materials, no sharp edges, no text.',
      whyItFits:
          'Reads as “product helper” without looking like a generic chatbot.',
    ),
    MascotConcept(
      name: 'Pebble',
      species: 'stone owl with big eyes',
      personality: 'steady, curious, quietly funny',
      identityLock:
          'Pebble is a smooth stone-owl mascot for $productName. Sage-gray body, mint belly #47C9A0, grape eye rings #6B4EFF, tiny butter beak #FFD56A, rounded wings, collectible clay look, no text.',
      whyItFits:
          'An owl feels trustworthy for a product that wants to look considered.',
    ),
  ];
}

String _guessName(String notes, String? url) {
  final host = Uri.tryParse(
    url ?? '',
  )?.host.replaceFirst(RegExp(r'^www\.'), '');
  if (host != null && host.isNotEmpty) {
    return host.split('.').first;
  }
  final words = notes
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2)
      .take(3)
      .join(' ');
  return words.isEmpty ? 'Your app' : words;
}

String? _string(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

List<dynamic> _asList(Object? value) {
  if (value is List) return value;
  if (value is Map) return [value];
  return const [];
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry('$key', item));
  return null;
}
