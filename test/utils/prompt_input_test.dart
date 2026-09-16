import 'package:flutter_test/flutter_test.dart';
import 'package:mascot_studio/utils/prompt_input.dart';

void main() {
  group('parseProductPrompt', () {
    test('keeps a description-only prompt as notes', () {
      const raw = 'A calm budgeting app for first-time renters.';
      final (:url, :notes) = parseProductPrompt(raw);
      expect(url, isEmpty);
      expect(notes, raw);
    });

    test('extracts the first url and leftover notes', () {
      final (:url, :notes) = parseProductPrompt(
        'Look at https://linear.app/docs please, a project tracker.',
      );
      expect(url, 'https://linear.app/docs');
      expect(notes, 'Look at please, a project tracker.');
    });

    test('strips trailing punctuation from the url', () {
      final (:url, :notes) = parseProductPrompt(
        'Brand site: https://acme.com).',
      );
      expect(url, 'https://acme.com');
      expect(notes, 'Brand site:');
    });

    test('accepts a bare url', () {
      final (:url, :notes) = parseProductPrompt('https://yourapp.com');
      expect(url, 'https://yourapp.com');
      expect(notes, isEmpty);
    });

    test('trims empty input', () {
      final (:url, :notes) = parseProductPrompt('   ');
      expect(url, isEmpty);
      expect(notes, isEmpty);
    });
  });
}
