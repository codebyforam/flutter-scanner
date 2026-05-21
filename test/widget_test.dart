import 'package:flutter_ocr/core/errors/result.dart';
import 'package:flutter_ocr/core/utils/luhn_validator.dart';
import 'package:flutter_ocr/core/utils/text_cleaner.dart';
import 'package:flutter_ocr/features/card_scanner/models/card_details.dart';
import 'package:flutter_ocr/features/card_scanner/parser/card_parser.dart';
import 'package:flutter_ocr/features/passbook_scanner/models/bank_details.dart';
import 'package:flutter_ocr/features/passbook_scanner/parser/passbook_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LuhnValidator Tests', () {
    test('Valid card numbers should pass Luhn algorithm', () {
      expect(LuhnValidator.validate('4242424242424242'), isTrue);
      expect(LuhnValidator.validate('49927398716'), isTrue);
    });

    test('Invalid card numbers should fail Luhn algorithm', () {
      expect(LuhnValidator.validate('4242424242424243'), isFalse);
    });
  });

  group('TextCleaner Tests', () {
    test('Clean should trim, normalize spacing and resolve OCR ligatures', () {
      const rawOcr = '  CARD  NUMBER  \n ﬁrst line \n ﬂow line  ';
      final cleaned = TextCleaner.clean(rawOcr);
      expect(cleaned, equals('CARD NUMBER\nfirst line\nflow line'));
    });

    test('normalizeDigits should map characters like O and I to 0 and 1', () {
      expect(TextCleaner.normalizeDigits('4242 O242 42I2'), equals('424202424212'));
    });
  });

  group('CardParser Tests', () {
    test('CardParser should extract card details and return Success for standard length 16', () {
      const parser = CardParser();
      const rawText = '''
        FEDERAL CARD
        CARD NO: 4242 4242 4242 4242
        EXPIRY: 12/28
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<Success<CardDetails>>());
      final success = result as Success<CardDetails>;
      expect(success.data.cardNumber, equals('4242424242424242'));
      expect(success.data.expiryDate, equals('12/28'));
      expect(success.data.isLuhnValid, isTrue);
    });

    test('CardParser should return PartialSuccess for non-standard length', () {
      const parser = CardParser();
      const rawText = '''
        CARD NO: 4992 7398 716
        EXPIRY: 12/28
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<PartialSuccess<CardDetails>>());
      final partial = result as PartialSuccess<CardDetails>;
      expect(partial.data.cardNumber, equals('49927398716'));
      expect(partial.partialMessage, equals('Card number has non-standard length'));
    });
  });

  group('PassbookParser Tests', () {
    test('PassbookParser should extract account with high score and IFSC', () {
      const parser = PassbookParser();
      const rawText = '''
        STATE BANK OF INDIA
        A/C NO: 12345O789O12
        IFSC CODE: SBINO001234
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<Success<BankDetails>>());
      final success = result as Success<BankDetails>;
      expect(success.data.accountNo, equals('123450789012'));
      expect(success.data.ifscCode, equals('SBIN0001234'));
    });

    test('PassbookParser should return PartialSuccess when IFSC is missing', () {
      const parser = PassbookParser();
      const rawText = '''
        STATE BANK OF INDIA
        A/C NO: 12345O789O12
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<PartialSuccess<BankDetails>>());
      final partial = result as PartialSuccess<BankDetails>;
      expect(partial.data.accountNo, equals('123450789012'));
      expect(partial.partialMessage, equals('IFSC code could not be found'));
    });
  });
}
