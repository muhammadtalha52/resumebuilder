import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skillresy/screens/auth/login_screen.dart';
import 'package:skillresy/screens/auth/forgot_password_screen.dart';
import 'package:skillresy/screens/common/splash_screen.dart';

import '../models/meeting_history_response.dart';
import '../screens/auth/onboarding_step_screen.dart';
import '../screens/auth/student_onboarding_step_screen.dart';
import '../screens/auth/user_type_selection_screen.dart';
import '../screens/candidate/interview/meeting_session_screen.dart';
import '../screens/candidate/interview/meeting_setup_screen.dart';
import '../screens/candidate/interview/meeting_detail_screen.dart';
import '../screens/candidate/interview/meeting_history_screen.dart';
import '../screens/candidate/interview/meeting_summary_screen.dart';
import '../screens/candidate/profile/edit_career_goals_screen.dart';
import '../screens/candidate/profile/edit_education_screen.dart';
import '../screens/candidate/profile/edit_others_screen.dart';
import '../screens/candidate/profile/edit_personal_details_screen.dart';
import '../screens/candidate/profile/edit_skills_tools_screen.dart';
import '../screens/candidate/profile/edit_work_experience_screen.dart';

import '../screens/candidate/plans/candidate_plans_screen.dart';
import '../screens/candidate/resume/resume_history_screen.dart';
import '../screens/candidate/resume/resume_review_screen.dart';
import '../screens/common/legal_webview_screen.dart';
import '../screens/common/main_screen.dart';

import '../screens/common/welcome_screen.dart';
import '../screens/student/document_viewer_screen.dart';
import '../screens/student/documents_screen.dart';
import '../screens/student/edit_student_career_goals_screen.dart';
import '../screens/student/edit_student_education_screen.dart';
import '../screens/student/edit_student_personal_details_screen.dart';
import '../screens/student/lectures_screen.dart';
import '../screens/student/quiz_generation_loading_screen.dart';
import '../screens/student/quiz_screen.dart';
import '../screens/student/quiz_review_screen.dart';
import '../screens/student/quiz_summary_screen.dart';
import '../screens/student/quiz_history_screen.dart';
import '../models/quize_model.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/user-type-selection',
      builder: (context, state) => const UserTypeSelectionScreen(),
    ),
    GoRoute(
      path: '/student-signup',
      builder: (context, state) =>
          const StudentOnboardingStepScreen(stepNumber: 1),
      routes: [
        GoRoute(
          path: 'step/:stepNumber',
          builder: (context, state) {
            final stepNumber =
                int.tryParse(state.pathParameters['stepNumber'] ?? '1') ?? 1;
            return StudentOnboardingStepScreen(stepNumber: stepNumber);
          },
        ),
      ],
    ),
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
      path: '/terms-of-use',
      builder: (context, state) => const LegalWebViewScreen(
        url: 'https://skillresy.com/terms-of-use/',
        title: 'Terms of Use',
      ),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingStepScreen(stepNumber: 1),
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
    GoRoute(
      path: '/resume/review',
      builder: (context, state) {
        final flowType = state.uri.queryParameters['flow'];
        return ResumeReviewScreen(flowType: flowType);
      },
    ),
    GoRoute(
      path: '/resume/history',
      builder: (context, state) => const ResumeHistoryScreen(),
    ),
    GoRoute(
      path: '/meeting/history',
      builder: (context, state) => const MeetingHistoryScreen(),
    ),
    GoRoute(
      path: '/meeting/detail',
      builder: (context, state) {
        final meeting = state.extra as MeetingHistoryItem;
        return MeetingDetailScreen(meeting: meeting);
      },
    ),
    GoRoute(
      path: '/interview/summary',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        final sessionId = params['sessionId'] ?? '';
        final sessionType = params['sessionType'] ?? 'Interview';
        final startTimeStr = params['startTime'];
        final durationSeconds = int.tryParse(params['duration'] ?? '0') ?? 0;

        final startTime = startTimeStr != null
            ? DateTime.tryParse(startTimeStr) ?? DateTime.now()
            : DateTime.now();

        return MeetingSummaryScreen(
          sessionId: sessionId,
          sessionType: sessionType,
          startTime: startTime,
          duration: Duration(seconds: durationSeconds),
        );
      },
    ),
    GoRoute(
      path: '/quiz/loading',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        final sizeBytes =
            int.tryParse(params['sizeBytes'] ?? '1048576') ??
            1048576; // Default 1 MB
        return QuizGenerationLoadingScreen(sizeBytes: sizeBytes);
      },
    ),
    GoRoute(
      path: '/quiz/start',
      builder: (context, state) {
        final quiz = state.extra as QuizModel;
        final lectureName = state.uri.queryParameters['lectureName'] ?? 'Quiz';
        return QuizScreen(quiz: quiz, lectureName: lectureName);
      },
    ),
    GoRoute(
      path: '/quiz/summary',
      builder: (context, state) {
        final lectureName = state.uri.queryParameters['lectureName'] ?? 'Quiz';
        return QuizSummaryScreen(lectureName: lectureName);
      },
    ),
    GoRoute(
      path: '/quiz/review',
      builder: (context, state) {
        final quiz = state.extra as QuizModel;
        final lectureName = state.uri.queryParameters['lectureName'] ?? 'Quiz';
        return QuizReviewScreen(quiz: quiz, lectureName: lectureName);
      },
    ),
    GoRoute(
      path: '/quiz/history',
      builder: (context, state) => const QuizHistoryScreen(),
    ),
    GoRoute(
      path: '/plans',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CandidatePlansScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/meeting/setup',
      builder: (context, state) => const MeetingSetupScreen(),
    ),
    GoRoute(
      path: '/meeting/session',
      builder: (context, state) => const MeetingSessionScreen(),
    ),
    GoRoute(
      path: '/student/profile/edit-personal-details',
      builder: (context, state) => const EditStudentPersonalDetailsScreen(),
    ),
    GoRoute(
      path: '/student/profile/edit-career-goals',
      builder: (context, state) => const EditStudentCareerGoalsScreen(),
    ),
    GoRoute(
      path: '/student/profile/edit-education',
      builder: (context, state) => const EditStudentEducationScreen(),
    ),
    GoRoute(
      path: '/student/document-viewer',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        final documentUrl = params['url'] ?? '';
        final documentName = params['name'] ?? 'Document';
        return DocumentViewerScreen(
          documentUrl: documentUrl,
          documentName: documentName,
        );
      },
    ),
    GoRoute(
      path: '/student/lectures',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        final subjectId = params['subjectId'] ?? '';
        final subjectName = params['subjectName'] ?? 'Folder';
        return LecturesScreen(subjectId: subjectId, subjectName: subjectName);
      },
    ),
    GoRoute(
      path: '/student/documents',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        final lectureId = params['lectureId'] ?? '';
        final lectureName = params['lectureName'] ?? 'Lecture';
        return DocumentsScreen(lectureId: lectureId, lectureName: lectureName);
      },
    ),
  ],
);
