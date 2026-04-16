import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roadwatch/LoginScreen.dart';
import 'package:roadwatch/admin_dashboard.dart';
import 'package:roadwatch/home_screen.dart';
import 'package:roadwatch/services/storage_service.dart';
import 'theme_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final isDemo = await StorageService.isDemoMode();
      final token = await StorageService.getToken();
      final role = await StorageService.getRole();

      Widget nextScreen;
      if (isDemo) {
        nextScreen = const HomeScreen();
      } else if (token != null && token.isNotEmpty) {
        if (role == 'admin') {
          nextScreen = const AdminDashboard();
        } else {
          nextScreen = const HomeScreen();
        }
      } else {
        nextScreen = const LoginScreen();
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation or Icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.assistant_navigation,
                  size: 70,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // App Name with Fade Transition
            FadeTransition(
              opacity: _textAnimation,
              child: Text(
                'RoadWatch',
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  height: 1.2,
                ),
              ),
            ),

            // Tagline with Staggered Animation
            AnimatedOpacity(
              opacity: _fadeAnimation.value,
              duration: const Duration(milliseconds: 800),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Smart Road Monitoring System',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Animated Progress Indicator
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _controller.value,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                borderRadius: BorderRadius.circular(10),
                minHeight: 4,
              ),
            ),

            const SizedBox(height: 16),

            // Loading Text with Pulse Animation
            AnimatedOpacity(
              opacity: _fadeAnimation.value,
              duration: const Duration(milliseconds: 500),
              child: Text(
                'Initializing...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
