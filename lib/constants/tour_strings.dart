/// Centralized strings for Onboarding Guided Tour.
///
/// Designed so marketing and product teams can update copy
/// without altering tour logic or triggering breaking code changes.
class TourStepData {
  final String title;
  final String description;

  const TourStepData({
    required this.title,
    required this.description,
  });
}

class TourStrings {
  // Candidate / Job Seeker Tour Steps
  static const List<TourStepData> candidateSteps = [
    TourStepData(
      title: 'AI Resume Intelligence',
      description:
          'Build, analyze, and optimize your resumes with industry-standard ATS scoring and instant improvements.',
    ),
    TourStepData(
      title: 'AI Mock Interviews',
      description:
          'Practice realistic, role-specific interview sessions with real-time feedback to sharpen your skills.',
    ),
    TourStepData(
      title: 'Your Career Profile',
      description:
          'Keep your skills, experience, education, and target job roles updated for personalized recommendations.',
    ),
    TourStepData(
      title: 'Unlock Full Access',
      description:
          'Explore our flexible career plans with unlimited mock interviews, instant resume reviews, and full AI access.',
    ),
  ];

  // Student Tour Steps
  static const List<TourStepData> studentSteps = [
    TourStepData(
      title: 'Your Academic Hub',
      description:
          'Track your academic progress, upcoming tasks, study streaks, and daily learning milestones in one place.',
    ),
    TourStepData(
      title: 'AI Study Space',
      description:
          'Upload lectures and documents, generate smart study summaries, and take interactive AI-powered quizzes.',
    ),
    TourStepData(
      title: 'Student Profile',
      description:
          'Keep your academic degree, major, university, and career goals up to date for tailored learning materials.',
    ),
    TourStepData(
      title: 'Student Membership',
      description:
          'Get unrestricted access to AI study tools, deep lecture insights, and unlimited AI practice quizzes.',
    ),
  ];

  // Buttons & Labels
  static const String next = 'Next';
  static const String back = 'Back';
  static const String skip = 'Skip';
  static const String finish = 'Finish';
  static const String takeTourAgain = 'Take guided tour again';
}
