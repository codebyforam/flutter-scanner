import 'package:flutter/material.dart';

enum ScanStepStatus { pending, active, completed, error }

class ScanStep {
  final String label;
  final ScanStepStatus status;

  const ScanStep({required this.label, required this.status});
}

class ScanTimeline extends StatelessWidget {
  final List<ScanStep> steps;

  const ScanTimeline({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stepWidth = constraints.maxWidth / steps.length;
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;

              return SizedBox(
                width: stepWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Lead line
                        Expanded(
                          child: index == 0 
                            ? const SizedBox.shrink() 
                            : _AnimatedLine(
                                active: steps[index - 1].status == ScanStepStatus.completed,
                              ),
                        ),
                        
                        _AnimatedStepCircle(status: step.status),
                        
                        // Tail line
                        Expanded(
                          child: isLast 
                            ? const SizedBox.shrink() 
                            : _AnimatedLine(
                                active: step.status == ScanStepStatus.completed,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: _getTextColor(step.status),
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        }
      ),
    );
  }

  Color _getTextColor(ScanStepStatus status) {
    switch (status) {
      case ScanStepStatus.completed:
        return const Color(0xFF10B981);
      case ScanStepStatus.active:
        return const Color(0xFF6366F1);
      case ScanStepStatus.error:
        return const Color(0xFFEF4444);
      case ScanStepStatus.pending:
        return const Color(0xFF94A3B8);
    }
  }
}

class _AnimatedLine extends StatelessWidget {
  final bool active;

  const _AnimatedLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _AnimatedStepCircle extends StatelessWidget {
  final ScanStepStatus status;

  const _AnimatedStepCircle({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasShadow = status == ScanStepStatus.active || status == ScanStepStatus.error;
    
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: hasShadow ? [
          BoxShadow(
            color: (status == ScanStepStatus.active ? theme.colorScheme.primary : theme.colorScheme.error)
                .withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ] : [],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getBgColor(theme),
          border: _getBorder(theme),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: _buildIcon(theme),
          ),
        ),
      ),
    );
  }

  Color _getBgColor(ThemeData theme) {
    switch (status) {
      case ScanStepStatus.completed: return theme.colorScheme.secondary;
      case ScanStepStatus.error: return theme.colorScheme.error.withValues(alpha: 0.9);
      case ScanStepStatus.active: return Colors.white;
      case ScanStepStatus.pending: return const Color(0xFFF8FAFC);
    }
  }

  Border? _getBorder(ThemeData theme) {
    if (status == ScanStepStatus.active) {
      return Border.all(color: theme.colorScheme.primary, width: 2.5);
    }
    if (status == ScanStepStatus.pending) {
      return Border.all(color: const Color(0xFFE2E8F0), width: 1.5);
    }
    if (status == ScanStepStatus.error) {
      return Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2), width: 3);
    }
    return null;
  }

  Widget _buildIcon(ThemeData theme) {
    switch (status) {
      case ScanStepStatus.completed:
        return const Icon(Icons.check_rounded, 
            key: ValueKey('check'), size: 16, color: Colors.white);
      case ScanStepStatus.error:
        return const Icon(Icons.close_rounded, 
            key: ValueKey('error'), size: 16, color: Colors.white);
      case ScanStepStatus.active:
        return Padding(
          key: const ValueKey('spinner'),
          padding: const EdgeInsets.all(6.0),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        );
      case ScanStepStatus.pending:
        return Container(key: const ValueKey('empty'));
    }
  }
}
