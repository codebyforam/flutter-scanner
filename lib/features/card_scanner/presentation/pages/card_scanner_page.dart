import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ocr/core/utils/luhn_validator.dart';
import 'package:flutter_ocr/features/card_scanner/cubit/card_scanner_cubit.dart';
import 'package:flutter_ocr/features/card_scanner/cubit/card_scanner_state.dart';
import 'package:flutter_ocr/shared/widgets/result_tile.dart';
import 'package:flutter_ocr/shared/widgets/scan_error_view.dart';
import 'package:flutter_ocr/shared/widgets/scan_image_preview.dart';
import 'package:flutter_ocr/shared/widgets/scan_timeline.dart';
import 'package:go_router/go_router.dart';

class CardScannerPage extends StatelessWidget {
  const CardScannerPage({super.key});

  List<ScanStep> _getSteps(CardScannerState state) {
    if (state is CardScannerInitial) {
      return [
        const ScanStep(label: 'Image', status: ScanStepStatus.pending),
        const ScanStep(label: 'Analyzing', status: ScanStepStatus.pending),
        const ScanStep(label: 'Done', status: ScanStepStatus.pending),
      ];
    }
    
    final isError = state is CardScannerFailure;
    final isDone = state is CardScannerSuccess || state is CardScannerPartialSuccess;
    final isLoading = state is CardScannerLoading;

    return [
      const ScanStep(label: 'Image', status: ScanStepStatus.completed),
      ScanStep(
        label: 'Analyzing', 
        status: isError ? ScanStepStatus.error : (isDone ? ScanStepStatus.completed : ScanStepStatus.active),
      ),
      ScanStep(label: 'Done', status: isDone ? ScanStepStatus.completed : ScanStepStatus.pending),
    ];
  }

  static ValidationResult _validateCardNumber(String value) {
    final clean = value.replaceAll(RegExp(r'\s+|-'), '');
    if (clean.isEmpty) {
      return const ValidationResult.warning('Card number is empty');
    }
    if (!RegExp(r'^\d+$').hasMatch(clean)) {
      return const ValidationResult.invalid('Must contain only digits, spaces, or dashes');
    }
    if (clean.length < 13) {
      return const ValidationResult.warning('Incomplete card number (minimum 13 digits)');
    }
    if (clean.length > 19) {
      return const ValidationResult.invalid('Card number is too long (maximum 19 digits)');
    }

    if (clean.length != 13 && clean.length != 15 && clean.length != 16 && clean.length != 19) {
      return ValidationResult.warning('Non-standard card length (${clean.length} digits)');
    }

    final isLuhn = LuhnValidator.validate(clean);
    if (!isLuhn) {
      return const ValidationResult.invalid('Failed Luhn checksum verification');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult _validateExpiryDate(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      return const ValidationResult.warning('Expiry date is empty');
    }

    final parts = clean.split('/');
    if (parts.length != 2) {
      return const ValidationResult.warning('Use MM/YY or MM/YYYY format');
    }

    final monthStr = parts[0].trim();
    final yearStr = parts[1].trim();

    if (monthStr.isEmpty || yearStr.isEmpty) {
      return const ValidationResult.warning('Incomplete expiry date');
    }

    if (!RegExp(r'^\d+$').hasMatch(monthStr) || !RegExp(r'^\d+$').hasMatch(yearStr)) {
      return const ValidationResult.invalid('Expiry must contain only digits and /');
    }

    if (monthStr.length < 2 || yearStr.length < 2) {
      return const ValidationResult.warning('Incomplete format (use MM/YY)');
    }

    final month = int.tryParse(monthStr);
    if (month == null || month < 1 || month > 12) {
      return const ValidationResult.invalid('Month must be between 01 and 12');
    }

    if (yearStr.length != 2 && yearStr.length != 4) {
      return const ValidationResult.invalid('Year must be 2 or 4 digits');
    }

    final year = int.tryParse(yearStr);
    if (year != null) {
      final fullYear = yearStr.length == 2 ? 2000 + year : year;
      if (fullYear < 2000 || fullYear > 2099) {
        return const ValidationResult.invalid('Invalid expiry year (use 2000-2099)');
      }
    }

    return const ValidationResult.valid();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CardScannerCubit>();
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: BackButton(
          onPressed: () => context.pop(),
          color: theme.colorScheme.onSurface,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {},
            color: theme.colorScheme.onSurface,
          ),
        ],
      ),
      body: BlocBuilder<CardScannerCubit, CardScannerState>(
        builder: (context, state) {
          final isLoading = state is CardScannerLoading;

          return Container(
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 60, 24, 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScanImagePreview(
                          imageFile: cubit.scannedImageFile,
                          onClear: cubit.reset,
                          isLoading: isLoading,
                        ),
                        if (cubit.scannedImageFile != null)
                          const SizedBox(height: 8),
                        if (cubit.scannedImageFile != null)
                          ScanTimeline(steps: _getSteps(state)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _buildStateContent(context, state, cubit),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomActions(context, cubit),
    );
  }

  Widget _buildBottomActions(BuildContext context, CardScannerCubit cubit) {
    final theme = Theme.of(context);
    
    return BlocBuilder<CardScannerCubit, CardScannerState>(
      builder: (context, state) {
        if (state is CardScannerLoading) return const SizedBox.shrink();
        
        final isInitial = state is CardScannerInitial;
        final isFailure = state is CardScannerFailure;

        return Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isInitial) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: cubit.scanCardFromGallery,
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: cubit.scanCardFromCamera,
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Camera'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (isFailure) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: cubit.reset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('BACK TO SCANNER'),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: cubit.reset,
                        child: const Text('RESCAN'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => context.pop(),
                        child: const Text('SAVE CARD'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStateContent(
    BuildContext context,
    CardScannerState state,
    CardScannerCubit cubit,
  ) {
    final theme = Theme.of(context);

    if (state is CardScannerInitial) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Scan your card',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'The scanner will automatically extract\nthe card number and expiry date.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          _StepIndicator(
            steps: const [
              'Position card in frame',
              'Hold steady for a moment',
              'Review extracted data',
            ],
            theme: theme,
          ),
        ],
      );
    }

    if (state is CardScannerSuccess || state is CardScannerPartialSuccess) {
      final data = state is CardScannerSuccess 
          ? (state as CardScannerSuccess).data 
          : (state as CardScannerPartialSuccess).data;
      final isPartial = state is CardScannerPartialSuccess;
      
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Scan Result', style: theme.textTheme.titleMedium),
                if (!isPartial)
                  const _ConfidenceBadge()
                else
                  _WarningBadge(theme: theme),
              ],
            ),
            const SizedBox(height: 20),
            ResultTile(
              label: 'Card Number',
              value: data.cardNumber,
              icon: Icons.credit_card_rounded,
              validator: _validateCardNumber,
            ),
            ResultTile(
              label: 'Expiry Date',
              value: data.expiryDate,
              icon: Icons.calendar_today_rounded,
              validator: _validateExpiryDate,
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    if (state is CardScannerFailure) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: ScanErrorView(
          errorMessage: state.message,
          onRetry: cubit.reset,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: const Color(0xFF10B981)),
          const SizedBox(width: 6),
          Text(
            'HIGH CONFIDENCE',
            style: TextStyle(
              color: const Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBadge extends StatelessWidget {
  final ThemeData theme;
  const _WarningBadge({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'REVIEW REQUIRED',
        style: TextStyle(
          color: theme.colorScheme.tertiary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final List<String> steps;
  final ThemeData theme;

  const _StepIndicator({required this.steps, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                steps[index],
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
