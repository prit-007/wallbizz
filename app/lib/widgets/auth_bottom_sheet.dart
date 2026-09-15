import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme_config.dart';
import '../services/sync_service.dart';
import '../services/wallpaper_actions.dart';
import '../screens/verify_email_screen.dart';
import '../screens/forgot_password_screen.dart';

void showAuthBottomSheet(BuildContext context, {VoidCallback? onDismissed}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) => AuthBottomSheet(onDismissed: onDismissed),
  ).then((_) => onDismissed?.call());
}

class AuthBottomSheet extends StatefulWidget {
  final VoidCallback? onDismissed;
  const AuthBottomSheet({super.key, this.onDismissed});

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          if (response.user?.emailConfirmedAt == null) {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    VerifyEmailScreen(email: _emailController.text.trim()),
              ),
            );
          } else {
            WallpaperActions.onAuthSuccess();
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) SyncService.onAuthStateChanged(user.id);
            Navigator.of(context).pop();
          }
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user?.emailConfirmedAt == null) {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    VerifyEmailScreen(email: _emailController.text.trim()),
              ),
            );
          } else {
            WallpaperActions.onAuthSuccess();
            if (user != null) SyncService.onAuthStateChanged(user.id);
            Navigator.of(context).pop();
          }
        }
      }
    } on AuthException catch (e) {
      final message = e.message;
      if (mounted) {
        if (message.contains('Email not confirmed') ||
            message.contains('email_not_confirmed')) {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  VerifyEmailScreen(email: _emailController.text.trim()),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      final redirectTo = kIsWeb ? null : 'wallbizz://callback';
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
      if (mounted) {
        WallpaperActions.onAuthSuccess();
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) SyncService.onAuthStateChanged(user.id);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: vk.glassBorder.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: vk.onSurfaceFaint,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.5, end: 0),
              const SizedBox(height: 32),
              Text(
                    _isSignUp ? 'JOIN THE CLUB' : 'WELCOME BACK',
                    style: GoogleFonts.oswald(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                      letterSpacing: 2.5,
                    ),
                  )
                  .animate()
                  .fade(duration: 400.ms, delay: 80.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 4),
              Text(
                    'Sync your curated collection across all devices.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: vk.onSurfaceSubtle,
                    ),
                  )
                  .animate()
                  .fade(duration: 400.ms, delay: 120.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 32),

              _TactileButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: cs.onSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedSmartPhone01,
                            size: 28,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: cs.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fade(duration: 400.ms, delay: 170.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: vk.glassBorder.withValues(alpha: 0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: GoogleFonts.inter(
                        color: vk.onSurfaceSubtle,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: vk.glassBorder.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ).animate().fade(duration: 400.ms, delay: 220.ms),
              const SizedBox(height: 24),

              _buildTextField(
                    controller: _emailController,
                    hint: 'Email Address',
                    icon: HugeIcons.strokeRoundedMailAtSign01,
                    vk: vk,
                  )
                  .animate()
                  .fade(duration: 400.ms, delay: 270.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: HugeIcons.strokeRoundedCircleLock01,
                    isPassword: true,
                    vk: vk,
                  )
                  .animate()
                  .fade(duration: 400.ms, delay: 320.ms)
                  .slideY(begin: 0.2, end: 0),

              if (!_isSignUp)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.inter(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fade(duration: 400.ms, delay: 370.ms),

              const SizedBox(height: 16),

              _TactileButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: cs.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  )
                  .animate()
                  .fade(duration: 400.ms, delay: 420.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _isSignUp = !_isSignUp),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        color: vk.onSurfaceSubtle,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: _isSignUp
                              ? 'Already have an account? '
                              : "Don't have an account? ",
                        ),
                        TextSpan(
                          text: _isSignUp ? 'Sign in' : 'Create one',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fade(duration: 400.ms, delay: 470.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required dynamic icon,
    bool isPassword = false,
    required dynamic vk,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPassword
          ? TextInputType.text
          : TextInputType.emailAddress,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: vk.onSurfaceFaint),
        prefixIcon: HugeIcon(icon: icon, color: vk.onSurfaceFaint, size: 20),
        filled: true,
        fillColor: vk.surfaceContainerLow.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: vk.glassBorder.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _TactileButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _TactileButton({required this.onPressed, required this.child});

  @override
  State<_TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<_TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
