import 'package:flutter_ocr/core/errors/result.dart';
import 'package:flutter_ocr/core/utils/regex_patterns.dart';
import 'package:flutter_ocr/core/utils/text_cleaner.dart';
import 'package:flutter_ocr/features/passbook_scanner/models/bank_details.dart';

class PassbookParser {
  const PassbookParser();

  Result<BankDetails> parse(String normalizedText) {
    if (normalizedText.isEmpty) {
      return const Failure('OCR text is empty');
    }

    String? foundAccountNo;
    String? foundIfscCode;
    String? warningMessage;

    final lines = normalizedText.split('\n');

    // 1. Search for IFSC Code
    for (final line in lines) {
      final cleanLine = line.replaceAll(RegExp(r'\s+'), '');
      final match = RegexPatterns.ifscPattern.firstMatch(cleanLine);
      if (match != null) {
        final rawIfsc = match.group(0)?.toUpperCase();
        if (rawIfsc != null && rawIfsc.length == 11) {
          // Normalize the 5th character to '0'
          foundIfscCode = '${rawIfsc.substring(0, 4)}0${rawIfsc.substring(5)}';
        } else {
          foundIfscCode = rawIfsc;
        }
        break;
      }
    }

    // 2. Search for Account Number with Confidence Scoring
    String? bestAccountNo;
    var highestScore = -100;

    for (final line in lines) {
      final normalizedLine = TextCleaner.normalizeDigits(line);
      final upperLine = normalizedLine.toUpperCase();

      final matches = RegexPatterns.accountNoPattern.allMatches(normalizedLine);
      for (final match in matches) {
        final candidate = match.group(0);
        if (candidate == null) continue;

        var score = 0;

        // Positive keywords
        if (upperLine.contains('ACCOUNT') || upperLine.contains('A/C') || upperLine.contains('ACC') || upperLine.contains('NO') || upperLine.contains('NUM')) {
          score += 5;
        }

        // Negative keywords
        if (upperLine.contains('DEBIT') || upperLine.contains('CREDIT') || upperLine.contains('BAL') || upperLine.contains('AMT') || upperLine.contains('RS')) {
          score -= 5;
        }

        if (score > highestScore) {
          highestScore = score;
          bestAccountNo = candidate;
        }
      }
    }

    if (highestScore >= 5) {
      foundAccountNo = bestAccountNo;
    }

    // 3. Search for Account Holder Name
    String? foundAccountHolderName;
    final nameKeywords = ['NAME', 'ACCOUNT HOLDER', 'CUSTOMER NAME', 'HOLDER NAME', 'NAME OF'];
    
    for (var i = 0; i < lines.length; i++) {
      final upperLine = lines[i].toUpperCase();
      
      for (final kw in nameKeywords) {
        if (upperLine.contains(kw)) {
          // Try to extract from the same line after the keyword
          var remaining = lines[i].substring(upperLine.indexOf(kw) + kw.length).trim();
          // Remove common separators
          remaining = remaining.replaceFirst(RegExp(r'^[:\-\s]+'), '').trim();
          
          if (remaining.isNotEmpty && remaining.split(' ').length >= 2) {
             // Basic check: should be mostly alphabetic
             if (RegExp(r'^[A-Z\s\.]+$', caseSensitive: false).hasMatch(remaining)) {
               foundAccountHolderName = remaining.toUpperCase();
               break;
             }
          }
          
          // If not found on same line, look at the next line
          if (i + 1 < lines.length) {
            final nextLine = lines[i+1].trim();
            if (nextLine.isNotEmpty && nextLine.split(' ').length >= 2) {
              if (RegExp(r'^[A-Z\s\.]+$', caseSensitive: false).hasMatch(nextLine)) {
                foundAccountHolderName = nextLine.toUpperCase();
                break;
              }
            }
          }
        }
      }
      if (foundAccountHolderName != null) break;
    }

    if (foundAccountNo == null && foundIfscCode == null && foundAccountHolderName == null) {
      return const Failure('Could not identify any bank details in OCR text');
    }

    if (foundAccountNo == null) {
      warningMessage = 'Account number could not be found';
    } else if (foundIfscCode == null) {
      warningMessage = 'IFSC code could not be found';
    } else if (foundAccountHolderName == null) {
      warningMessage = 'Account holder name could not be found';
    }

    final details = BankDetails(
      accountNo: foundAccountNo ?? '',
      ifscCode: foundIfscCode ?? '',
      accountHolderName: foundAccountHolderName ?? '',
      warning: warningMessage,
    );

    if (warningMessage != null) {
      return PartialSuccess(details, warningMessage);
    }

    return Success(details);
  }
}
