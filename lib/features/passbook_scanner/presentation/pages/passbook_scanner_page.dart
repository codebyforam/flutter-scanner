import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ocr/features/passbook_scanner/cubit/passbook_scanner_cubit.dart';
import 'package:flutter_ocr/features/passbook_scanner/cubit/passbook_scanner_state.dart';
import 'package:flutter_ocr/shared/widgets/result_tile.dart';
import 'package:flutter_ocr/shared/widgets/scan_error_view.dart';
import 'package:flutter_ocr/shared/widgets/scan_image_preview.dart';

class PassbookScannerPage extends StatelessWidget {
  const PassbookScannerPage({super.key});

  static ValidationResult _validateAccountNumber(String value) {
    final clean = value.replaceAll(RegExp(r'\s+|-'), '');
    if (clean.isEmpty) {
      return const ValidationResult.warning('Account number is empty');
    }
    if (!RegExp(r'^\d+$').hasMatch(clean)) {
      return const ValidationResult.invalid('Account number must contain only digits');
    }
    if (clean.length < 9) {
      return const ValidationResult.warning('Incomplete account number (minimum 9 digits)');
    }
    if (clean.length > 18) {
      return const ValidationResult.invalid('Account number too long (maximum 18 digits)');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult _validateIfscCode(String value) {
    var clean = value.trim().toUpperCase().replaceAll(RegExp(r'\s+|-'), '');

    // Normalize O->0 specifically at index 4 if length >= 5
    if (clean.length >= 5 && clean[4] == 'O') {
      clean = '${clean.substring(0, 4)}0${clean.substring(5)}';
    }

    if (clean.isEmpty) {
      return const ValidationResult.warning('IFSC code is empty');
    }

    if (clean.length < 11) {
      return const ValidationResult.warning('Incomplete IFSC code (must be 11 characters)');
    }
    if (clean.length > 11) {
      return const ValidationResult.invalid('IFSC code is too long (must be 11 characters)');
    }

    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscRegex.hasMatch(clean)) {
      return const ValidationResult.invalid('Invalid IFSC format (e.g. SBIN0001234)');
    }

    return const ValidationResult.valid();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PassbookScannerCubit>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passbook Scanner'),
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
          child: BlocBuilder<PassbookScannerCubit, PassbookScannerState>(
            builder: (context, state) {
              final isLoading = state is PassbookScannerLoading;

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
      bottomNavigationBar: BlocBuilder<PassbookScannerCubit, PassbookScannerState>(
        builder: (context, state) {
          if (state is PassbookScannerLoading) return const SizedBox.shrink();
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
                          onPressed: cubit.scanPassbookFromGallery,
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
                          onPressed: cubit.scanPassbookFromCamera,
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
    PassbookScannerState state,
    PassbookScannerCubit cubit,
  ) {
    final theme = Theme.of(context);

    if (state is PassbookScannerInitial) {
      return const _EmptyPrompt(
        key: ValueKey('initial'),
        icon: Icons.account_balance_wallet_rounded,
        title: 'Scan Your Passbook',
        subtitle: 'Point your camera at the bank details page, or pick an image from your gallery.',
      );
    }

    if (state is PassbookScannerLoading) {
      return const SizedBox.shrink(key: ValueKey('loading'));
    }

    if (state is PassbookScannerFailure) {
      return ScanErrorView(
        key: const ValueKey('error'),
        errorMessage: state.message,
        onRetry: cubit.reset,
      );
    }

    if (state is PassbookScannerSuccess) {
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
                    label: 'Account Number',
                    value: state.data.accountNo,
                    icon: Icons.account_balance_wallet_rounded,
                    validator: _validateAccountNumber,
                  ),
                  const SizedBox(height: 8),
                  ResultTile(
                    label: 'IFSC Code',
                    value: state.data.ifscCode,
                    icon: Icons.domain_rounded,
                    validator: _validateIfscCode,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (state is PassbookScannerPartialSuccess) {
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
                    label: 'Account Number',
                    value: state.data.accountNo,
                    icon: Icons.account_balance_wallet_rounded,
                    validator: _validateAccountNumber,
                  ),
                  const SizedBox(height: 8),
                  ResultTile(
                    label: 'IFSC Code',
                    value: state.data.ifscCode,
                    icon: Icons.domain_rounded,
                    validator: _validateIfscCode,
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
