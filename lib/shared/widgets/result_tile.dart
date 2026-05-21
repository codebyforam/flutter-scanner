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
  final bool isSensitive;

  const ResultTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.validator,
    this.isSensitive = false,
  });

  @override
  State<ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<ResultTile> {
  late TextEditingController _controller;
  late ValidationResult _validationResult;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _validate(widget.value);
    _obscureText = widget.isSensitive;
  }

  @override
  void didUpdateWidget(covariant ResultTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value;
      _validate(widget.value);
    }
  }

  String _getMaskedValue(String value) {
    if (value.length <= 4) return value;
    final lastFour = value.substring(value.length - 4);
    final prefix = value.substring(0, value.length - 4);
    final masked = prefix.replaceAll(RegExp(r'\d'), 'X');
    return masked + lastFour;
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
      _validationResult = const ValidationResult.valid();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final status = _validationResult.status;
    final message = _validationResult.message;

    final isError = status == ValidationStatus.invalid;
    final isWarning = status == ValidationStatus.warning;
    final isValid = status == ValidationStatus.valid;

    final statusColor = isError 
        ? theme.colorScheme.error 
        : (isWarning ? theme.colorScheme.tertiary : theme.colorScheme.secondary);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isError ? theme.colorScheme.error.withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      widget.label.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                _StatusBadge(status: status, color: statusColor),
              ],
            ),
          ),
          TextField(
            controller: _controller,
            onChanged: (val) => setState(() => _validate(val)),
            obscureText: _obscureText,
            obscuringCharacter: 'X',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              letterSpacing: 2,
              fontFamily: 'monospace', // Use monospace for numbers
            ),
            decoration: InputDecoration(
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              suffixIcon: widget.isSensitive
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    )
                  : null,
            ),
          ),
          if (message != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ValidationStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    String text = 'VALID';
    IconData icon = Icons.check_circle_rounded;
    
    if (status == ValidationStatus.invalid) {
      text = 'INVALID';
      icon = Icons.cancel_rounded;
    } else if (status == ValidationStatus.warning) {
      text = 'CHECK';
      icon = Icons.error_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
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

