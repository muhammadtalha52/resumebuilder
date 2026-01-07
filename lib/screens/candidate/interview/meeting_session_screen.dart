import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skillresy/providers/auth_provider.dart';

import '../../../constants/app_colors.dart';
import '../../../models/conversation_models.dart';
import '../../../providers/continuous_transcription_provider.dart';
import '../../../providers/interview_session_provider.dart';
import '../../../widgets/dialogs/confirmation_dialog.dart';
import '../../../widgets/dialogs/notification_dialog.dart';

class MeetingSessionScreen extends ConsumerWidget {
  const MeetingSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionData = ref.watch(continuousTranscriptionProvider);
    final sessionNotifier = ref.read(continuousTranscriptionProvider.notifier);

    // Auto-transition to listening if we have session ID but are in idle state
    // This happens when coming from setup screen after startSessionWithAPI
    if (sessionData.sessionId != null &&
        sessionData.sessionId!.isNotEmpty &&
        sessionData.state == InterviewSessionState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print(
          '[AUTO-TRANSITION] Session ID exists but in idle state, transitioning to listening',
        );
        print('[AUTO-TRANSITION] Session ID: ${sessionData.sessionId}');
        // Don't call startSession() as that would reset the session
        // Just transition to listening state and start audio transcription
        sessionNotifier.transitionToListening();
      });
    }

    // Check for permission dialog
    if (sessionData.error == 'PERMISSION_DENIED_DIALOG') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog(context, sessionNotifier);
      });
    }

    // Listen for 5-minute warning (at 55 minutes)
    ref.listen(
      continuousTranscriptionProvider.select((data) => data.sessionWarning5Min),
      (previous, current) {
        if (current && !(previous ?? false)) {
          // Show warning dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showNotificationDialog(
              context: context,
              title: 'Time Warning',
              subtitle: 'You have 5 minutes remaining in your session',
              icon: Icons.access_time,
              iconBackgroundColor: AppColors.primary,
              buttonText: 'Got it',
              buttonColor: AppColors.primary,
              buttonTextColor: Colors.white,
            );
          });
        }
      },
    );

    // Listen for auto-end (at 60 minutes)
    ref.listen(
      continuousTranscriptionProvider.select((data) => data.sessionAutoEnd),
      (previous, current) async {
        if (current && !(previous ?? false)) {
          // Auto-end session
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            // Capture session data before stopping
            final sessionId = sessionData.sessionId;
            final sessionType = sessionData.sessionType ?? 'Interview';
            final startTime =
                sessionNotifier.sessionStartTime ?? DateTime.now();
            final duration = sessionData.sessionDuration;

            // Stop the session
            await sessionNotifier.stopSession();

            // Show auto-end dialog
            if (context.mounted) {
              await showNotificationDialog(
                context: context,
                title: 'Session Time Limit Reached',
                subtitle:
                    'Your session has reached the 1-hour limit and has been automatically ended',
                icon: Icons.timer_off,
                iconBackgroundColor: Colors.red,
                buttonText: 'View Summary',
                buttonColor: AppColors.primary,
                buttonTextColor: Colors.white,
              );
            }

            // Navigate to summary screen
            if (context.mounted) {
              if (sessionId != null && sessionId.isNotEmpty) {
                context.go(
                  '/interview/summary?sessionId=$sessionId'
                  '&sessionType=$sessionType'
                  '&startTime=${startTime.toIso8601String()}'
                  '&duration=${duration.inSeconds}',
                );
              } else {
                // If no session ID, just go back home
                context.go('/home');
              }
            }
          });
        }
      },
    );

    return PopScope(
      canPop: false,
      // Always prevent back navigation - user must use End button
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/icons/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button - only show in idle state
                    if (sessionData.state == InterviewSessionState.idle) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (sessionData.state != InterviewSessionState.idle) ...[
                      // LIVE indicator with end button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  // Show confirmation dialog before ending session
                                  final confirmed = await showConfirmationDialog(
                                    context: context,
                                    title: 'End Session?',
                                    subtitle:
                                        'Your session will end and you\'ll see the summary',
                                    icon: Icons.stop_circle,
                                    iconBackgroundColor: Colors.red,
                                    confirmText: 'End Session',
                                    cancelText: 'Cancel',
                                    confirmButtonColor: Colors.red,
                                    confirmTextColor: Colors.white,
                                  );

                                  if (confirmed == true && context.mounted) {
                                    // Capture session data before stopping
                                    final sessionId = sessionData.sessionId;
                                    final sessionType =
                                        sessionData.sessionType ?? 'Interview';
                                    final startTime =
                                        sessionNotifier.sessionStartTime ??
                                        DateTime.now();
                                    final duration =
                                        sessionData.sessionDuration;

                                    // Stop the session
                                    sessionNotifier.stopSession();

                                    // Navigate to summary screen
                                    if (sessionId != null &&
                                        sessionId.isNotEmpty) {
                                      final transcriptionData = ref.read(
                                        continuousTranscriptionProvider,
                                      );

                                      print(transcriptionData);
                                      context.go(
                                        '/interview/summary?sessionId=$sessionId'
                                        '&sessionType=$sessionType'
                                        '&startTime=${startTime.toIso8601String()}'
                                        '&duration=${duration.inSeconds}',
                                      );
                                    } else {
                                      // If no session ID, just go back home
                                      context.go('/home');
                                    }
                                  }
                                },
                                child: const Text(
                                  'End Session',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Interview section - only show in idle state
                    if (sessionData.state == InterviewSessionState.idle) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mic,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sessionData.sessionType ?? 'Interview',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.6,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final interviewSession = ref.watch(
                            interviewSessionProvider,
                          );
                          return Text(
                            interviewSession.positionTitle.isNotEmpty
                                ? interviewSession.positionTitle
                                : 'Senior Software Position',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Dynamic content based on session state
                    Expanded(
                      child: _buildSessionContent(sessionData, sessionNotifier),
                    ),

                    // Bottom section - conditional based on session state
                    if (sessionData.state != InterviewSessionState.idle)
                      _buildBottomSection(ref, sessionData, sessionNotifier),

                    // Start button for idle state
                    if (sessionData.state == InterviewSessionState.idle)
                      _buildStartSessionButton(ref, sessionNotifier),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Main content area - changes based on session state
  Widget _buildSessionContent(
    InterviewSessionData sessionData,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    switch (sessionData.state) {
      case InterviewSessionState.idle:
        return _buildIdleContent();
      case InterviewSessionState.listening:
      case InterviewSessionState.paused:
      case InterviewSessionState.ended:
      case InterviewSessionState.recording:
      case InterviewSessionState.processing:
      case InterviewSessionState.showingHelp:
        return _buildHelpContent(sessionData, sessionNotifier);
    }
  }

  // Idle state content (fox avatar)
  Widget _buildIdleContent() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/fox-mascot.png',
              width: 90,
              height: 90,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.pets, color: AppColors.accent, size: 60),
            ),
            const SizedBox(height: 32),

            // Instructions Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.accent.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.tips_and_updates,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Before You Start',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Instructions list
                    _buildInstructionItem(
                      icon: Icons.volume_up,
                      text: 'Find a quiet place for best results',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionItem(
                      icon: Icons.phone_android,
                      text: 'Place phone close to speaker',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionItem(
                      icon: Icons.hearing,
                      text: 'Scout will listen and help in real-time',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionItem(
                      icon: Icons.access_time,
                      text: 'Maximum session duration: 1 hour',
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tap "Start Session" when you\'re ready',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build instruction item
  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // Help popup content - show separate transcription and conversation areas
  Widget _buildHelpContent(
    InterviewSessionData sessionData,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    return Column(
      children: [
        // Transcription Container (fixed 150px height) - now using optimized widget
        const TranscriptSection(),

        const SizedBox(height: 8),

        // Conversation Container (expands to fill remaining space)
        Expanded(child: _buildConversationContainer(sessionData)),
      ],
    );
  }

  // Conversation Container - Only Scout AI responses
  Widget _buildConversationContainer(InterviewSessionData sessionData) {
    return _ConversationContainer(sessionData: sessionData);
  }

  // Bottom section - conditional based on session state
  Widget _buildBottomSection(
    WidgetRef ref,
    InterviewSessionData sessionData,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    switch (sessionData.state) {
      case InterviewSessionState.idle:
        return _buildStartSessionButton(ref, sessionNotifier);
      case InterviewSessionState.paused:
        return _buildPausedStatus();
      case InterviewSessionState.listening:
      case InterviewSessionState.ended:
      case InterviewSessionState.recording:
      case InterviewSessionState.processing:
      case InterviewSessionState.showingHelp:
        // Always show Scout buttons during any active session
        return _buildListeningStatus(sessionNotifier, sessionData);
    }
  }

  Widget _buildStartSessionButton(
    WidgetRef ref,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    final sessionData = ref.watch(continuousTranscriptionProvider);
    final isLoading = sessionData.isStartingSession;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradientHorizontal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                // Check internet connectivity first to avoid wasting credits
                bool hasInternet = false;
                try {
                  // Try to lookup a reliable DNS address
                  final result = await InternetAddress.lookup(
                    'google.com',
                  ).timeout(const Duration(seconds: 5));
                  hasInternet =
                      result.isNotEmpty && result[0].rawAddress.isNotEmpty;
                } catch (e) {
                  hasInternet = false;
                }

                // Show error if no internet connection
                if (!hasInternet && ref.context.mounted) {
                  await showConfirmationDialog(
                    context: ref.context,
                    title: 'No Internet Connection',
                    subtitle:
                        'Please check your internet connection and try again. Your credits will not be used.',
                    icon: Icons.wifi_off,
                    iconBackgroundColor: Colors.red,
                    confirmText: 'OK',
                    confirmButtonColor: Colors.red,
                    confirmTextColor: Colors.white,
                  );
                  return;
                }

                // Show confirmation dialog before starting session
                final confirmed = await showConfirmationDialog(
                  context: ref.context,
                  title: 'Ready to Start?',
                  subtitle:
                      'Your session will begin and Scout will start listening',
                  icon: Icons.play_circle,
                  iconBackgroundColor: AppColors.primary,
                  confirmText: 'Start Session',
                  cancelText: 'Cancel',
                  confirmButtonColor: AppColors.primary,
                  confirmTextColor: Colors.white,
                );

                if (confirmed == true) {
                  // Check if we already have a session ID from startSessionWithAPI
                  if (sessionData.sessionId != null) {
                    print(
                      '[START-BTN] Session ID exists, starting audio transcription only',
                    );
                    await sessionNotifier.startSession();
                  } else {
                    print(
                      '[START-BTN] No session ID, using data from InterviewSessionProvider',
                    );
                    // Get interview session data from the global provider
                    final interviewSession = ref.read(interviewSessionProvider);
                    final authState = ref.watch(authProvider);
                    final user = authState.user;

                    // Start session with API using data from InterviewSessionProvider
                    final success = await sessionNotifier.startSessionWithAPI(
                      sessionType: interviewSession.interviewType.isNotEmpty
                          ? interviewSession.interviewType.toLowerCase()
                          : 'interview',
                      role: interviewSession.positionTitle.isNotEmpty
                          ? interviewSession.positionTitle
                          : 'Software Developer',
                      companyName: interviewSession.companyName.isNotEmpty
                          ? interviewSession.companyName
                          : 'Company',
                      jobDescription: interviewSession.jobDescription.isNotEmpty
                          ? interviewSession.jobDescription
                          : 'Software development position',
                      agenda: interviewSession.meetingAgenda,
                      language: "en",
                      // Use extracted resume data if available, fallback to user profile
                      resumeText:
                          interviewSession.extractedResumeData ??
                          user?.toJson().toString(),
                    );

                    if (success) {
                      print(
                        '[START-BTN] API session started, now starting audio transcription',
                      );
                      await sessionNotifier.startSession();
                    } else {
                      print('[START-BTN] Failed to start API session');
                    }
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Starting Session...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Start Session',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildListeningStatus(
    ContinuousTranscriptionNotifier sessionNotifier,
    InterviewSessionData sessionData,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(
        children: [
          // Scout Help Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Prevent duplicate API calls if already in progress
                if (sessionData.isGettingHelp) {
                  print('[SCOUT-BTN] Already getting help, ignoring tap');
                  return;
                }

                // Check session type and call appropriate method
                final sessionType = sessionData.sessionType?.toLowerCase();
                if (sessionType == 'meeting') {
                  sessionNotifier.getNextMeetingHelp();
                } else {
                  sessionNotifier.getHelp();
                }
              },
              child: Container(
                height: 65, // Fixed height for both buttons
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/fox-mascot.png',
                      width: 18,
                      height: 18,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.pets,
                        size: 18,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Scout, Give me a response!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Follow-up Questions Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Prevent duplicate API calls if already in progress
                if (sessionData.isGettingHelp) {
                  print('[FOLLOW-UP-BTN] Already getting help, ignoring tap');
                  return;
                }

                sessionNotifier.getFollowUpQuestions();
              },
              child: Container(
                height: 65, // Fixed height for both buttons
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 18, color: Colors.blue),
                    const SizedBox(height: 3),
                    Flexible(
                      child: Text(
                        'Follow Up Question, Scout',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'Session paused',
            style: TextStyle(
              fontSize: 17,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Show permission dialog when Scout needs microphone access
  void _showPermissionDialog(
    BuildContext context,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    // Clear the dialog error first
    sessionNotifier.clearError();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Image.asset(
                'assets/icons/fox-mascot.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.pets, size: 32, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Scout Needs Permission',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scout needs microphone access to listen to interview conversations and provide real-time AI assistance.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 Go to Settings → Privacy & Security → Microphone and enable access for this app.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8B5000),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Open app settings
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Separate StatefulWidget to properly handle scroll behavior
class _ConversationContainer extends StatefulWidget {
  final InterviewSessionData sessionData;

  const _ConversationContainer({required this.sessionData});

  @override
  State<_ConversationContainer> createState() => _ConversationContainerState();
}

class _ConversationContainerState extends State<_ConversationContainer> {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get only assistant messages from conversation
    final conversation = widget.sessionData.conversation;
    final assistantMessages = conversation.messages
        .where((msg) => msg.isAssistant)
        .toList();

    // Only auto-scroll when there's actually a NEW message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && assistantMessages.isNotEmpty) {
        // Check if we have NEW messages (not just rebuild)
        if (assistantMessages.length > _lastMessageCount) {
          _lastMessageCount = assistantMessages.length;
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/fox-mascot.png',
                  width: 16,
                  height: 16,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.pets, size: 16, color: Colors.orange),
                ),
                const SizedBox(width: 8),
                Text(
                  'Scout AI Responses',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (assistantMessages.isNotEmpty ||
                    widget.sessionData.isGettingHelp)
                  Text(
                    '${assistantMessages.length} response${assistantMessages.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child:
                assistantMessages.isEmpty && !widget.sessionData.isGettingHelp
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/fox-mascot.png',
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.pets,
                                size: 32,
                                color: Colors.orange,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scout will provide AI assistance here',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // Show assistant messages (including streaming ones)
                        ...assistantMessages.map(
                          (message) => _buildScoutResponseCard(
                            message,
                            widget.sessionData.isGettingHelp,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Build Scout response card
  Widget _buildScoutResponseCard(
    ConversationMessage message,
    bool isStreaming,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scout header - compact row with icon and label
            Row(
              children: [
                Image.asset(
                  'assets/icons/fox-mascot.png',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  message.assistantType == AssistantMessageType.followUp
                      ? 'Scout Follow-Up'
                      : 'Scout Answer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Response content - now uses full width
            message.content.isEmpty
                ? Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scout is thinking...',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  )
                : MarkdownBody(
                    data: message.content.replaceAll('\\n', '\n'),
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                      strong: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      listBullet: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    softLineBreak: true,
                  ),
          ],
        ),
      ),
    );
  }
}

// Extracted transcript widget with auto-scroll functionality
class TranscriptSection extends ConsumerStatefulWidget {
  const TranscriptSection({super.key});

  @override
  ConsumerState<TranscriptSection> createState() => _TranscriptSectionState();
}

class _TranscriptSectionState extends ConsumerState<TranscriptSection> {
  final ScrollController _scrollController = ScrollController();
  String _lastTranscript = '';

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for transcript changes and auto-scroll
    ref.listen(
      continuousTranscriptionProvider.select((data) => data.fullTranscript),
      (previous, current) {
        if (current.length > _lastTranscript.length) {
          _lastTranscript = current;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      },
    );

    // Watch only the data we need
    final fullTranscript = ref.watch(
      continuousTranscriptionProvider.select((data) => data.fullTranscript),
    );
    final isListening = ref.watch(
      continuousTranscriptionProvider.select((data) => data.isListening),
    );

    // Check if we have any content to show
    final hasFullTranscript = fullTranscript.isNotEmpty;

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mic,
                  size: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Transcription',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: !hasFullTranscript && !isListening
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_none,
                          size: 48,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Place phone near speaker so Scout can listen',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full transcript (saved text)
                        if (hasFullTranscript)
                          Text(
                            fullTranscript,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),

                        // Listening indicator (when recording)
                        if (isListening) ...[
                          if (hasFullTranscript) const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Recording indicator - wrapped in SizedBox to prevent layout shift
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: Center(child: _PulsingDot()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Listening message
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Scout is listening...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.lightBlueAccent,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Extracted pulsing dot widget
class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(milliseconds: 500), (i) => i),
      builder: (context, snapshot) {
        final tick = snapshot.data ?? 0;
        final isPulsing = tick % 2 == 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: isPulsing ? 10 : 8,
          height: isPulsing ? 10 : 8,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: isPulsing
                ? [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
        );
      },
    );
  }
}
