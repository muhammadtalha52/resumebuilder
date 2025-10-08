import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../../services/app_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Navigate to next screen after delay
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Initialize app logic (loads token and user data)
    await appLogic.init();

    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check if user is already logged in
    if (appLogic.accessToken.isNotEmpty && appLogic.user != null) {
      // User is logged in - go to home
      context.go('/home');
      return;
    }

    // Check if this is the first time user opens the app
    final hasSeenWelcome = await AppPreferences.hasSeenWelcome();

    if (hasSeenWelcome) {
      // Returning user but not logged in - go to login
      context.go('/login');
    } else {
      // First time user - show welcome screens
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background pattern
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Logo
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive sizing for tablets and phones
                  double logoWidth = constraints.maxWidth < 600
                      ? constraints.maxWidth *
                            0.75 // Mobile: 75% of screen width
                      : constraints.maxWidth *
                            0.5; // Tablet: 50% of screen width

                  // Maximum width limit
                  logoWidth = logoWidth.clamp(250.0, 500.0);

                  return Image.asset(
                    'assets/icons/logo-fox-on-left.png',
                    width: logoWidth,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
