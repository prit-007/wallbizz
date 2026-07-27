import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email address'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'wallbizz://callback',
      );
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.1),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1),
                    boxShadow: [
                      BoxShadow(color: cs.primary.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 5)
                    ],
                  ),
                  child: Icon(Icons.lock_reset_rounded, size: 56, color: cs.primary),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(height: 48),
              Text(
                'RESET\nPASSWORD',
                textAlign: TextAlign.center,
                style: GoogleFonts.oswald(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                  height: 1.1,
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),
              Text(
                _sent
                    ? 'Check your inbox for the secure reset link.'
                    : 'Enter your email address and we will send you a secure link to reset your password.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: vk.onSurfaceSubtle,
                  height: 1.5,
                ),
              ).animate().fade(duration: 500.ms, delay: 100.ms),
              const SizedBox(height: 48),

              if (!_sent) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: GoogleFonts.inter(color: vk.onSurfaceFaint),
                    prefixIcon: Icon(Icons.alternate_email_rounded, color: vk.onSurfaceFaint, size: 22),
                    filled: true,
                    fillColor: vk.surfaceContainerLow.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: vk.glassBorder.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: cs.primary),
                    ),
                  ),
                ).animate().fade(duration: 500.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                        : Text(
                            'SEND RESET LINK',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                  ),
                ).animate().fade(duration: 500.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.05), blurRadius: 20)
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Link successfully sent to:\n${_emailController.text.trim()}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.greenAccent.shade100,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(duration: 400.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
              ],

              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back_rounded, size: 18, color: vk.onSurfaceSubtle),
                label: Text(
                  'BACK TO SIGN IN',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: vk.onSurfaceSubtle),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
