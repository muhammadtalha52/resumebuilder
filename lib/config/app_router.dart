import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skillresy/screens/auth/login_screen.dart';
import 'package:skillresy/screens/onboarding/get_started_screen.dart';
import 'package:skillresy/screens/onboarding/onboarding_step_screen.dart';
import 'package:skillresy/screens/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/home',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Home Screen - Coming Soon')),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const GetStartedScreen(),
      routes: [
        GoRoute(
          path: 'step/:stepNumber',
          builder: (context, state) {
            final stepNumber =
                int.tryParse(state.pathParameters['stepNumber'] ?? '1') ?? 1;
            return OnboardingStepScreen(stepNumber: stepNumber);
          },
        ),
      ],
    ),
  ],
);
