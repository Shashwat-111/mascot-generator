import 'package:flutter_test/flutter_test.dart';
import 'package:mascot_studio/models/brand_brief.dart';

void main() {
  test('incomplete JSON still yields four mascots', () {
    final brief = BrandBrief.fromJson({
      'productName': 'Applyra',
      'palette': [
        {'hex': '89CFF0', 'role': 'primary'},
      ],
    }, notes: 'Job application tracker');

    expect(brief.productName, 'Applyra');
    expect(brief.concepts, hasLength(4));
    expect(brief.palette, isNotEmpty);
    expect(brief.oneLiner, isNotEmpty);
    expect(brief.concepts.first.identityLock, isNotEmpty);

    final roundtrip = BrandBrief.fromJson(brief.toJson());
    expect(roundtrip.productName, brief.productName);
    expect(roundtrip.concepts, hasLength(4));
  });

  test('empty payload uses fallbacks', () {
    final brief = BrandBrief.fallback(notes: '', url: 'https://linear.app');
    expect(brief.productName, 'linear');
    expect(brief.concepts, hasLength(4));
  });
}
