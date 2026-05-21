import 'package:equatable/equatable.dart';

class BankDetails extends Equatable {
  final String accountNo;
  final String ifscCode;
  final String? warning;

  const BankDetails({
    required this.accountNo,
    required this.ifscCode,
    this.warning,
  });

  const BankDetails.empty() : accountNo = '', ifscCode = '', warning = null;

  @override
  List<Object?> get props => [accountNo, ifscCode, warning];
}
