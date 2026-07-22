import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) return;

    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background.jpg',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.3),
            colorBlendMode: BlendMode.darken,
          ).animate().fade(duration: 1200.ms, curve: Curves.easeOutCubic),

          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.2, 1.0],
              ),
            ),
          ).animate().fade(duration: 1000.ms),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CURATED 4K BACKGROUNDS & WALLPAPERS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 3.5,
                  ),
                ).animate()
                 .fade(delay: 800.ms, duration: 800.ms)
                 .slideY(begin: 0.8, end: 0, curve: Curves.easeOutCubic),

                Text(
                  'WALLBIZZ',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 90,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                    letterSpacing: 6,
                    height: 1.1,
                  ),
                ).animate()
                 .fade(delay: 400.ms, duration: 1200.ms)
                 .scale(begin: const Offset(1.05, 1.05), end: const Offset(1.0, 1.0), curve: Curves.easeOutCubic)
                 .shimmer(delay: 1500.ms, duration: 2000.ms, color: Colors.cyanAccent.withValues(alpha: 0.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
