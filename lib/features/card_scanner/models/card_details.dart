import 'package:equatable/equatable.dart';

class CardDetails extends Equatable {
  final String cardNumber;
  final String expiryDate;
  final bool isLuhnValid;
  final String? warning;

  const CardDetails({
    required this.cardNumber,
    required this.expiryDate,
    required this.isLuhnValid,
    this.warning,
  });

  const CardDetails.empty() : cardNumber = '', expiryDate = '', isLuhnValid = false, warning = null;

  @override
  List<Object?> get props => [cardNumber, expiryDate, isLuhnValid, warning];
}
