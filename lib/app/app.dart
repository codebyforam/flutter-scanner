import 'package:flutter/material.dart';
import 'package:flutter_ocr/app/router.dart';
import 'package:flutter_ocr/core/theme/app_theme.dart';

class FlutterScannerApp extends StatelessWidget {
  const FlutterScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Scanner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
