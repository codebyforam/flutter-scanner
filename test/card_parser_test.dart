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
        JOHN DOE
        4242 4242 4242 4242
        VALID THRU 12/28
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<Success<CardDetails>>());
      final success = result as Success<CardDetails>;
      expect(success.data.cardNumber, equals('4242424242424242'));
      expect(success.data.expiryDate, equals('12/28'));
      expect(success.data.cardHolderName, equals('JOHN DOE'));
      expect(success.data.isLuhnValid, isTrue);
      expect(success.data.warning, isNull);
    });

    test('Card with CARD HOLDER prefix returns correct name', () {
      const rawText = '''
        4242 4242 4242 4242
        VALID THRU 12/28
        CARD HOLDER JANE SMITH
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<Success<CardDetails>>());
      final success = result as Success<CardDetails>;
      expect(success.data.cardHolderName, equals('JANE SMITH'));
    });

    test('Card with initials and mixed case returns normalized name', () {
      const rawText = '''
        4242 4242 4242 4242
        12/28
        J. R. Smith
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<Success<CardDetails>>());
      final success = result as Success<CardDetails>;
      expect(success.data.cardHolderName, equals('J. R. SMITH'));
    });

    test('Handles OCR misread digit in name (e.g., 1RAM PATEL)', () {
      const rawText = '''
        DEBIT
        1RAM PATEL
        6521 7905 0605 7
        VALID UPTO 11/24
        RuPay
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<Object>()); // Success or PartialSuccess
      final data = result is Success<CardDetails> 
          ? result.data 
          : (result as PartialSuccess<CardDetails>).data;
      
      expect(data.cardHolderName, equals('IRAM PATEL'));
      expect(data.expiryDate, equals('11/24'));
    });

    test('Non-card document with no details returns Failure', () {
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
    });

    test('Passbook scanning that happens to contain Luhn valid account number returns PartialSuccess', () {
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
      expect(partial.partialMessage, startsWith('Low confidence scan.'));
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

      test('Parses MMYY (no separator) format', () {
        const rawText = '''
          VISA CARD
          4242 4242 4242 4242
          VALID 1224
        ''';
        final result = parser.parse(TextCleaner.clean(rawText));
        expect(result, isA<Success<CardDetails>>());
        final success = result as Success<CardDetails>;
        expect(success.data.expiryDate, equals('12/24'));
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
  });
}
