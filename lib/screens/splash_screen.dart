import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

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

  void _navigateToNextScreen() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
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
                            0.6 // Mobile: 60% of screen width
                      : constraints.maxWidth *
                            0.4; // Tablet: 40% of screen width

                  // Maximum width limit
                  logoWidth = logoWidth.clamp(200.0, 400.0);

                  return SvgPicture.asset(
                    'assets/svg/skillresy-logo.svg',
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
