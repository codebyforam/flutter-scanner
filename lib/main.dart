import 'package:flutter/material.dart';
import 'package:flutter_ocr/app/app.dart';
import 'package:flutter_ocr/app/injection.dart';
import 'package:flutter_ocr/core/logger/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.i('Initializing Dependency Injection...');
  await initInjection();

  AppLogger.i('Starting OCR Scanner Application...');
  runApp(const OcrScannerApp());
}
