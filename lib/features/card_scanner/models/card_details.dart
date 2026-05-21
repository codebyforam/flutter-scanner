import 'package:equatable/equatable.dart';

class CardDetails extends Equatable {
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;
  final bool isLuhnValid;
  final String? warning;

  const CardDetails({
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
    required this.isLuhnValid,
    this.warning,
  });

  const CardDetails.empty()
      : cardNumber = '',
        expiryDate = '',
        cardHolderName = '',
        isLuhnValid = false,
        warning = null;

  @override
  List<Object?> get props => [cardNumber, expiryDate, cardHolderName, isLuhnValid, warning];
}
