import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ocr/core/errors/result.dart';
import 'package:flutter_ocr/core/services/image_service.dart';
import 'package:flutter_ocr/core/services/ocr_service.dart';
import 'package:flutter_ocr/core/utils/text_cleaner.dart';
import 'package:flutter_ocr/features/card_scanner/cubit/card_scanner_state.dart';
import 'package:flutter_ocr/features/card_scanner/parser/card_parser.dart';

class CardScannerCubit extends Cubit<CardScannerState> {
  final ImageService _imageService;
  final OcrService _ocrService;
  final CardParser _cardParser;

  CardScannerCubit({
    required ImageService imageService,
    required OcrService ocrService,
    required CardParser cardParser,
  }) : _imageService = imageService,
       _ocrService = ocrService,
       _cardParser = cardParser,
       super(const CardScannerInitial());

  File? _scannedImageFile;

  File? get scannedImageFile => _scannedImageFile;

  int? _lastScanHash;

  Future<void> scanCardFromCamera() async {
    final imgResult = await _imageService.pickImageFromCamera();
    await _processImageResult(imgResult);
  }

  Future<void> scanCardFromGallery() async {
    final imgResult = await _imageService.pickImageFromGallery();
    await _processImageResult(imgResult);
  }

  Future<void> _processImageResult(Result<File> imgResult) async {
    switch (imgResult) {
      case Success(:final data):
        _scannedImageFile = data;
        emit(const CardScannerLoading());
        
        // Add artificial delay to make the analysis stage feel premium and deliberate
        await Future<void>.delayed(const Duration(milliseconds: 1500));

        final ocrResult = await _ocrService.extractText(data);
        _processOcrResult(ocrResult);
      case PartialSuccess(:final partialMessage):
        emit(CardScannerFailure('Image processing warning: $partialMessage'));
      case Failure(:final message):
        // If user canceled (common case for 'No image...'), return to initial instead of error
        if (message.contains('No image')) {
          emit(const CardScannerInitial());
        } else {
          emit(CardScannerFailure(message));
        }
    }
  }

  void _processOcrResult(Result<String> ocrResult) {
    switch (ocrResult) {
      case Success(:final data):
        final normalizedText = TextCleaner.clean(data);
        final currentHash = normalizedText.hashCode;
        final isDuplicate = _lastScanHash == currentHash;
        if (!isDuplicate) {
          _lastScanHash = currentHash;
        }

        final parseResult = _cardParser.parse(normalizedText);

        switch (parseResult) {
          case Success(:final data):
            if (data.warning != null) {
              emit(CardScannerPartialSuccess(data, data.warning!, isDuplicate: isDuplicate));
            } else {
              emit(CardScannerSuccess(data, isDuplicate: isDuplicate));
            }
          case PartialSuccess(:final data, :final partialMessage):
            emit(CardScannerPartialSuccess(data, partialMessage, isDuplicate: isDuplicate));
          case Failure(:final message):
            emit(CardScannerFailure(message));
        }
      case PartialSuccess(:final partialMessage):
        emit(CardScannerFailure('OCR warning: $partialMessage'));
      case Failure(:final message):
        emit(CardScannerFailure(message));
    }
  }

  void reset() {
    _scannedImageFile = null;
    _lastScanHash = null;
    emit(const CardScannerInitial());
  }
}
