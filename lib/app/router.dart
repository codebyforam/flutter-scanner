import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ocr/app/injection.dart';
import 'package:flutter_ocr/features/card_scanner/cubit/card_scanner_cubit.dart';
import 'package:flutter_ocr/features/card_scanner/presentation/pages/card_scanner_page.dart';
import 'package:flutter_ocr/features/passbook_scanner/cubit/passbook_scanner_cubit.dart';
import 'package:flutter_ocr/features/passbook_scanner/presentation/pages/passbook_scanner_page.dart';
import 'package:flutter_ocr/features/scanner_home/presentation/pages/home_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/card-scanner',
      builder: (context, state) => BlocProvider<CardScannerCubit>(
        create: (context) => sl<CardScannerCubit>(),
        child: const CardScannerPage(),
      ),
    ),
    GoRoute(
      path: '/passbook-scanner',
      builder: (context, state) => BlocProvider<PassbookScannerCubit>(
        create: (context) => sl<PassbookScannerCubit>(),
        child: const PassbookScannerPage(),
      ),
    ),
  ],
);
