import 'dart:io';

import 'package:flutter_ocr/core/errors/result.dart';
import 'package:flutter_ocr/core/services/ocr_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlKitOcrService implements OcrService {
  @override
  Future<Result<String>> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (recognizedText.text.isEmpty) {
        return const Failure('No text could be recognized from the image.');
      }

      return Success(recognizedText.text);
    } on Exception catch (e) {
      return Failure('OCR Processing failed: $e');
    }
  }
}
