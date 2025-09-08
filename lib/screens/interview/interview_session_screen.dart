import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/typewriter_text.dart';
import '../../providers/interview_session_provider.dart';

class InterviewSessionScreen extends ConsumerWidget {
  final String sessionType;
  final String roleIndustry;
  final String company;
  final String jobDescription;
  final String language;
  final bool realTimeTranscription;
  final bool liveCoaching;
  final bool followUpQuestions;
  final bool summaryGeneration;

  const InterviewSessionScreen({
    super.key,
    required this.sessionType,
    required this.roleIndustry,
    required this.company,
    required this.jobDescription,
    required this.language,
    required this.realTimeTranscription,
    required this.liveCoaching,
    required this.followUpQuestions,
    required this.summaryGeneration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionData = ref.watch(interviewSessionProvider);
    final sessionNotifier = ref.read(interviewSessionProvider.notifier);

    // Check for permission dialog
    if (sessionData.error == 'PERMISSION_DENIED_DIALOG') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog(context, sessionNotifier);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxWithSmallTitle(
          title: "Live Interview Assistant",
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: null,
      ),
      floatingActionButton: _buildFloatingMicButton(
        sessionData,
        sessionNotifier,
      ),
      floatingActionButtonLocation: const _CustomFabLocation(),
      body: Container(
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
            padding: const EdgeInsets.all(15),
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
                if (sessionData.state != InterviewSessionState.idle) ...[
                  // LIVE indicator with end button
                  Row(
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: GestureDetector(
                          onTap: () => sessionNotifier.stopSession(),
                          child: const Text(
                            'End',
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
                  const SizedBox(height: 16),
                ],

                // Interview section - only show in idle state
                if (sessionData.state == InterviewSessionState.idle) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Interview',
                          style: TextStyle(
                            fontSize: 14,
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
                  Text(
                    roleIndustry.isNotEmpty
                        ? roleIndustry
                        : 'Senior Software Position',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Dynamic content based on session state
                Expanded(
                  child: _buildSessionContent(sessionData, sessionNotifier),
                ),

                // Bottom section - conditional based on session state
                if (sessionData.state != InterviewSessionState.idle)
                  _buildBottomSection(sessionData, sessionNotifier),

                // Start button for idle state
                if (sessionData.state == InterviewSessionState.idle)
                  _buildStartSessionButton(sessionNotifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Main content area - changes based on session state
  Widget _buildSessionContent(
    InterviewSessionData sessionData,
    InterviewSessionNotifier sessionNotifier,
  ) {
    switch (sessionData.state) {
      case InterviewSessionState.idle:
        return _buildIdleContent();
      case InterviewSessionState.listening:
      case InterviewSessionState.paused:
      case InterviewSessionState.recording:
        return _buildActiveSessionContent(sessionData, sessionNotifier);
      case InterviewSessionState.processing:
        return _buildActiveSessionContent(sessionData, sessionNotifier);
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
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Start a session to receive real-time AI coaching',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Active session content (transcription area)
  Widget _buildActiveSessionContent(
    InterviewSessionData sessionData,
    InterviewSessionNotifier sessionNotifier,
  ) {
    final scrollController = ScrollController();

    // Auto-scroll to bottom when new content is added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Check if we have any content to show
    final hasFullTranscript = sessionData.fullTranscript.isNotEmpty;
    final hasLiveTranscription =
        sessionData.currentTranscription != null &&
        sessionData.currentTranscription!.isNotEmpty;

    // If no content yet and not recording, show placeholder
    if (!hasFullTranscript && !hasLiveTranscription) {
      return Center(
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
              'Tap the microphone to start transcribing',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full transcript (saved text)
            if (hasFullTranscript)
              Text(
                sessionData.fullTranscript,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),

            // Live transcription (currently being spoken)
            if (hasLiveTranscription) ...[
              if (hasFullTranscript) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recording indicator
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: _buildPulsingDot(),
                  ),
                  const SizedBox(width: 8),
                  // Live transcription with typewriter effect
                  Expanded(
                    child: TypewriterText(
                      text: sessionData.currentTranscription!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.withValues(alpha: 0.8),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                      typingSpeed: const Duration(milliseconds: 30),
                      showCursor: true,
                    ),
                  ),
                ],
              ),
            ],

            // Show blinking cursor when waiting for speech (recording but no current transcription)
            if (sessionData.state == InterviewSessionState.recording &&
                !hasLiveTranscription) ...[
              if (hasFullTranscript) const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: _buildPulsingDot(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Listening...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Help popup content - show transcription (same as active content)
  Widget _buildHelpContent(
    InterviewSessionData sessionData,
    InterviewSessionNotifier sessionNotifier,
  ) {
    // Show the same transcript view as active session
    return _buildActiveSessionContent(sessionData, sessionNotifier);
  }

  Widget _buildHelpOption(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom section - conditional based on session state
  Widget _buildBottomSection(
    InterviewSessionData sessionData,
    InterviewSessionNotifier sessionNotifier,
  ) {
    switch (sessionData.state) {
      case InterviewSessionState.idle:
        return _buildStartSessionButton(sessionNotifier);
      case InterviewSessionState.listening:
        return _buildListeningStatus(sessionNotifier);
      case InterviewSessionState.paused:
        return _buildPausedStatus();
      case InterviewSessionState.showingHelp:
        return _buildHelpStatus(sessionNotifier);
      case InterviewSessionState.recording:
      case InterviewSessionState.processing:
        return _buildProcessingStatus(sessionNotifier);
    }
  }

  Widget _buildStartSessionButton(InterviewSessionNotifier sessionNotifier) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: () => sessionNotifier.startSession(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
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

  Widget _buildListeningStatus(InterviewSessionNotifier sessionNotifier) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tap Scout for options',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => sessionNotifier.showHelp(),
            child: Image.asset(
              'assets/icons/fox-mascot.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.pets, size: 40, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingStatus(InterviewSessionNotifier sessionNotifier) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'Recording',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                // Pulsing recording indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/icons/fox-mascot.png',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.pets, size: 40, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingStatus(InterviewSessionNotifier sessionNotifier) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tap mic to record more',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => sessionNotifier.showHelp(),
            child: Image.asset(
              'assets/icons/fox-mascot.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.pets, size: 40, color: AppColors.accent),
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
              fontSize: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStatus(InterviewSessionNotifier sessionNotifier) {
    return Column(
      children: [
        // Help dropdown positioned above the fox
        Container(
          width: 200,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpOption(
                'Transcribe Interview Only',
                Icons.record_voice_over,
                () {
                  sessionNotifier.hideHelp();
                  // Just continue listening
                },
              ),
              const SizedBox(height: 8),
              _buildHelpOption('Scout the Fox Answer!', Icons.pets, () {
                sessionNotifier.hideHelp();
                // Add mock AI response to the latest question
              }),
              const SizedBox(height: 8),
              _buildHelpOption(
                'Follow-Up Questions',
                Icons.question_answer,
                () {
                  sessionNotifier.hideHelp();
                  // Add a mock follow-up question
                },
              ),
            ],
          ),
        ),

        // Bottom status bar with fox
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tap on Scout the Fox to get help!',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => sessionNotifier.hideHelp(),
                child: Image.asset(
                  'assets/icons/fox-mascot.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.pets, size: 40, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Floating Action Button - Microphone
  Widget? _buildFloatingMicButton(
    InterviewSessionData sessionData,
    InterviewSessionNotifier sessionNotifier,
  ) {
    // Only show FAB when session is active
    if (sessionData.state == InterviewSessionState.idle) {
      return null;
    }

    switch (sessionData.state) {
      case InterviewSessionState.listening:
      case InterviewSessionState.showingHelp:
      case InterviewSessionState.paused:
        return GestureDetector(
          onTap: () => sessionNotifier.startRecording(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.mic_off, color: Colors.grey, size: 28),
          ),
        );
      case InterviewSessionState.recording:
        return GestureDetector(
          onTap: () => sessionNotifier.stopRecordingAndProcess(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.green, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.green, size: 28),
          ),
        );
      case InterviewSessionState.processing:
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.red, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.mic_off, color: Colors.red, size: 28),
        );
      case InterviewSessionState.idle:
        return null;
    }
  }

  // Blinking dots animation (like Claude)
  Widget _buildBlinkingCursor() {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(milliseconds: 400), (i) => i),
      builder: (context, snapshot) {
        final tick = snapshot.data ?? 0;
        final dotCount = (tick % 4) + 1; // 1, 2, 3, 4 dots cycling

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final isVisible = index < (dotCount > 3 ? 3 : dotCount);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // Pulsing red dot for recording indicator
  Widget _buildPulsingDot() {
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

  // Show permission dialog when Scout needs microphone access
  void _showPermissionDialog(
    BuildContext context,
    InterviewSessionNotifier sessionNotifier,
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

// Custom FAB location - positions FAB above the Scout bar with spacing
class _CustomFabLocation extends FloatingActionButtonLocation {
  const _CustomFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Center horizontally
    final double x =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2;

    // Position above the bottom content with some spacing
    final double y =
        scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        100; // 100px from bottom to leave space for Scout bar

    return Offset(x, y);
  }
}
