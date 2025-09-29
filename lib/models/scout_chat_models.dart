enum ChatSender { user, scout }

class ChatMessage {
  final String id;
  final String message;
  final ChatSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.message,
    required this.sender,
    required this.timestamp,
  });

  factory ChatMessage.user(String message) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      sender: ChatSender.user,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.scout(String message) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      sender: ChatSender.scout,
      timestamp: DateTime.now(),
    );
  }
}

class ScoutChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isSessionSetup;
  final int? sessionId;

  ScoutChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isSessionSetup = false,
    this.sessionId,
  });

  ScoutChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isSessionSetup,
    int? sessionId,
  }) {
    return ScoutChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSessionSetup: isSessionSetup ?? this.isSessionSetup,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}
