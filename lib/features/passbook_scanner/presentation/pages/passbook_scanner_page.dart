import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ocr/features/passbook_scanner/cubit/passbook_scanner_cubit.dart';
import 'package:flutter_ocr/features/passbook_scanner/cubit/passbook_scanner_state.dart';
import 'package:flutter_ocr/shared/widgets/result_tile.dart';
import 'package:flutter_ocr/shared/widgets/scan_error_view.dart';
import 'package:flutter_ocr/shared/widgets/scan_image_preview.dart';
import 'package:flutter_ocr/shared/widgets/scan_timeline.dart';
import 'package:go_router/go_router.dart';

class PassbookScannerPage extends StatelessWidget {
  const PassbookScannerPage({super.key});

  List<ScanStep> _getSteps(PassbookScannerState state) {
    if (state is PassbookScannerInitial) {
      return [
        const ScanStep(label: 'Image', status: ScanStepStatus.pending),
        const ScanStep(label: 'Analyzing', status: ScanStepStatus.pending),
        const ScanStep(label: 'Done', status: ScanStepStatus.pending),
      ];
    }
    
    final isError = state is PassbookScannerFailure;
    final isDone = state is PassbookScannerSuccess || state is PassbookScannerPartialSuccess;
    final isLoading = state is PassbookScannerLoading;

    return [
      const ScanStep(label: 'Image', status: ScanStepStatus.completed),
      ScanStep(
        label: 'Analyzing', 
        status: isError ? ScanStepStatus.error : (isDone ? ScanStepStatus.completed : ScanStepStatus.active),
      ),
      ScanStep(label: 'Done', status: isDone ? ScanStepStatus.completed : ScanStepStatus.pending),
    ];
  }

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

  static ValidationResult _validateAccountHolderName(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      return const ValidationResult.warning('Account holder name is empty');
    }
    if (RegExp(r'\d').hasMatch(clean)) {
      return const ValidationResult.invalid('Name should not contain digits');
    }
    if (clean.length < 3) {
      return const ValidationResult.warning('Name is too short');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult _validateIfscCode(String value) {
    var clean = value.trim().toUpperCase().replaceAll(RegExp(r'\s+|-'), '');

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
  Widget build(BuildContext context) {
    final cubit = context.read<PassbookScannerCubit>();
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
      body: BlocBuilder<PassbookScannerCubit, PassbookScannerState>(
        builder: (context, state) {
          final isLoading = state is PassbookScannerLoading;

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

  Widget _buildBottomActions(BuildContext context, PassbookScannerCubit cubit) {
    final theme = Theme.of(context);
    
    return BlocBuilder<PassbookScannerCubit, PassbookScannerState>(
      builder: (context, state) {
        if (state is PassbookScannerLoading) return const SizedBox.shrink();
        
        final isInitial = state is PassbookScannerInitial;
        final isFailure = state is PassbookScannerFailure;

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
                        onPressed: cubit.scanPassbookFromGallery,
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
                        onPressed: cubit.scanPassbookFromCamera,
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
                        child: const Text('SAVE DETAILS'),
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
    PassbookScannerState state,
    PassbookScannerCubit cubit,
  ) {
    final theme = Theme.of(context);

    if (state is PassbookScannerInitial) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Scan your Passbook',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'The scanner will automatically extract\naccount holder name, number and IFSC.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          _StepIndicator(
            steps: const [
              'Find account details page',
              'Align text within the frame',
              'Verify extracted information',
            ],
            theme: theme,
          ),
        ],
      );
    }

    if (state is PassbookScannerSuccess || state is PassbookScannerPartialSuccess) {
      final data = state is PassbookScannerSuccess 
          ? (state as PassbookScannerSuccess).data 
          : (state as PassbookScannerPartialSuccess).data;
      final isPartial = state is PassbookScannerPartialSuccess;
      final isDuplicate = state is PassbookScannerSuccess 
          ? (state as PassbookScannerSuccess).isDuplicate 
          : (state as PassbookScannerPartialSuccess).isDuplicate;
      
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Scan Result', style: theme.textTheme.titleMedium),
                Row(
                  children: [
                    if (isDuplicate)
                      const _DuplicateBadge(),
                    const SizedBox(width: 8),
                    if (!isPartial)
                      const _ConfidenceBadge()
                    else
                      _WarningBadge(theme: theme),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ResultTile(
              label: 'Account Holder',
              value: data.accountHolderName,
              icon: Icons.person_rounded,
              validator: _validateAccountHolderName,
            ),
            ResultTile(
              label: 'Account Number',
              value: data.accountNo,
              icon: Icons.account_balance_wallet_rounded,
              validator: _validateAccountNumber,
            ),
            ResultTile(
              label: 'IFSC Code',
              value: data.ifscCode,
              icon: Icons.domain_rounded,
              validator: _validateIfscCode,
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    if (state is PassbookScannerFailure) {
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

class _DuplicateBadge extends StatelessWidget {
  const _DuplicateBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'DUPLICATE',
        style: TextStyle(
          color: theme.colorScheme.outline,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
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
