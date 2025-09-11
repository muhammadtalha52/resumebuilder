import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/conversation_models.dart';

class MessageBubble extends StatelessWidget {
  final ConversationMessage message;
  final bool showAvatar;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showTimestamp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser && showAvatar) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageContainer(context),
                  if (showTimestamp) ...[
                    const SizedBox(height: 4),
                    _buildTimestamp(),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: message.isUser
          ? AppColors.primary
          : Colors.orange.withValues(alpha: 0.2),
      child: message.isUser
          ? const Icon(Icons.person, size: 16, color: Colors.white)
          : Image.asset(
              'assets/icons/fox-mascot.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.pets, size: 16, color: Colors.orange),
            ),
    );
  }

  Widget _buildMessageContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isUser
            ? AppColors.primary
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomLeft: message.isUser
              ? const Radius.circular(18)
              : const Radius.circular(4),
          bottomRight: message.isUser
              ? const Radius.circular(4)
              : const Radius.circular(18),
        ),
        border: message.isAssistant
            ? Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isAssistant) ...[
            Row(
              children: [
                const Icon(Icons.pets, size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                const Text(
                  'Scout the Fox',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          _buildMessageContent(context),
          if (message.state == MessageState.sending) ...[
            const SizedBox(height: 8),
            _buildLoadingIndicator(),
          ] else if (message.hasFailed) ...[
            const SizedBox(height: 8),
            _buildErrorIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.isComposing && message.content.isEmpty) {
      return _buildTypingIndicator();
    }

    return SelectableText(
      message.content,
      style: TextStyle(
        fontSize: 15,
        height: 1.4,
        color: message.isUser ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypingDot(0),
          const SizedBox(width: 4),
          _buildTypingDot(1),
          const SizedBox(width: 4),
          _buildTypingDot(2),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, value, child) {
        return AnimatedOpacity(
          opacity: value,
          duration: Duration(milliseconds: 200 + (index * 100)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Sending...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 14, color: Colors.red),
        const SizedBox(width: 6),
        Text(
          message.error ?? 'Failed to send',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.red,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Text(
        _formatTimestamp(message.timestamp),
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
