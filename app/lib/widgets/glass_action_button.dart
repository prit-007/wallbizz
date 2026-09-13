import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isDownloading;
  final bool isDownloaded;
  final String label;
  final dynamic icon;
  final Color backgroundColor;
  final Color textColor;

  const GlassActionButton({
    super.key,
    required this.onPressed,
    required this.isDownloading,
    required this.isDownloaded,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  State<GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<GlassActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDownloaded
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isDownloading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.textColor,
                  ),
                )
              else
                HugeIcon(icon: widget.icon, color: widget.textColor, size: 20),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: widget.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FrostedCircleButton extends StatefulWidget {
  final dynamic icon;
  final VoidCallback onTap;
  final Color iconColor;

  const FrostedCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  State<FrostedCircleButton> createState() => _FrostedCircleButtonState();
}

class _FrostedCircleButtonState extends State<FrostedCircleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: HugeIcon(
                icon: widget.icon,
                color: widget.iconColor,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
