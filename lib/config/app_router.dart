import 'package:go_router/go_router.dart';
import 'package:skillresy/screens/auth/login_screen.dart';
import 'package:skillresy/screens/splash_screen.dart';

import '../screens/auth/onboarding/get_started_screen.dart';
import '../screens/auth/onboarding/onboarding_step_screen.dart';
import '../screens/main_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/profile/edit_personal_details_screen.dart';
import '../screens/profile/edit_career_goals_screen.dart';
import '../screens/profile/edit_skills_tools_screen.dart';
import '../screens/profile/edit_others_screen.dart';
import '../screens/profile/edit_education_screen.dart';
import '../screens/profile/edit_work_experience_screen.dart';
import '../screens/legal/legal_screen.dart';

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
      path: '/profile/edit-personal-details',
      builder: (context, state) => const EditPersonalDetailsScreen(),
    ),
    GoRoute(
      path: '/profile/edit-career-goals',
      builder: (context, state) => const EditCareerGoalsScreen(),
    ),
    GoRoute(
      path: '/profile/edit-skills-tools',
      builder: (context, state) => const EditSkillsToolsScreen(),
    ),
    GoRoute(
      path: '/profile/edit-others',
      builder: (context, state) => const EditOthersScreen(),
    ),
    GoRoute(
      path: '/profile/edit-education',
      builder: (context, state) => const EditEducationScreen(),
    ),
    GoRoute(
      path: '/profile/edit-work-experience',
      builder: (context, state) => const EditWorkExperienceScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const LegalScreen(title: 'Privacy Policy'),
    ),
    GoRoute(
      path: '/terms-of-use',
      builder: (context, state) => const LegalScreen(title: 'Terms of Use'),
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
