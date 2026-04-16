import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:roadwatch/splash_screen.dart';
import 'package:roadwatch/theme/app_theme.dart';
import 'package:roadwatch/theme/theme_provider.dart';

Completer<AndroidMapRenderer?>? _initializedRendererCompleter;

Future<AndroidMapRenderer?> initializeMapRenderer() async {
  if (_initializedRendererCompleter != null) {
    return _initializedRendererCompleter!.future;
  }

  final completer = Completer<AndroidMapRenderer?>();
  _initializedRendererCompleter = completer;

  final mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    // CRITICAL FIX: Force Hybrid Composition - THIS KILLS BLASTBufferQueue SPAM
    mapsImplementation.useAndroidViewSurface = true;

    // Initialize the LATEST renderer
    unawaited(
      mapsImplementation
          .initializeWithRenderer(AndroidMapRenderer.latest)
          .then((initializedRenderer) {
        completer.complete(initializedRenderer);
      }),
    );
  } else {
    completer.complete(null);
  }
  return completer.future;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============ ADD THIS BLOCK ============
  // NOTE: Flutter web doesn't support dart:io, so we avoid Platform.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      // CRITICAL: Force Hybrid Composition - THIS IS THE OFFICIAL FIX
      mapsImplementation.useAndroidViewSurface = true;
      // Initialize renderer BEFORE creating any GoogleMap widgets
      await initializeMapRenderer();
    }
  }
  // ========================================

  // Load Poppins font
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: themeProvider)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;

        // Handle system theme
        if (themeProvider.themeMode == ThemeMode.system) {
          final brightness = MediaQuery.of(context).platformBrightness;
          return _buildAnimatedApp(brightness == Brightness.dark);
        }

        return _buildAnimatedApp(isDarkMode);
      },
    );
  }

  Widget _buildAnimatedApp(bool isDarkMode) {
    return AnimatedTheme(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      data: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      child: MaterialApp(
        title: 'RoadWatch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: kIsWeb ? const WebSplashLoader() : const SplashScreen(),
      ),
    );
  }
}

// Lightweight splash loader for Web to mask slow rendering startup
class WebSplashLoader extends StatefulWidget {
  const WebSplashLoader({super.key});

  @override
  State<WebSplashLoader> createState() => _WebSplashLoaderState();
}

class _WebSplashLoaderState extends State<WebSplashLoader> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          createRoute(const SplashScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// Professional Animation route wrappers
Route createRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

// Slide from right animation
Route slideFromRightRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      // Secondary animation for pop transition
      var secondaryTween = Tween(
        begin: Offset.zero,
        end: const Offset(0.3, 0.0),
      ).chain(CurveTween(curve: Curves.easeInCubic));

      return SlideTransition(
        position: animation.drive(tween),
        child: SlideTransition(
          position: secondaryAnimation.drive(secondaryTween),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 450),
  );
}

// Scale and fade animation
Route scaleAndFadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var scaleAnimation = Tween<double>(
        begin: 0.88,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      var fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(opacity: fadeAnimation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

// Slide from bottom with scale animation
Route slideFromBottomWithScaleRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      var scaleAnimation = Tween<double>(
        begin: 0.92,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(tween),
        child: ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(opacity: animation, child: child),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}
