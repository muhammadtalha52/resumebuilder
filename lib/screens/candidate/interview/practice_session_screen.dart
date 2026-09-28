import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/continuous_transcription_provider.dart';
import '../../../providers/interview_session_provider.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/dialogs/ai_consent_dialog.dart';
import '../../../widgets/dialogs/confirmation_dialog.dart';
import '../../../widgets/dialogs/notification_dialog.dart';

/// Practice Session Screen
///
/// Flow:
/// 1. Scout asks an interview question
/// 2. User records their answer
/// 3. Scout analyzes and provides feedback
/// 4. User can request next question or end session
class PracticeSessionScreen extends ConsumerStatefulWidget {
  const PracticeSessionScreen({super.key});

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  bool _isInitialized = false;
  final ScrollController _conversationScrollController = ScrollController();
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  @override
  void dispose() {
    _conversationScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // The session will be started when user taps "Start Practice"
  }

  /// Scrolls the conversation list to the bottom
  void _scrollToBottom() {
    if (_conversationScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _conversationScrollController.animateTo(
          _conversationScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionData = ref.watch(continuousTranscriptionProvider);
    final sessionNotifier = ref.read(continuousTranscriptionProvider.notifier);

    // Check for permission dialog
    if (sessionData.error == 'PERMISSION_DENIED_DIALOG') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog(context, sessionNotifier);
      });
    }

