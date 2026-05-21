import 'package:flutter_ocr/core/errors/result.dart';
import 'package:flutter_ocr/core/logger/app_logger.dart';
import 'package:flutter_ocr/core/utils/luhn_validator.dart';
import 'package:flutter_ocr/core/utils/regex_patterns.dart';
import 'package:flutter_ocr/core/utils/text_cleaner.dart';
import 'package:flutter_ocr/features/card_scanner/models/card_details.dart';

class _ExpiryCandidate {
  final String rawText;
  final String normalizedText;
  final int score;
  final int baseScore;
  final int lineIndex;

  const _ExpiryCandidate({
    required this.rawText,
    required this.normalizedText,
    required this.score,
    required this.baseScore,
    required this.lineIndex,
  });
}

class CardParser {
  const CardParser();

  String _normalizeDigitsPreservingSpaces(String input) {
    return input.toUpperCase().replaceAll('O', '0').replaceAll('I', '1').replaceAll('L', '1').replaceAll('Z', '2').replaceAll('S', '5').replaceAll('B', '8').replaceAll('G', '6');
  }

  String? _normalizeExpiry(String month, String year) {
    final cleanMonth = month.replaceAll(RegExp(r'\D'), '');
    var cleanYear = year.replaceAll(RegExp(r'\D'), '');
    if (cleanMonth.isEmpty || cleanYear.isEmpty) return null;

    final m = int.tryParse(cleanMonth);
    if (m == null || m < 1 || m > 12) return null;

    final formattedMonth = m.toString().padLeft(2, '0');

    if (cleanYear.length == 4) {
      cleanYear = cleanYear.substring(2);
    } else if (cleanYear.length != 2) {
      return null;
    }

    return '$formattedMonth/$cleanYear';
  }

  int _calculateDocumentScore(
    String normalizedText, {
    required String? foundCardNumber,
    required int? bestExpiryScore,
    required int? bestExpiryBaseScore,
  }) {
    var score = 0;
    final lowerText = normalizedText.toLowerCase();

    // 1. Positive keywords
    if (RegExp(r'\bvisa\b').hasMatch(lowerText)) score += 2;
    if (RegExp(r'\bmastercard\b').hasMatch(lowerText)) score += 2;
    if (RegExp(r'\brupay\b').hasMatch(lowerText)) score += 2;
    if (RegExp(r'\bdebit\b').hasMatch(lowerText)) score += 1;
    if (RegExp(r'\bcredit\b').hasMatch(lowerText)) score += 1;
    if (RegExp(r'\bcard\s*holder\b').hasMatch(lowerText)) score += 1;
    if (RegExp(r'\b(valid\s+thru|val\s+thru)\b').hasMatch(lowerText)) score += 1;

    // 2. Card number passes Luhn
    if (foundCardNumber != null && LuhnValidator.validate(foundCardNumber)) {
      score += 3;
    }

    // 3. Expiry candidate has context boost
    if (bestExpiryScore != null && bestExpiryBaseScore != null) {
      if ((bestExpiryScore - bestExpiryBaseScore) >= 2) {
        score += 2;
      }
    }

    // 4. Negative keywords
    if (RegExp(r'\b(account|a/c)\b').hasMatch(lowerText)) score -= 1;
    if (RegExp(r'\bcustomer\s*id\b').hasMatch(lowerText)) score -= 1;
    if (RegExp(r'\bopen\s*date\b').hasMatch(lowerText)) score -= 1;
    if (RegExp(r'\bbranch\b').hasMatch(lowerText)) score -= 2;
    if (RegExp(r'\bifsc\b').hasMatch(lowerText)) score -= 3;
    if (RegExp(r'\bpassbook\b').hasMatch(lowerText)) score -= 3;
    if (RegExp(r'\btransaction(s)?\b').hasMatch(lowerText)) score -= 3;
    if (RegExp(r'\bstatement(s)?\b').hasMatch(lowerText)) score -= 3;

    return score;
  }

