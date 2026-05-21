import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

class ScanImagePreview extends StatefulWidget {
  final File? imageFile;
  final VoidCallback? onClear;
  final bool isLoading;

  const ScanImagePreview({
    super.key,
    required this.imageFile,
    this.onClear,
    this.isLoading = false,
  });

  @override
  State<ScanImagePreview> createState() => _ScanImagePreviewState();
}

class _ScanImagePreviewState extends State<ScanImagePreview> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isLoading) {
      _scanController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ScanImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _scanController.repeat(reverse: true);
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _scanController.stop();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: 1.58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.imageFile == null)
                _buildPlaceholder(theme, primaryColor)
              else
                _buildImage(theme),
              if (widget.isLoading) _buildScanningOverlay(primaryColor),
              if (widget.imageFile != null && widget.onClear != null && !widget.isLoading)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _BlurButton(
                    onPressed: widget.onClear!,
                    icon: Icons.close_rounded,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.surfaceContainerLow,
          ],
        ),
      ),
      child: Stack(
        children: [
          _buildCorners(primaryColor),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_rounded,
                    size: 32,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ready to Scan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Place card inside the frame',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(widget.imageFile!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildScanningOverlay(Color primaryColor) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return Stack(
          children: [
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              top: _scanController.value * (MediaQuery.of(context).size.width / 1.58),
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.8),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0),
                      primaryColor,
                      primaryColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ANALYZING CARD...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorners(Color color) {
    return Stack(
      children: [
        Positioned(
          top: 24,
          left: 24,
          child: _Corner(angle: 0, color: color),
        ),
        Positioned(
          top: 24,
          right: 24,
          child: _Corner(angle: 1.5708, color: color),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          child: _Corner(angle: 4.71239, color: color),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: _Corner(angle: 3.14159, color: color),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final double angle;
  final Color color;

  const _Corner({required this.angle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: 4),
            left: BorderSide(color: color, width: 4),
          ),
        ),
      ),
    );
  }
}

class _BlurButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const _BlurButton({required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black.withValues(alpha: 0.3),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

