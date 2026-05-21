import 'package:flutter_ocr/core/services/camera_image_service.dart';
import 'package:flutter_ocr/core/services/image_service.dart';
import 'package:flutter_ocr/core/services/ml_kit_ocr_service.dart';
import 'package:flutter_ocr/core/services/ocr_service.dart';
import 'package:flutter_ocr/features/card_scanner/cubit/card_scanner_cubit.dart';
import 'package:flutter_ocr/features/card_scanner/parser/card_parser.dart';
import 'package:flutter_ocr/features/passbook_scanner/cubit/passbook_scanner_cubit.dart';
import 'package:flutter_ocr/features/passbook_scanner/parser/passbook_parser.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

Future<void> initInjection() async {
  // Services
  sl.registerLazySingleton<ImageService>(CameraImageService.new);
  sl.registerLazySingleton<OcrService>(MlKitOcrService.new);

  // Parsers
  sl.registerLazySingleton<CardParser>(() => const CardParser());
  sl.registerLazySingleton<PassbookParser>(() => const PassbookParser());

  // Cubits
  sl.registerFactory<CardScannerCubit>(
    () => CardScannerCubit(
      imageService: sl(),
      ocrService: sl(),
      cardParser: sl(),
    ),
  );
  sl.registerFactory<PassbookScannerCubit>(
    () => PassbookScannerCubit(
      imageService: sl(),
      ocrService: sl(),
      passbookParser: sl(),
    ),
  );
}
