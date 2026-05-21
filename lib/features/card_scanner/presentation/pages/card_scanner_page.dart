import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ocr/core/utils/luhn_validator.dart';
import 'package:flutter_ocr/features/card_scanner/cubit/card_scanner_cubit.dart';
import 'package:flutter_ocr/features/card_scanner/cubit/card_scanner_state.dart';
import 'package:flutter_ocr/shared/widgets/result_tile.dart';
import 'package:flutter_ocr/shared/widgets/scan_error_view.dart';
import 'package:flutter_ocr/shared/widgets/scan_image_preview.dart';

class CardScannerPage extends StatelessWidget {
  const CardScannerPage({super.key});

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

    // Standard length checks
    if (clean.length != 13 && clean.length != 15 && clean.length != 16 && clean.length != 19) {
      return ValidationResult.warning('Non-standard card length (${clean.length} digits)');
    }

    // Luhn validation runs only when structurally complete to prevent validation flickering
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
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CardScannerCubit>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cubit.reset,
          ),
        ],
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<CardScannerCubit, CardScannerState>(
            builder: (context, state) {
              final isLoading = state is CardScannerLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScanImagePreview(
                      imageFile: cubit.scannedImageFile,
                      onClear: cubit.reset,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      child: _buildStateContent(context, state, cubit),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BlocBuilder<CardScannerCubit, CardScannerState>(
        builder: (context, state) {
          if (state is CardScannerLoading) return const SizedBox.shrink();
          final theme = Theme.of(context);

          return SafeArea(
            child: Container(
              color: theme.colorScheme.surfaceContainerLowest,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Scans are processed securely on-device',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: cubit.scanCardFromGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: cubit.scanCardFromCamera,
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Scan with Camera'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateContent(
    BuildContext context,
    CardScannerState state,
    CardScannerCubit cubit,
  ) {
    final theme = Theme.of(context);

    if (state is CardScannerInitial) {
      return const _EmptyPrompt(
        key: ValueKey('initial'),
        icon: Icons.credit_card_rounded,
        title: 'Scan Your Card',
        subtitle: 'Point your camera at a credit or debit card, or pick an image from your gallery.',
      );
    }

    if (state is CardScannerLoading) {
      return const SizedBox.shrink(key: ValueKey('loading'));
    }

    if (state is CardScannerFailure) {
      return ScanErrorView(
        key: const ValueKey('error'),
        errorMessage: state.message,
        onRetry: cubit.reset,
      );
    }

    if (state is CardScannerSuccess) {
      return Column(
        key: const ValueKey('success'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isDuplicate) _DuplicateBanner(theme: theme),
          _SectionHeader(title: 'Extracted Details', isPartial: false, theme: theme),
          Card(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ResultTile(
                    label: 'Card Number',
                    value: state.data.cardNumber,
                    icon: Icons.credit_card_rounded,
                    validator: _validateCardNumber,
                  ),
                  const SizedBox(height: 8),
                  ResultTile(
                    label: 'Expiry Date',
                    value: state.data.expiryDate,
                    icon: Icons.date_range_rounded,
                    validator: _validateExpiryDate,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (state is CardScannerPartialSuccess) {
      return Column(
        key: const ValueKey('partial'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isDuplicate) _DuplicateBanner(theme: theme),
          _SectionHeader(title: 'Extracted with Warnings', isPartial: true, theme: theme),
          Card(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ResultTile(
                    label: 'Card Number',
                    value: state.data.cardNumber,
                    icon: Icons.credit_card_rounded,
                    validator: _validateCardNumber,
                  ),
                  const SizedBox(height: 8),
                  ResultTile(
                    label: 'Expiry Date',
                    value: state.data.expiryDate,
                    icon: Icons.date_range_rounded,
                    validator: _validateExpiryDate,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink(key: ValueKey('fallback'));
  }
}

// ── Reusable private sub-widgets ──────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyPrompt({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isPartial;
  final ThemeData theme;

  const _SectionHeader({
    required this.title,
    required this.isPartial,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (isPartial)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: theme.colorScheme.tertiary,
              ),
            ),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPartial ? theme.colorScheme.tertiary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateBanner extends StatelessWidget {
  final ThemeData theme;

  const _DuplicateBanner({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.copy_rounded, size: 18, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This image was already scanned. Showing cached results.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
