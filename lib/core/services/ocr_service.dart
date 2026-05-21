import 'dart:io';

import 'package:flutter_ocr/core/errors/result.dart';

abstract class OcrService {
  Future<Result<String>> extractText(File imageFile);
}

class FakeOcrService implements OcrService {
  const FakeOcrService();

  @override
  Future<Result<String>> extractText(File imageFile) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return const Success('MOCK OCR TEXT FOR TESTING');
  }
}