  Result<CardDetails> parse(String normalizedText) {
    if (normalizedText.isEmpty) {
      return const Failure('OCR text is empty');
    }

    final lines = normalizedText.split('\n');

    // 1. Gather all potential card numbers after stripping spaces (standard OCR-friendly approach)
    final cardCandidates = <String>[];
    for (final line in lines) {
      final normalizedLine = TextCleaner.normalizeDigits(line);
      final matches = RegexPatterns.cardPattern.allMatches(normalizedLine);
      for (final m in matches) {
        final candidate = m.group(0);
        if (candidate != null) {
          cardCandidates.add(candidate);
        }
      }
    }

    // 2. Select the best card number candidate
    String? foundCardNumber;
    if (cardCandidates.isNotEmpty) {
      // Find the first Luhn valid candidate with standard length
      for (final card in cardCandidates) {
        final len = card.length;
        final isStandard = len == 13 || len == 15 || len == 16 || len == 19;
        if (isStandard && LuhnValidator.validate(card)) {
          foundCardNumber = card;
          break;
        }
      }
      // Fallback to first Luhn valid candidate
      if (foundCardNumber == null) {
        for (final card in cardCandidates) {
          if (LuhnValidator.validate(card)) {
            foundCardNumber = card;
            break;
          }
        }
      }
      // Fallback to first candidate
      foundCardNumber ??= cardCandidates.first;
    }

    // 3. Find and score expiry candidates
    final expiryCandidates = <_ExpiryCandidate>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final normalizedLine = _normalizeDigitsPreservingSpaces(line);

      // We search for both separator and no-separator matches on the normalized line
      final matches = <Match>[
        ...RegexPatterns.expiryWithSeparator.allMatches(normalizedLine),
        ...RegexPatterns.expiryNoSeparator.allMatches(normalizedLine),
      ];

      for (final match in matches) {
        final rawText = match.group(0);
        final month = match.group(1);
        final year = match.group(2);

        if (rawText == null || month == null || year == null) continue;

        // Skip if this candidate is actually a substring of the card number (relevant for non-separated candidates like 1224)
        final hasSep = rawText.contains(RegExp('[/.-]'));
        if (!hasSep && foundCardNumber != null) {
          final cleanExpiryDigits = rawText.replaceAll(RegExp(r'\D'), '');
          if (foundCardNumber.contains(cleanExpiryDigits)) {
            continue;
          }
        }

        final normalized = _normalizeExpiry(month, year);
        if (normalized == null) continue;

        // Base score: 2 for separator matches, 1 for no-separator matches
        final baseScore = hasSep ? 2 : 1;
        var score = baseScore;

        // Context Boost / Penalty Check in lines [i-1, i]
        var hasPositiveThru = false;
        var hasPositiveExp = false;
        var hasNegativeMonthYear = false;
        var hasNegativeOpenDob = false;

        for (var j = i - 1; j <= i; j++) {
          if (j < 0 || j >= lines.length) continue;
          final contextLine = lines[j];

          if (RegExp(r'\b(valid\s+thru|val\s+thru)\b', caseSensitive: false).hasMatch(contextLine)) {
            hasPositiveThru = true;
          }
          if (RegExp(r'\b(valid|exp|expiry|expires)\b', caseSensitive: false).hasMatch(contextLine)) {
            hasPositiveExp = true;
          }
          if (RegExp(r'\b(month\s*/\s*year|mm\s*/\s*yy(yy)?)\b', caseSensitive: false).hasMatch(contextLine)) {
            hasNegativeMonthYear = true;
          }
          if (RegExp(r'\b(open\s*date|dob|date\s+of\s+birth|birth)\b', caseSensitive: false).hasMatch(contextLine)) {
            hasNegativeOpenDob = true;
          }
        }

        if (hasPositiveThru) {
          score += 3;
        } else if (hasPositiveExp) {
          score += 2;
        }

        if (hasNegativeMonthYear) {
          score -= 2;
        }
        if (hasNegativeOpenDob) {
          score -= 3;
        }

        expiryCandidates.add(
          _ExpiryCandidate(
            rawText: rawText,
            normalizedText: normalized,
            score: score,
            baseScore: baseScore,
            lineIndex: i,
          ),
        );
      }
    }

    // 4. Select the best expiry candidate
    _ExpiryCandidate? bestExpiry;
    if (expiryCandidates.isNotEmpty) {
      expiryCandidates.sort((a, b) {
        if (a.score != b.score) {
          return b.score.compareTo(a.score);
        }
        final aHasSep = a.rawText.contains(RegExp('[/.-]'));
        final bHasSep = b.rawText.contains(RegExp('[/.-]'));
        if (aHasSep != bHasSep) {
          return aHasSep ? -1 : 1;
        }
        return a.lineIndex.compareTo(b.lineIndex);
      });
      bestExpiry = expiryCandidates.first;
    }

    final foundExpiryDate = bestExpiry?.normalizedText;

    // 5. Try to find card holder name
    String? foundCardHolderName;

