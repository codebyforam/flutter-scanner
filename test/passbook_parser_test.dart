import 'package:flutter_ocr/core/errors/result.dart';
import 'package:flutter_ocr/core/utils/text_cleaner.dart';
import 'package:flutter_ocr/features/passbook_scanner/models/bank_details.dart';
import 'package:flutter_ocr/features/passbook_scanner/parser/passbook_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PassbookParser Tests', () {
    const parser = PassbookParser();

    test('Standard passbook extract details', () {
      const rawText = '''
        STATE BANK OF INDIA
        ACCOUNT HOLDER: JANE DOE
        ACCOUNT NO: 123456789012
        IFSC: SBIN0001234
        BRANCH: MUMBAI
      ''';
      final cleanText = TextCleaner.clean(rawText);
      final result = parser.parse(cleanText);

      expect(result, isA<Success<BankDetails>>());
      final success = result as Success<BankDetails>;
      expect(success.data.accountNo, equals('123456789012'));
      expect(success.data.ifscCode, equals('SBIN0001234'));
      expect(success.data.accountHolderName, equals('JANE DOE'));
    });

    test('IFSC with OCR error (O vs 0) is normalized', () {
      const rawText = '''
        SBIN O 001234
      ''';
      final result = parser.parse(TextCleaner.clean(rawText));
      expect(result, isA<PartialSuccess<BankDetails>>());
      final partial = result as PartialSuccess<BankDetails>;
      expect(partial.data.ifscCode, equals('SBIN0001234'));
    });

    test('Extracts name from multi-line format', () {
      const rawText = '''
        NAME
        JOHN SMITH
        A/C NO: 9876543210
      ''';
      final result = parser.parse(TextCleaner.clean(rawText));
      final data = (result as Success<BankDetails>).data;
      expect(data.accountHolderName, equals('JOHN SMITH'));
    });
    
    test('Failure when no details found', () {
      const rawText = 'random noise text with no keywords';
      final result = parser.parse(TextCleaner.clean(rawText));
      expect(result, isA<Failure<BankDetails>>());
    });
  });
}
