import 'package:flutter_ocr/core/utils/luhn_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LuhnValidator Tests', () {
    test('Valid card number returns true', () {
      // Standard test VISA number
      expect(LuhnValidator.validate('4242 4242 4242 4242'), isTrue);
      expect(LuhnValidator.validate('4242424242424242'), isTrue);
    });

    test('Invalid card number returns false', () {
      // One digit off
      expect(LuhnValidator.validate('4242 4242 4242 4241'), isFalse);
    });

    test('Empty or non-numeric strings return false', () {
      expect(LuhnValidator.validate(''), isFalse);
      expect(LuhnValidator.validate('abc'), isFalse);
    });

    test('Handles spaces and dashes', () {
      expect(LuhnValidator.validate('4242-4242-4242-4242'), isTrue);
    });
  });
}