    for (final line in lines) {
      var candidate = line.trim();
      if (candidate.isEmpty) continue;

      final upperCandidate = candidate.toUpperCase();

      // Check for common labels and strip them
      final prefixes = ['CARD HOLDER', 'NAME', 'CARDHOLDER', 'NAME OF HOLDER'];
      var hadPrefix = false;
      for (final p in prefixes) {
        if (upperCandidate.startsWith(p)) {
          candidate = candidate.substring(p.length).replaceFirst(RegExp(r'^[:\-\s]+'), '').trim();
          hadPrefix = true;
          break;
        }
      }

      if (candidate.isEmpty) continue;

      // Look for lines with 2-5 words
      final words = candidate.split(RegExp(r'\s+'));
      if (words.length >= 2 && words.length <= 5) {
        final cleanedCandidate = candidate.toUpperCase()
            .replaceAll('1', 'I')
            .replaceAll('0', 'O')
            .replaceAll('5', 'S')
            .replaceAll('8', 'B')
            .replaceAll('2', 'Z');

        if (RegExp(r'^[A-Z\s.-]+$').hasMatch(cleanedCandidate)) {
          var isForbidden = false;
          final forbiddenKeywords = [
            'DEBIT', 'CREDIT', 'CARD', 'INTERNATIONAL', 'PLATINUM', 
            'GOLD', 'CLASSIC', 'BANK', 'VALID', 'THRU', 'UPTO', 'FROM',
            'ELECTRON', 'MAESTRO', 'RUPAY', 'VISA', 'MASTERCARD', 'WORLD',
            'PREPAID', 'SIGNATURE', 'BUSINESS', 'MEMBER', 'AUTHORIZED',
            'CUSTOMER', 'INDIA', 'STATE', 'CENTRAL', 'HDFC', 'ICICI', 'AXIS'
          ];
          
          final upperCandidate = cleanedCandidate.toUpperCase();
          for (final kw in forbiddenKeywords) {
            if (upperCandidate.contains(kw)) {
              isForbidden = true;
              break;
            }
          }
          
          if (isForbidden) {
            AppLogger.d('Skipping name candidate (forbidden keyword): $cleanedCandidate');
            continue;
          }
          
          if (!hadPrefix) {
            if (cleanedCandidate.length < 3) continue;
            // Names usually don't have very long single words (unless it's a very long surname)
            // But they definitely don't have words like 'INTERNATIONAL' which is 13 chars.
            if (words.any((w) => w.length > 15)) continue;
            if (words.any((w) => w.length < 2 && !w.contains('.'))) continue;
          }

          AppLogger.d('Found name candidate: $cleanedCandidate (Prefix: $hadPrefix)');
          foundCardHolderName = cleanedCandidate;
          if (hadPrefix) break;
        }
      }
    }

    // 6. Calculate Document Confidence Score
    final docScore = _calculateDocumentScore(
      normalizedText,
      foundCardNumber: foundCardNumber,
      bestExpiryScore: bestExpiry?.score,
      bestExpiryBaseScore: bestExpiry?.baseScore,
    );

    final isDocConfidenceLow = docScore < 3;

    if (foundCardNumber == null && foundExpiryDate == null) {
      return const Failure('Could not find any card details. Please ensure the card is well-lit and clearly visible.');
    }

    var isLuhnValid = false;
    var isStandardLength = false;
    String? warningMessage;

    if (foundCardNumber != null) {
      final len = foundCardNumber.length;
      if (len == 13 || len == 15 || len == 16 || len == 19) {
        isStandardLength = true;
      }
      isLuhnValid = LuhnValidator.validate(foundCardNumber);
    }

    // Determine warning messaging
    if (isDocConfidenceLow) {
      final String suffix;
      if (foundCardNumber == null) {
        suffix = ' Card number could not be found.';
      } else if (!isLuhnValid) {
        suffix = ' Card number failed checksum verification.';
      } else if (!isStandardLength) {
        suffix = ' Card number has non-standard length.';
      } else if (foundExpiryDate == null) {
        suffix = ' Expiry date could not be found.';
      } else {
        suffix = '';
      }

      warningMessage = 'Low confidence scan.$suffix';
    } else if (foundCardNumber == null || !isLuhnValid || foundExpiryDate == null) {
      if (foundCardNumber == null) {
        warningMessage = 'Card number not found.';
      } else if (!isLuhnValid) {
        warningMessage = 'Invalid card number checksum.';
      } else {
        warningMessage = 'Expiry date not found.';
      }
    }

    final details = CardDetails(
      cardNumber: foundCardNumber ?? '',
      expiryDate: foundExpiryDate ?? '',
      cardHolderName: foundCardHolderName ?? '',
      isLuhnValid: isLuhnValid,
      warning: warningMessage,
    );

    if (warningMessage != null) {
      return PartialSuccess(details, warningMessage);
    }
    
    return Success(details);
  }
}
