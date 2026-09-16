/// Splits a single landing prompt into the URL Gemini should fetch and leftover notes.
({String url, String notes}) parseProductPrompt(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return (url: '', notes: '');
  }

  final match = _urlPattern.firstMatch(text);
  if (match == null) {
    return (url: '', notes: text);
  }

  final url = _trimTrailingPunctuation(match.group(0)!);
  final notes = '${text.substring(0, match.start)} ${text.substring(match.end)}'
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return (url: url, notes: notes);
}

final _urlPattern = RegExp(r'https?://[^\s<>]+', caseSensitive: false);

String _trimTrailingPunctuation(String url) {
  return url.replaceFirst(RegExp(r'[.,;:!?)]+$'), '');
}