    // Listen for session warnings
    ref.listen(
      continuousTranscriptionProvider.select((data) => data.sessionWarning5Min),
      (previous, current) {
        if (current && !(previous ?? false)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showNotificationDialog(
              context: context,
              title: 'Time Warning',
              subtitle: 'You have 5 minutes remaining in your practice session',
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

    // Listen for auto-end
    ref.listen(
      continuousTranscriptionProvider.select((data) => data.sessionAutoEnd),
      (previous, current) async {
        if (current && !(previous ?? false)) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final sessionId = sessionData.sessionId;
            final startTime =
                sessionNotifier.sessionStartTime ?? DateTime.now();
            final duration = sessionData.sessionDuration;

            await sessionNotifier.stopSession();

            if (context.mounted) {
              await showNotificationDialog(
                context: context,
                title: 'Practice Time Limit Reached',
                subtitle: 'Your practice session has reached the 1-hour limit',
                icon: Icons.timer_off,
                iconBackgroundColor: Colors.red,
                buttonText: 'View Summary',
                buttonColor: AppColors.primary,
                buttonTextColor: Colors.white,
              );
            }

            if (context.mounted && sessionId != null && sessionId.isNotEmpty) {
              context.go(
                '/interview/summary?sessionId=$sessionId'
                '&sessionType=Practice'
                '&startTime=${startTime.toIso8601String()}'
                '&duration=${duration.inSeconds}',
              );
            } else if (context.mounted) {
              context.go('/home');
            }
          });
        }
      },
    );

    // Listen for new assistant messages to auto-scroll
    final currentMessageCount = sessionData.conversation.messages
        .where((msg) => msg.isAssistant)
        .length;

    if (currentMessageCount > _previousMessageCount) {
      _scrollToBottom();
      _previousMessageCount = currentMessageCount;
    }

    // Also scroll when Scout starts responding (isGettingHelp becomes true)
    ref.listen(
      continuousTranscriptionProvider.select((data) => data.isGettingHelp),
      (previous, current) {
        if (current && !(previous ?? false)) {
          _scrollToBottom();
        }
      },
    );

    return PopScope(
      canPop: false,
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
                    // Header section
                    _buildHeader(sessionData, sessionNotifier),

                    const SizedBox(height: 10),

                    // Session info (only in idle state)
                    if (sessionData.state == InterviewSessionState.idle)
                      _buildSessionInfo(),

                    // Main content
                    Expanded(
                      child: _buildMainContent(sessionData, sessionNotifier),
                    ),

                    // Bottom action buttons
                    _buildBottomSection(sessionData, sessionNotifier),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    InterviewSessionData sessionData,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    final isActive = sessionData.state != InterviewSessionState.idle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          if (!isActive)
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
          if (isActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRACTICE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (isActive)
            GestureDetector(
              onTap: () => _endSession(sessionData, sessionNotifier),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'End Practice',
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
    );
  }

  Widget _buildSessionInfo() {
    final interviewSession = ref.watch(interviewSessionProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, color: AppColors.accent, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Practice Interview',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            interviewSession.positionTitle.isNotEmpty
                ? interviewSession.positionTitle
                : 'Interview Practice',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    InterviewSessionData sessionData,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    if (sessionData.state == InterviewSessionState.idle) {
      return _buildIdleContent();
    }

    return _buildActiveSessionContent(sessionData, sessionNotifier);
  }

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
                      AppColors.accent.withValues(alpha: 0.08),
                      AppColors.primary.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            size: 18,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'How Practice Works',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildInstructionItem(
                      icon: Icons.question_answer,
                      text: 'Scout will ask you interview questions',
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionItem(
                      icon: Icons.mic,
                      text: 'Speak your answer clearly',
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionItem(
                      icon: Icons.rate_review,
                      text: 'Get instant feedback and suggestions',
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionItem(
                      icon: Icons.trending_up,
                      text: 'Improve with each practice round',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tap "Start Practice" when you\'re ready',
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

  Widget _buildActiveSessionContent(
    InterviewSessionData sessionData,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    return Column(
      children: [
        // Your Answer Section (Transcription)
        _buildTranscriptSection(sessionData),

        const SizedBox(height: 8),

        // Scout's Questions & Feedback Section
        Expanded(child: _buildConversationSection(sessionData)),
      ],
    );
  }

  Widget _buildTranscriptSection(InterviewSessionData sessionData) {
    final fullTranscript = sessionData.fullTranscript;
    final isListening = sessionData.isListening;
    final hasTranscript = fullTranscript.isNotEmpty;

    return Container(
      height: 150,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.mic, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Your Answer',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                if (isListening)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Recording',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: !hasTranscript && !isListening
                ? Center(
                    child: Text(
                      'Your spoken answer will appear here...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      fullTranscript.isNotEmpty
                          ? fullTranscript
                          : 'Recording...',
                      style: TextStyle(
                        fontSize: 14,
                        color: fullTranscript.isNotEmpty
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationSection(InterviewSessionData sessionData) {
    final conversation = sessionData.conversation;
    final assistantMessages = conversation.messages
        .where((msg) => msg.isAssistant)
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
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
                  'Scout\'s Questions & Feedback',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: assistantMessages.isEmpty && !sessionData.isGettingHelp
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/fox-mascot.png',
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.pets,
                                size: 40,
                                color: Colors.orange,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap "Next Question" to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _conversationScrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: assistantMessages.length,
                    itemBuilder: (context, index) {
                      final message = assistantMessages[index];
                      return _buildScoutMessage(
                        message,
                        sessionData.isGettingHelp,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoutMessage(dynamic message, bool isStreaming) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/fox-mascot.png',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Scout',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  )
                : MarkdownBlock(
                    data: message.content.replaceAll('\\n', '\n'),
                    config: MarkdownConfig(
                      configs: [
                        HrConfig(height: 0, color: Colors.transparent),
                        PConfig(
                          textStyle: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(
    InterviewSessionData sessionData,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    if (sessionData.state == InterviewSessionState.idle) {
      return _buildStartButton(sessionNotifier);
    }

    return _buildActiveSessionButtons(sessionData, sessionNotifier);
  }

  Widget _buildStartButton(ContinuousTranscriptionNotifier sessionNotifier) {
    final sessionData = ref.watch(continuousTranscriptionProvider);
    final isLoading = sessionData.isStartingSession;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CustomButton(
        text: isLoading ? 'Starting Practice...' : 'Start Practice',
        onPressed: isLoading ? null : () => _startSession(sessionNotifier),
        isLoading: isLoading,
        useGradient: true,
        icon: isLoading ? null : Icons.play_arrow,
      ),
    );
  }

  Widget _buildActiveSessionButtons(
    InterviewSessionData sessionData,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: Row(
          children: [
            // Ask Question Button - Scout asks user a question
            Expanded(
              child: GestureDetector(
                onTap: sessionData.isGettingHelp
                    ? null
                    : () => sessionNotifier.getPracticeQuestion(),
                child: Container(
                  height: 65,
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/fox-mascot.png',
                        width: 18,
                        height: 18,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.pets, size: 18, color: AppColors.accent),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Next Question',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Get Feedback Button - Scout validates user's answer
            Expanded(
              child: GestureDetector(
                onTap: sessionData.isGettingHelp
                    ? null
                    : () => sessionNotifier.validatePracticeAnswer(),
                child: Container(
                  height: 65,
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review, size: 18, color: Colors.blue),
                      const SizedBox(height: 3),
                      Text(
                        'Get Feedback',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startSession(
    ContinuousTranscriptionNotifier sessionNotifier,
  ) async {
    // Check internet connectivity
    bool hasInternet = false;
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      hasInternet = false;
    }

    if (!hasInternet && mounted) {
      await showConfirmationDialog(
        context: context,
        title: 'No Internet Connection',
        subtitle: 'Please check your internet connection and try again.',
        icon: Icons.wifi_off,
        iconBackgroundColor: Colors.red,
        confirmText: 'OK',
        confirmButtonColor: Colors.red,
        confirmTextColor: Colors.white,
      );
      return;
    }

    // Check iOS AI third-party data consent compliance before mic access
    if (Platform.isIOS) {
      if (!mounted) return;
      final consentGranted = await AIConsentDialog.showIfNeeded(context);
      if (!consentGranted) {
        return;
      }
    }

    if (!mounted) return;

    // Show confirmation dialog
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Ready to Practice?',
      subtitle: 'Scout will start asking you interview questions',
      icon: Icons.school_outlined,
      iconBackgroundColor: AppColors.accent,
      confirmText: 'Start Practice',
      cancelText: 'Cancel',
      confirmButtonColor: AppColors.accent,
      confirmTextColor: Colors.white,
    );

    if (confirmed == true) {
      // Get interview session data from the global provider
      final interviewSession = ref.read(interviewSessionProvider);
      final authState = ref.read(authProvider);
      final user = authState.user;

      // Start session with API using same format as interview assistant
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
        language: interviewSession.languageSelector.isNotEmpty
            ? interviewSession.languageSelector
            : 'en',
        resumeText:
            interviewSession.extractedResumeData ?? user?.toJson().toString(),
      );

      if (success) {
        await sessionNotifier.startSession();
      }
    }
  }

  Future<void> _endSession(
    InterviewSessionData sessionData,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'End Practice?',
      subtitle: 'Your practice session will end and you\'ll see the summary',
      icon: Icons.stop_circle,
      iconBackgroundColor: Colors.red,
      confirmText: 'End Practice',
      cancelText: 'Cancel',
      confirmButtonColor: Colors.red,
      confirmTextColor: Colors.white,
    );

    if (confirmed == true && mounted) {
      final sessionId = sessionData.sessionId;
      final startTime = sessionNotifier.sessionStartTime ?? DateTime.now();
      final duration = sessionData.sessionDuration;

      sessionNotifier.stopSession();

      if (sessionId != null && sessionId.isNotEmpty) {
        context.go(
          '/interview/summary?sessionId=$sessionId'
          '&sessionType=Practice'
          '&startTime=${startTime.toIso8601String()}'
          '&duration=${duration.inSeconds}',
        );
      } else {
        context.go('/home');
      }
    }
  }

  void _showPermissionDialog(
    BuildContext context,
    ContinuousTranscriptionNotifier sessionNotifier,
  ) {
    sessionNotifier.clearError();

    showDialog(
      context: context,
      barrierDismissible: false,
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
                'Scout needs microphone access to hear your answers and provide feedback.',
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
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
