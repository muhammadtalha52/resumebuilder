import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skillresy/screens/auth/login_screen.dart';
import 'package:skillresy/screens/splash_screen.dart';

import '../screens/auth/onboarding/get_started_screen.dart';
import '../screens/auth/onboarding/onboarding_step_screen.dart';
import '../screens/main_screen.dart';
import '../screens/welcome/welcome_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/get-started',
      builder: (context, state) => const GetStartedScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const MainScreen()),
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
