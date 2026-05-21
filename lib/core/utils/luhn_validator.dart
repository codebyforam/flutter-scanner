class LuhnValidator {
  const LuhnValidator._();

  /// Validates if a card number passes the Luhn checksum algorithm.
  static bool validate(String cardNumber) {
    final cleanNum = cardNumber.replaceAll(RegExp(r'\s+|-'), '');

    if (cleanNum.isEmpty || !RegExp(r'^\d+$').hasMatch(cleanNum)) {
      return false;
    }

    var sum = 0;
    var shouldDouble = false;

    for (var i = cleanNum.length - 1; i >= 0; i--) {
      var n = int.parse(cleanNum[i]);

      if (shouldDouble) {
        n *= 2;
        if (n > 9) {
          n -= 9;
        }
      }

      sum += n;
      shouldDouble = !shouldDouble;
    }

    return sum % 10 == 0;
  }
}
