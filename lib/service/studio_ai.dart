import 'dart:typed_data';

import 'package:mascot_studio/models/brand_brief.dart';

abstract class StudioAi {
  Future<BrandBrief> analyzeBrand({String? url, required String notes});

  Future<Uint8List> generateImage({
    required String prompt,
    List<Uint8List> references = const [],
    String aspectRatio = '1:1',
  });

  Future<Uint8List> animateMascot({
    required String prompt,
    required Uint8List reference,
  });

  void close();
}
