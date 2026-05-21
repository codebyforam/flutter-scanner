class TextCleaner {
  const TextCleaner._();

  /// Cleans and normalizes raw OCR text.
  /// Standardizes characters that are commonly misread by OCR engines.
  static String clean(String text) {
    return text
        .trim()
        // Replace typical OCR ligatures/substitutions
        .replaceAll('ﬁ', 'fi')
        .replaceAll('ﬂ', 'fl')
        // Clean multi-spaces and standardize line breaks
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  /// Helper to normalize characters based on context (e.g. converting letters to digits)
  static String normalizeDigits(String input) {
    return input
        .toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1')
        .replaceAll('Z', '2')
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll('G', '6')
        .replaceAll(RegExp(r'\s+'), '');
  }
}
