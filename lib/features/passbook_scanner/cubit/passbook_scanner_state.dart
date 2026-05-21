import 'package:equatable/equatable.dart';
import 'package:flutter_ocr/features/passbook_scanner/models/bank_details.dart';

sealed class PassbookScannerState extends Equatable {
  const PassbookScannerState();

  @override
  List<Object?> get props => [];
}

final class PassbookScannerInitial extends PassbookScannerState {
  const PassbookScannerInitial();
}

final class PassbookScannerLoading extends PassbookScannerState {
  const PassbookScannerLoading();
}

final class PassbookScannerSuccess extends PassbookScannerState {
  final BankDetails data;
  final bool isDuplicate;

  const PassbookScannerSuccess(this.data, {this.isDuplicate = false});

  @override
  List<Object?> get props => [data, isDuplicate];
}

final class PassbookScannerPartialSuccess extends PassbookScannerState {
  final BankDetails data;
  final String warning;
  final bool isDuplicate;

  const PassbookScannerPartialSuccess(this.data, this.warning, {this.isDuplicate = false});

  @override
  List<Object?> get props => [data, warning, isDuplicate];
}

final class PassbookScannerFailure extends PassbookScannerState {
  final String message;

  const PassbookScannerFailure(this.message);

  @override
  List<Object?> get props => [message];
}
