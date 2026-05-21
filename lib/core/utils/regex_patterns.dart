class RegexPatterns {
  const RegexPatterns._();

  /// Regex pattern matching common credit/debit card numbers (10 to 19 digits)
  static final RegExp cardPattern = RegExp(r'\b(?:\d[ -]*?){10,19}\b');

  /// Regex pattern matching expiry date in format MM/YY or MM/YYYY
  static final RegExp expiryPattern = RegExp(r'\b(0[1-9]|1[0-2])\s*/\s*([0-9]{2,4})\b');

  /// Regex patterns matching expiry dates with separator (/, -, .) or without separator/with space
  static final RegExp expiryWithSeparator = RegExp(r'\b(0[1-9]|1[0-2])\s*[/.-]\s*([0-9]{2}|[0-9]{4})\b');
  static final RegExp expiryNoSeparator = RegExp(r'\b(0[1-9]|1[0-2])\s*([0-9]{2})\b');

  /// Regex pattern matching Indian Financial System Code (IFSC) (e.g., SBIN0001234)
  static final RegExp ifscPattern = RegExp(r'\b[A-Z]{4}[0O][A-Z0-9]{6}\b', caseSensitive: false);

  /// Regex pattern matching typical Bank Account Numbers (9 to 18 digits)
  static final RegExp accountNoPattern = RegExp(r'\b\d{9,18}\b');
}
