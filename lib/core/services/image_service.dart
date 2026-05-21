import 'dart:io';
import 'dart:ui';

import 'package:flutter_ocr/core/errors/result.dart';

abstract class ImageService {
  Future<Result<File>> pickImageFromCamera();

  Future<Result<File>> pickImageFromGallery();

  // Future-proofing placeholders for image preprocessing
  Future<File> cropImage(File image, Rect rect);

  Future<File> sharpenImage(File image);

  Future<File> convertToGrayscale(File image);
}

class FakeImageService implements ImageService {
  const FakeImageService();

  @override
  Future<Result<File>> pickImageFromCamera() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const Failure('Camera picking not implemented in FakeImageService');
  }

  @override
  Future<Result<File>> pickImageFromGallery() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const Failure('Gallery picking not implemented in FakeImageService');
  }

  @override
  Future<File> cropImage(File image, Rect rect) async {
    // TODO(user): Implement image cropping logic in the future
    return image;
  }

  @override
  Future<File> sharpenImage(File image) async {
    // TODO(user): Implement image sharpening logic in the future
    return image;
  }

  @override
  Future<File> convertToGrayscale(File image) async {
    // TODO(user): Implement grayscale conversion logic in the future
    return image;
  }
}
