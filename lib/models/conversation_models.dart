// Simple ID generator instead of uuid package
int _messageIdCounter = 0;

String _generateMessageId() =>
    'msg_${DateTime.now().millisecondsSinceEpoch}_${++_messageIdCounter}';

enum MessageType { user, assistant, system }

enum AssistantMessageType { help, followUp }

enum MessageState {
  composing, // User is still recording/typing
  sending, // Message is being sent to API
  sent, // Message sent successfully
  error, // Message failed to send
}

class ConversationMessage {
  final String id;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final MessageState state;
  final String? error;
  final AssistantMessageType? assistantType; // For tracking help vs follow-up

  ConversationMessage({
    String? id,
    required this.type,
    required this.content,
    DateTime? timestamp,
    this.state = MessageState.sent,
    this.error,
    this.assistantType,
  }) : id = id ?? _generateMessageId(),
       timestamp = timestamp ?? DateTime.now();

  ConversationMessage copyWith({
    String? id,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    MessageState? state,
    String? error,
    AssistantMessageType? assistantType,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      state: state ?? this.state,
      error: error ?? this.error,
      assistantType: assistantType ?? this.assistantType,
    );
  }

  // Helper getters
  bool get isUser => type == MessageType.user;

  bool get isAssistant => type == MessageType.assistant;

  bool get isSystem => type == MessageType.system;

  bool get isComposing => state == MessageState.composing;

  bool get isSending => state == MessageState.sending;

  bool get hasFailed => state == MessageState.error;

  @override
  String toString() {
    return 'ConversationMessage(id: $id, type: $type, content: ${content.length > 50 ? content.substring(0, 50) + '...' : content}, state: $state)';
  }
}

// Conversation metadata
class ConversationData {
  final List<ConversationMessage> messages;
  final String? currentUserId; // ID of message being composed
  final String? currentAssistantId; // ID of assistant response being generated
  final bool isRecording;
  final bool isProcessing;
  final DateTime? lastActivity;

  ConversationData({
    this.messages = const [],
    this.currentUserId,
    this.currentAssistantId,
    this.isRecording = false,
    this.isProcessing = false,
    this.lastActivity,
  });

  ConversationData copyWith({
    List<ConversationMessage>? messages,
    String? currentUserId,
    String? currentAssistantId,
    bool? isRecording,
    bool? isProcessing,
    DateTime? lastActivity,
  }) {
    return ConversationData(
      messages: messages ?? this.messages,
      currentUserId: currentUserId,
      currentAssistantId: currentAssistantId,
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  // Helper methods
  ConversationMessage? getCurrentUserMessage() {
    if (currentUserId == null) return null;
    return messages.firstWhere(
      (msg) => msg.id == currentUserId,
      orElse: () => throw StateError('Current user message not found'),
    );
  }

  ConversationMessage? getCurrentAssistantMessage() {
    if (currentAssistantId == null) return null;
    return messages.firstWhere(
      (msg) => msg.id == currentAssistantId,
      orElse: () => throw StateError('Current assistant message not found'),
    );
  }

  // Get conversation as a single transcript for API calls
  String getFullTranscript() {
    return messages
        .where((msg) => msg.isUser && msg.state == MessageState.sent)
        .map((msg) => msg.content)
        .join(' ');
  }

  @override
  String toString() {
    return 'ConversationData(messages: ${messages.length}, isRecording: $isRecording, isProcessing: $isProcessing)';
  }
}
