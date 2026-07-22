import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme_config.dart';

class CreateMoodboardDialog extends StatefulWidget {
  final Function(String name) onCreate;

  const CreateMoodboardDialog({super.key, required this.onCreate});

  @override
  State<CreateMoodboardDialog> createState() => _CreateMoodboardDialogState();
}

class _CreateMoodboardDialogState extends State<CreateMoodboardDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = context.vivek;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: v.surfaceContainer.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: v.glassBorder.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dashboard_customize_rounded, size: 40, color: cs.primary)
                  .animate().fade(duration: 400.ms).scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text('NEW MOODBOARD', style: GoogleFonts.oswald(fontSize: 22, color: cs.onSurface, fontWeight: FontWeight.bold, letterSpacing: 1.5))
                  .animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  style: GoogleFonts.inter(color: cs.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g. Minimal, Dark, Abstract...',
                    hintStyle: GoogleFonts.inter(color: v.onSurfaceFaint, fontSize: 14),
                    filled: true,
                    fillColor: v.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: v.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: v.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ).animate().fade(duration: 400.ms, delay: 180.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: v.glassBorder.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text('CANCEL', style: GoogleFonts.inter(color: v.onSurfaceSubtle, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final name = _controller.text.trim();
                          if (name.isNotEmpty) {
                            widget.onCreate(name);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('CREATE', style: GoogleFonts.inter(color: cs.onPrimary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(duration: 400.ms, delay: 260.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
