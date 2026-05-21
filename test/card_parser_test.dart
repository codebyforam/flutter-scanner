import 'package:flutter_ocr/core/errors/result.dart';
import 'package:flutter_ocr/core/utils/text_cleaner.dart';
import 'package:flutter_ocr/features/card_scanner/models/card_details.dart';
import 'package:flutter_ocr/features/card_scanner/parser/card_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Improved CardParser Heuristics Tests', () {
    const parser = CardParser();

    test('Standard card with branding and correct details returns Success', () {
      const rawText = '''
        VISA DEBIT
        CARD HOLDER: JOHN DOE
        CARD NO: 4242 4242 4242 4242
        VALID THRU: 12/28
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<Success<CardDetails>>());
      final success = result as Success<CardDetails>;
      expect(success.data.cardNumber, equals('4242424242424242'));
      expect(success.data.expiryDate, equals('12/28'));
      expect(success.data.isLuhnValid, isTrue);
      expect(success.data.warning, isNull);
    });

    test('Non-card document with no details returns Failure with soft warning', () {
      const rawText = '''
        STATE BANK OF INDIA
        BRANCH: MUMBAI MAIN
        IFSC: SBIN0001234
        TRANSACTION STATEMENT FOR MAY 2026
        DEPOSIT: 10,000.00
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<Failure<CardDetails>>());
      final failure = result as Failure<CardDetails>;
      expect(failure.message, equals('This scan may not contain a clearly identifiable payment card.'));
    });

    test('Passbook scanning that happens to contain Luhn valid account number returns PartialSuccess with soft warning', () {
      const rawText = '''
        STATE BANK OF INDIA
        PASSBOOK SCAN
        ACCOUNT NO: 4242 4242 4242 4242
        IFSC: SBIN0001234
        BRANCH: CHENNAI
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      // Should be PartialSuccess because confidence is low, but we found a card candidate (the account number)
      expect(result, isA<PartialSuccess<CardDetails>>());
      final partial = result as PartialSuccess<CardDetails>;
      expect(partial.data.cardNumber, equals('4242424242424242'));
      expect(partial.partialMessage, startsWith('This scan may not contain a clearly identifiable payment card.'));
    });

    group('Expiry Formats Parsing', () {
      test('Parses MM/YY format', () {
        const rawText = '''
          VISA CARD
          4242 4242 4242 4242
          EXPIRY: 05/26
        ''';
        final result = parser.parse(TextCleaner.clean(rawText)) as Success<CardDetails>;
        expect(result.data.expiryDate, equals('05/26'));
      });

      test('Parses MM-YY format', () {
        const rawText = '''
          VISA CARD
          4242 4242 4242 4242
          EXP: 10-27
        ''';
        final result = parser.parse(TextCleaner.clean(rawText)) as Success<CardDetails>;
        expect(result.data.expiryDate, equals('10/27'));
      });

      test('Parses MMYY (no separator) format and filters it if inside card number', () {
        // Card 4242 4242 4242 4242 is Luhn-valid (16 digits) and does not contain '1224',
        // so 1224 on the VALID line is correctly kept as an expiry candidate.
        const rawText = '''
          VISA CARD
          4242 4242 4242 4242
          VALID: 1224
        ''';
        final result = parser.parse(TextCleaner.clean(rawText));
        expect(result, isA<Success<CardDetails>>());
        final success = result as Success<CardDetails>;
        // 1224 → 12/24
        expect(success.data.expiryDate, equals('12/24'));
      });

      test('Parses MM 2Y (with space) format', () {
        const rawText = '''
          VISA CARD
          4242 4242 4242 4242
          EXP: 08 29
        ''';
        final result = parser.parse(TextCleaner.clean(rawText)) as Success<CardDetails>;
        expect(result.data.expiryDate, equals('08/29'));
      });

      test('Parses MM/YYYY format and normalizes to MM/YY', () {
        const rawText = '''
          VISA CARD
          4242 4242 4242 4242
          EXPIRY: 12/2030
        ''';
        final result = parser.parse(TextCleaner.clean(rawText)) as Success<CardDetails>;
        expect(result.data.expiryDate, equals('12/30'));
      });

      test('Handles OCR-normalized digits (like O instead of 0, I instead of 1)', () {
        const rawText = '''
          VISA CARD
          4242 4242 4242 4242
          EXPIRY: O5/26
        ''';
        final result = parser.parse(TextCleaner.clean(rawText)) as Success<CardDetails>;
        expect(result.data.expiryDate, equals('05/26'));
      });
    });

    group('Contextual Prioritization', () {
      test('Prioritizes expiry date near EXP/VALID over date near DOB or OPEN DATE', () {
        const rawText = '''
          MASTERCARD
          4242 4242 4242 4242
          DOB: 01/90
          EXPIRY: 12/28
        ''';
        final result = parser.parse(TextCleaner.clean(rawText)) as Success<CardDetails>;
        // 12/28 is near EXPIRY (positive boost), while 01/90 is near DOB (negative penalty).
        expect(result.data.expiryDate, equals('12/28'));
      });

      test('Prioritizes expiry date near VALID THRU over date near MONTH/YEAR layout placeholders', () {
        const rawText = '''
          MASTERCARD
          4242 4242 4242 4242
          MONTH/YEAR: 01/90
          VALID THRU: 12/28
        ''';
        final result = parser.parse(TextCleaner.clean(rawText)) as Success<CardDetails>;
        // 12/28 is near VALID THRU (positive boost), while 01/90 is near MONTH/YEAR placeholder (negative penalty).
        expect(result.data.expiryDate, equals('12/28'));
      });
    });
  });
}
