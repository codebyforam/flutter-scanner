import 'package:flutter/material.dart';

enum ValidationStatus {
  valid,
  invalid,
  warning,
}

class ValidationResult {
  final ValidationStatus status;
  final String? message;

  const ValidationResult({
    required this.status,
    this.message,
  });

  const ValidationResult.valid() : status = ValidationStatus.valid, message = null;

  const ValidationResult.invalid(String msg) : status = ValidationStatus.invalid, message = msg;

  const ValidationResult.warning(String msg) : status = ValidationStatus.warning, message = msg;
}

class ResultTile extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final ValidationResult Function(String)? validator;
  final bool isValid;
  final String? warning;

  const ResultTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.validator,
    this.isValid = true,
    this.warning,
  });

  @override
  State<ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<ResultTile> {
  late TextEditingController _controller;
  late ValidationResult _validationResult;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _validate(widget.value);
  }

  @override
  void didUpdateWidget(covariant ResultTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value;
      _validate(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate(String val) {
    if (widget.validator != null) {
      _validationResult = widget.validator!(val);
    } else {
      // Legacy compatibility mode
      if (!widget.isValid) {
        _validationResult = const ValidationResult.invalid('Invalid parsed value');
      } else if (widget.warning != null) {
        _validationResult = ValidationResult.warning(widget.warning!);
      } else {
        _validationResult = const ValidationResult.valid();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final warningColor = theme.colorScheme.onTertiaryContainer;
    final warningBgColor = theme.colorScheme.tertiaryContainer;

    final status = _validationResult.status;
    final message = _validationResult.message;

    final isError = status == ValidationStatus.invalid;
    final isWarning = status == ValidationStatus.warning;
    final isValid = status == ValidationStatus.valid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isError ? errorColor : null,
              letterSpacing: 1.2,
            ),
            onChanged: (val) {
              setState(() {
                _validate(val);
              });
            },
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: Icon(
                widget.icon,
                color: isError ? errorColor : (isWarning ? warningColor : theme.colorScheme.primary),
              ),
              filled: true,
              fillColor: isError ? errorColor.withValues(alpha: 0.05) : (isWarning ? warningBgColor : theme.colorScheme.surfaceContainerHigh),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isError ? errorColor.withValues(alpha: 0.5) : (isWarning ? warningColor.withValues(alpha: 0.3) : Colors.transparent),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isError ? errorColor : (isWarning ? warningColor : theme.colorScheme.primary),
                  width: 2,
                ),
              ),
              suffixIcon: isValid ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.edit_outlined, size: 20),
            ),
          ),
          if (message != null && isError) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 16, color: errorColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (message != null && isWarning) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.security_update_warning_outlined, size: 16, color: warningColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
