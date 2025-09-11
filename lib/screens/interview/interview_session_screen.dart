import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';
import '../../models/conversation_models.dart';
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
              padding: const EdgeInsets.only(top: 15, bottom: 15),
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
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.6,
                            ),
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
                    _buildBottomSection(ref, sessionData, sessionNotifier),

                  // Start button for idle state
                  if (sessionData.state == InterviewSessionState.idle)
                    _buildStartSessionButton(sessionNotifier),
                ],
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
    InterviewSessionNotifier sessionNotifier,
  ) {
    switch (sessionData.state) {
      case InterviewSessionState.idle:
        return _buildIdleContent();
      case InterviewSessionState.listening:
      case InterviewSessionState.paused:
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

  // Help popup content - show separate transcription and conversation areas
  Widget _buildHelpContent(
    InterviewSessionData sessionData,
    InterviewSessionNotifier sessionNotifier,
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
    InterviewSessionNotifier sessionNotifier,
  ) {
    switch (sessionData.state) {
      case InterviewSessionState.idle:
        return _buildStartSessionButton(sessionNotifier);
      case InterviewSessionState.paused:
        return _buildPausedStatus();
      case InterviewSessionState.listening:
      case InterviewSessionState.recording:
      case InterviewSessionState.processing:
      case InterviewSessionState.showingHelp:
        // Always show Scout buttons during any active session
        return _buildListeningStatus(sessionNotifier);
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
              onTap: () => sessionNotifier.getHelp(),
              child: Container(
                height: 65, // Fixed height for both buttons
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
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
                        fontSize: 10,
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
              onTap: () => sessionNotifier.getFollowUpQuestions(),
              child: Container(
                height: 65, // Fixed height for both buttons
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
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
                          fontSize: 9,
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
              fontSize: 16,
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
            padding: const EdgeInsets.all(12),
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
                    fontSize: 14,
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
                      fontSize: 12,
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
        padding: const EdgeInsets.all(12),
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
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.pets, size: 16, color: Colors.orange),
                ),
                const SizedBox(width: 6),
                Text(
                  message.assistantType == AssistantMessageType.followUp
                      ? 'Scout Follow-Up'
                      : 'Scout Answer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

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
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                : MarkdownBody(
                    data: message.content.replaceAll('\\n', '\n'),
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                      strong: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      listBullet: const TextStyle(
                        fontSize: 13,
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
    ref.listen(interviewSessionProvider.select((data) => data.fullTranscript), (
      previous,
      current,
    ) {
      if (current.length > _lastTranscript.length) {
        _lastTranscript = current;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    // Watch only the data we need
    final fullTranscript = ref.watch(
      interviewSessionProvider.select((data) => data.fullTranscript),
    );
    final currentTranscription = ref.watch(
      interviewSessionProvider.select((data) => data.currentTranscription),
    );
    final sessionState = ref.watch(
      interviewSessionProvider.select((data) => data.state),
    );

    // Check if we have any content to show
    final hasFullTranscript = fullTranscript.isNotEmpty;
    final hasLiveTranscription =
        currentTranscription != null && currentTranscription.isNotEmpty;

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
            padding: const EdgeInsets.all(12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: !hasFullTranscript && !hasLiveTranscription
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

                        // Live transcription (currently being spoken)
                        if (hasLiveTranscription) ...[
                          if (hasFullTranscript) const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Recording indicator
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                child: _PulsingDot(),
                              ),
                              const SizedBox(width: 8),
                              // Live transcription
                              Expanded(
                                child: Text(
                                  currentTranscription,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.withValues(alpha: 0.8),
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Show listening indicator when recording but no current transcription
                        if (sessionState == InterviewSessionState.recording &&
                            !hasLiveTranscription) ...[
                          if (hasFullTranscript) const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                child: _PulsingDot(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Listening...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontStyle: FontStyle.italic,
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
