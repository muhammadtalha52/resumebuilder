import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/conversation_models.dart';
import '../../providers/continuous_transcription_provider.dart';
import '../../constants/app_colors.dart';
import 'message_bubble.dart';

class ConversationView extends ConsumerStatefulWidget {
  const ConversationView({super.key});

  @override
  ConsumerState<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends ConsumerState<ConversationView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionData = ref.watch(continuousTranscriptionProvider);

    // For now, create mock conversation from legacy transcript
    // This will be replaced with actual conversation data
    final messages = _createMockMessagesFromTranscript(sessionData);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Interview Conversation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (messages.isNotEmpty)
                  Text(
                    '${messages.length} message${messages.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(messages),
          ),

          // Current transcription (if recording)
          if (sessionData.currentTranscription != null &&
              sessionData.currentTranscription!.isNotEmpty)
            _buildCurrentTranscription(sessionData),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'Start recording to begin conversation',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the microphone button to record interviewer questions',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<ConversationMessage> messages) {
    // Auto-scroll to bottom when new messages are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isLastMessage = index == messages.length - 1;

        return MessageBubble(
          message: message,
          showAvatar: true,
          showTimestamp: isLastMessage,
        );
      },
    );
  }

  Widget _buildCurrentTranscription(InterviewSessionData sessionData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Recording indicator
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 1,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),

          // Current speech
          Expanded(
            child: Text(
              sessionData.currentTranscription!,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TEMPORARY: Create mock messages from legacy transcript
  // This will be replaced when we fully transition to conversation model
  List<ConversationMessage> _createMockMessagesFromTranscript(
    InterviewSessionData sessionData,
  ) {
    final transcript = sessionData.fullTranscript.trim();
    if (transcript.isEmpty) return [];

    final messages = <ConversationMessage>[];

    // Split transcript into sentences and create alternating messages
    // This is a simple approach for demonstration
    final sentences = transcript.split(RegExp(r'[.!?]+'));

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();
      if (sentence.isEmpty) continue;

      // Create user message (interviewer speech)
      messages.add(
        ConversationMessage(
          type: MessageType.user,
          content: sentence,
          timestamp: DateTime.now().subtract(
            Duration(minutes: sentences.length - i),
          ),
        ),
      );
    }

    // Add Scout response if we have help response
    if (sessionData.helpResponse != null) {
      messages.add(
        ConversationMessage(
          type: MessageType.assistant,
          content: sessionData.helpResponse!,
          timestamp: sessionData.helpTimestamp ?? DateTime.now(),
        ),
      );
    }

    return messages;
  }
}
