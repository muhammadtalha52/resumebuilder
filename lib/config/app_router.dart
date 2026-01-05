import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skillresy/screens/auth/login_screen.dart';
import 'package:skillresy/screens/auth/forgot_password_screen.dart';
import 'package:skillresy/screens/common/splash_screen.dart';

import '../models/meeting_history_response.dart';
import '../screens/auth/onboarding_step_screen.dart';
import '../screens/auth/simple_signup_screen.dart';
import '../screens/auth/student_onboarding_step_screen.dart';
import '../screens/auth/user_type_selection_screen.dart';
import '../screens/candidate/activity/activity_history_screen.dart';
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

import '../screens/candidate/invite/invite_friends_screen.dart';
import '../screens/candidate/plans/candidate_plans_screen.dart';
import '../screens/candidate/resume/resume_history_screen.dart';
import '../screens/candidate/resume/resume_review_screen.dart';
import '../screens/candidate/usage/usage_screen.dart';
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
import '../screens/student/student_plans_screen.dart';
import '../models/quize_model.dart';

// Helper function to create pages without swipe-back gesture
Page<dynamic> buildPageWithoutSwipeBack({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, childWidget) {
      return childWidget;
    },
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const SplashScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const WelcomeScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const LoginScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const ForgotPasswordScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/user-type-selection',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const UserTypeSelectionScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/simple-signup',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const SimpleSignupScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/student-signup',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const StudentOnboardingStepScreen(stepNumber: 1),
        key: state.pageKey,
      ),
      routes: [
        GoRoute(
          path: 'step/:stepNumber',
          pageBuilder: (context, state) {
            final stepNumber =
                int.tryParse(state.pathParameters['stepNumber'] ?? '1') ?? 1;
            return buildPageWithoutSwipeBack(
              child: StudentOnboardingStepScreen(stepNumber: stepNumber),
              key: state.pageKey,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const MainScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/profile/edit-personal-details',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const EditPersonalDetailsScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/profile/edit-career-goals',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const EditCareerGoalsScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/profile/edit-skills-tools',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const EditSkillsToolsScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/profile/edit-others',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const EditOthersScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/profile/edit-education',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const EditEducationScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/profile/edit-work-experience',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const EditWorkExperienceScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const OnboardingStepScreen(stepNumber: 1),
        key: state.pageKey,
      ),
      routes: [
        GoRoute(
          path: 'step/:stepNumber',
          pageBuilder: (context, state) {
            final stepNumber =
                int.tryParse(state.pathParameters['stepNumber'] ?? '1') ?? 1;
            return buildPageWithoutSwipeBack(
              child: OnboardingStepScreen(stepNumber: stepNumber),
              key: state.pageKey,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/resume/review',
      pageBuilder: (context, state) {
        final flowType = state.uri.queryParameters['flow'];
        return buildPageWithoutSwipeBack(
          child: ResumeReviewScreen(flowType: flowType),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/resume/history',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const ResumeHistoryScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/meeting/history',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const MeetingHistoryScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/activity/history',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const ActivityHistoryScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/meeting/detail',
      pageBuilder: (context, state) {
        final meeting = state.extra as MeetingHistoryItem;
        return buildPageWithoutSwipeBack(
          child: MeetingDetailScreen(meeting: meeting),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/interview/summary',
      pageBuilder: (context, state) {
        final params = state.uri.queryParameters;
        final sessionId = params['sessionId'] ?? '';
        final sessionType = params['sessionType'] ?? 'Interview';
        final startTimeStr = params['startTime'];
        final durationSeconds = int.tryParse(params['duration'] ?? '0') ?? 0;

        final startTime = startTimeStr != null
            ? DateTime.tryParse(startTimeStr) ?? DateTime.now()
            : DateTime.now();

        return buildPageWithoutSwipeBack(
          child: MeetingSummaryScreen(
            sessionId: sessionId,
            sessionType: sessionType,
            startTime: startTime,
            duration: Duration(seconds: durationSeconds),
          ),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/quiz/loading',
      pageBuilder: (context, state) {
        final params = state.uri.queryParameters;
        final sizeBytes =
            int.tryParse(params['sizeBytes'] ?? '1048576') ??
            1048576; // Default 1 MB
        return buildPageWithoutSwipeBack(
          child: QuizGenerationLoadingScreen(sizeBytes: sizeBytes),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/quiz/start',
      pageBuilder: (context, state) {
        final quiz = state.extra as QuizModel;
        final lectureName = state.uri.queryParameters['lectureName'] ?? 'Quiz';
        return buildPageWithoutSwipeBack(
          child: QuizScreen(quiz: quiz, lectureName: lectureName),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/quiz/summary',
      pageBuilder: (context, state) {
        final lectureName = state.uri.queryParameters['lectureName'] ?? 'Quiz';
        return buildPageWithoutSwipeBack(
          child: QuizSummaryScreen(lectureName: lectureName),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/quiz/review',
      pageBuilder: (context, state) {
        final quiz = state.extra as QuizModel;
        final lectureName = state.uri.queryParameters['lectureName'] ?? 'Quiz';
        return buildPageWithoutSwipeBack(
          child: QuizReviewScreen(quiz: quiz, lectureName: lectureName),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/quiz/history',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const QuizHistoryScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/plans',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const CandidatePlansScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/usage',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const UsageScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/invite-friends',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const InviteFriendsScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/meeting/setup',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const MeetingSetupScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/meeting/session',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const MeetingSessionScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/student/profile/edit-personal-details',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const EditStudentPersonalDetailsScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/student/profile/edit-career-goals',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const EditStudentCareerGoalsScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/student/profile/edit-education',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const EditStudentEducationScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/student/document-viewer',
      pageBuilder: (context, state) {
        final params = state.uri.queryParameters;
        final documentUrl = params['url'] ?? '';
        final documentName = params['name'] ?? 'Document';
        return buildPageWithoutSwipeBack(
          child: DocumentViewerScreen(
            documentUrl: documentUrl,
            documentName: documentName,
          ),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/student/lectures',
      pageBuilder: (context, state) {
        final params = state.uri.queryParameters;
        final subjectId = params['subjectId'] ?? '';
        final subjectName = params['subjectName'] ?? 'Folder';
        return buildPageWithoutSwipeBack(
          child: LecturesScreen(subjectId: subjectId, subjectName: subjectName),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/student/documents',
      pageBuilder: (context, state) {
        final params = state.uri.queryParameters;
        final lectureId = params['lectureId'] ?? '';
        final lectureName = params['lectureName'] ?? 'Lecture';
        return buildPageWithoutSwipeBack(
          child: DocumentsScreen(
            lectureId: lectureId,
            lectureName: lectureName,
          ),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/student/plans',
      pageBuilder: (context, state) => buildPageWithoutSwipeBack(
        child: const StudentPlansScreen(),
        key: state.pageKey,
      ),
    ),
  ],
);
