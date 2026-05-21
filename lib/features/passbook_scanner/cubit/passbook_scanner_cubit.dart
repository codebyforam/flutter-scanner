import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ocr/core/errors/result.dart';
import 'package:flutter_ocr/core/services/image_service.dart';
import 'package:flutter_ocr/core/services/ocr_service.dart';
import 'package:flutter_ocr/core/utils/text_cleaner.dart';
import 'package:flutter_ocr/features/passbook_scanner/cubit/passbook_scanner_state.dart';
import 'package:flutter_ocr/features/passbook_scanner/parser/passbook_parser.dart';

class PassbookScannerCubit extends Cubit<PassbookScannerState> {
  final ImageService _imageService;
  final OcrService _ocrService;
  final PassbookParser _passbookParser;

  PassbookScannerCubit({
    required ImageService imageService,
    required OcrService ocrService,
    required PassbookParser passbookParser,
  }) : _imageService = imageService,
       _ocrService = ocrService,
       _passbookParser = passbookParser,
       super(const PassbookScannerInitial());

  File? _scannedImageFile;

  File? get scannedImageFile => _scannedImageFile;

  int? _lastScanHash;

  Future<void> scanPassbookFromCamera() async {
    emit(const PassbookScannerLoading());
    final imgResult = await _imageService.pickImageFromCamera();
    await _processImageResult(imgResult);
  }

  Future<void> scanPassbookFromGallery() async {
    emit(const PassbookScannerLoading());
    final imgResult = await _imageService.pickImageFromGallery();
    await _processImageResult(imgResult);
  }

  Future<void> _processImageResult(Result<File> imgResult) async {
    switch (imgResult) {
      case Success(:final data):
        _scannedImageFile = data;
        final ocrResult = await _ocrService.extractText(data);
        _processOcrResult(ocrResult);
      case PartialSuccess(:final partialMessage):
        emit(PassbookScannerFailure('Image processing warning: $partialMessage'));
      case Failure(:final message):
        emit(PassbookScannerFailure(message));
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

        final parseResult = _passbookParser.parse(normalizedText);

        switch (parseResult) {
          case Success(:final data):
            if (data.warning != null) {
              emit(PassbookScannerPartialSuccess(data, data.warning!, isDuplicate: isDuplicate));
            } else {
              emit(PassbookScannerSuccess(data, isDuplicate: isDuplicate));
            }
          case PartialSuccess(:final data, :final partialMessage):
            emit(PassbookScannerPartialSuccess(data, partialMessage, isDuplicate: isDuplicate));
          case Failure(:final message):
            emit(PassbookScannerFailure(message));
        }
      case PartialSuccess(:final partialMessage):
        emit(PassbookScannerFailure('OCR warning: $partialMessage'));
      case Failure(:final message):
        emit(PassbookScannerFailure(message));
    }
  }

  void reset() {
    _scannedImageFile = null;
    _lastScanHash = null;
    emit(const PassbookScannerInitial());
  }
}
