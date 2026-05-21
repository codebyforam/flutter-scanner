import 'dart:io';
import 'dart:ui';

import 'package:flutter_ocr/core/errors/result.dart';
import 'package:flutter_ocr/core/services/image_service.dart';
import 'package:image_picker/image_picker.dart';

class CameraImageService implements ImageService {
  final ImagePicker _picker;

  CameraImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<Result<File>> pickImageFromCamera() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (file == null) {
        return const Failure('No image captured.');
      }
      return Success(File(file.path));
    } on Exception catch (e) {
      return Failure('Failed to capture image: $e');
    }
  }

  @override
  Future<Result<File>> pickImageFromGallery() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (file == null) {
        return const Failure('No image selected.');
      }
      return Success(File(file.path));
    } on Exception catch (e) {
      return Failure('Failed to select image: $e');
    }
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
