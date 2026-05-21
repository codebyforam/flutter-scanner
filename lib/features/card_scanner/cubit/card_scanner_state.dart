import 'package:equatable/equatable.dart';
import 'package:flutter_ocr/features/card_scanner/models/card_details.dart';

sealed class CardScannerState extends Equatable {
  const CardScannerState();

  @override
  List<Object?> get props => [];
}

final class CardScannerInitial extends CardScannerState {
  const CardScannerInitial();
}

final class CardScannerLoading extends CardScannerState {
  const CardScannerLoading();
}

final class CardScannerSuccess extends CardScannerState {
  final CardDetails data;
  final bool isDuplicate;

  const CardScannerSuccess(this.data, {this.isDuplicate = false});

  @override
  List<Object?> get props => [data, isDuplicate];
}

final class CardScannerPartialSuccess extends CardScannerState {
  final CardDetails data;
  final String warning;
  final bool isDuplicate;

  const CardScannerPartialSuccess(this.data, this.warning, {this.isDuplicate = false});

  @override
  List<Object?> get props => [data, warning, isDuplicate];
}

final class CardScannerFailure extends CardScannerState {
  final String message;

  const CardScannerFailure(this.message);

  @override
  List<Object?> get props => [message];
}
