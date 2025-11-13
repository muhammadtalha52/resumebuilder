import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../constants/app_colors.dart';
import '../models/meeting_history_response.dart';
import '../models/scout_chat_models.dart';
import '../providers/scout_chat_provider.dart';

class ScoutChatBottomSheet extends ConsumerStatefulWidget {
  final MeetingHistoryItem meeting;

  const ScoutChatBottomSheet({super.key, required this.meeting});

  @override
  ConsumerState<ScoutChatBottomSheet> createState() =>
      _ScoutChatBottomSheetState();
}

class _ScoutChatBottomSheetState extends ConsumerState<ScoutChatBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSessionSetup = false;

  @override
  void initState() {
    super.initState();
    // Setup chat session when bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupChatSession();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _setupChatSession() async {
    // Reset any previous session before setting up new one
    ref.read(scoutChatProvider.notifier).resetSession();
    await ref.read(scoutChatProvider.notifier).setupChatSession(widget.meeting);
    setState(() {
      _isSessionSetup = true;
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      ref.read(scoutChatProvider.notifier).sendMessage(message);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(scoutChatProvider);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Chat messages area
            Expanded(child: _buildChatArea(chatState)),

            // Input area
            _buildInputArea(chatState),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Scout avatar
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(
              'assets/icons/fox-mascot.png',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: 12),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat with Scout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  widget.meeting.isInterview
                      ? 'About your interview session'
                      : 'About your meeting session',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(ScoutChatState chatState) {
    if (!_isSessionSetup && chatState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Setting up Scout chat session...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (chatState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: ${chatState.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _setupChatSession(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatState.messages.length && chatState.isLoading) {
          return _buildTypingIndicator();
        }

        final message = chatState.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == ChatSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Scout avatar
            SizedBox(
              width: 32,
              height: 32,
              child: Image.asset(
                'assets/icons/fox-mascot.png',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.orange : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
              ),
              child: isUser
                  ? Text(
                      message.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: message.message.replaceAll('\\n', '\n'),
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
                        code: TextStyle(
                          fontSize: 12,
                          backgroundColor: Colors.grey.shade100,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            // User avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.shade500,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Scout avatar
          SizedBox(
            width: 32,
            height: 32,
            child: Image.asset(
              'assets/icons/fox-mascot.png',
              width: 32,
              height: 32,
            ),
          ),
          const SizedBox(width: 8),

          // Typing animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(200),
                const SizedBox(width: 4),
                _buildTypingDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.4, end: 1.0),
      builder: (context, value, child) {
        return AnimatedBuilder(
          animation: AnimationController(
            duration: const Duration(milliseconds: 600),
            vsync: Navigator.of(context),
          )..repeat(reverse: true),
          builder: (context, child) {
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputArea(ScoutChatState chatState) {
    final isInputEnabled =
        _isSessionSetup && !chatState.isLoading && !chatState.hasReachedLimit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Question counter
          if (_isSessionSetup) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questions: ${chatState.questionCount}/${chatState.maxQuestions}',
                  style: TextStyle(
                    fontSize: 12,
                    color: chatState.hasReachedLimit
                        ? Colors.red.shade600
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (chatState.hasReachedLimit)
                  Text(
                    'Limit reached',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Input field and send button
          Row(
            children: [
              // Message input field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: chatState.hasReachedLimit
                        ? 'Question limit reached'
                        : 'Ask Scout about your session...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    filled: true,
                    fillColor: chatState.hasReachedLimit
                        ? Colors.grey[100]
                        : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => isInputEnabled ? _sendMessage() : null,
                  enabled: isInputEnabled,
                ),
              ),
              const SizedBox(width: 12),

              // Send button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isInputEnabled ? Colors.orange : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: isInputEnabled ? _sendMessage : null,
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
