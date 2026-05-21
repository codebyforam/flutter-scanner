import 'package:equatable/equatable.dart';

class BankDetails extends Equatable {
  final String accountNo;
  final String ifscCode;
  final String accountHolderName;
  final String? warning;

  const BankDetails({
    required this.accountNo,
    required this.ifscCode,
    required this.accountHolderName,
    this.warning,
  });

  const BankDetails.empty()
      : accountNo = '',
        ifscCode = '',
        accountHolderName = '',
        warning = null;

  @override
  List<Object?> get props => [accountNo, ifscCode, accountHolderName, warning];
}
