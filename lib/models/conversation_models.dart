import 'dart:convert';

// Simple ID generator instead of uuid package
int _messageIdCounter = 0;

String _generateMessageId() =>
    'msg_${DateTime.now().millisecondsSinceEpoch}_${++_messageIdCounter}';

/// Entry type for unified conversation flow
enum ConversationEntryType { speaker, scout }

/// Unified model for conversation entries - can be speaker or scout response
/// Used for displaying continuous conversation flow
class ConversationEntry {
  final ConversationEntryType type;
  final int? speakerId; // Only for speaker type
  final String text;
  final double? startTime;
  final double? endTime;

  ConversationEntry({
    required this.type,
    this.speakerId,
    required this.text,
    this.startTime,
    this.endTime,
  });

  /// Create a speaker entry
  factory ConversationEntry.speaker({
    required int speakerId,
    required String text,
    double? startTime,
    double? endTime,
  }) {
    return ConversationEntry(
      type: ConversationEntryType.speaker,
      speakerId: speakerId,
      text: text,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Create a scout response entry
  factory ConversationEntry.scout({required String text}) {
    return ConversationEntry(type: ConversationEntryType.scout, text: text);
  }

  /// Create from SpeakerSegment (for compatibility)
  factory ConversationEntry.fromSpeakerSegment(SpeakerSegment segment) {
    return ConversationEntry(
      type: ConversationEntryType.speaker,
      speakerId: segment.speakerId,
      text: segment.text,
      startTime: segment.startTime,
      endTime: segment.endTime,
    );
  }

  bool get isSpeaker => type == ConversationEntryType.speaker;
  bool get isScout => type == ConversationEntryType.scout;

  /// Get display label
  String getDisplayLabel() {
    if (isScout) return 'Scout Response';
    return 'Speaker ${(speakerId ?? 0) + 1}';
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type == ConversationEntryType.scout ? 'scout' : 'speaker',
      if (speakerId != null) 's': speakerId,
      't': text,
      if (startTime != null) 'st': startTime,
      if (endTime != null) 'et': endTime,
    };
  }

  factory ConversationEntry.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final isScout = typeStr == 'scout';

    return ConversationEntry(
      type: isScout
          ? ConversationEntryType.scout
          : ConversationEntryType.speaker,
      speakerId: json['s'] as int?,
      text: json['t'] as String? ?? '',
      startTime: (json['st'] as num?)?.toDouble(),
      endTime: (json['et'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() =>
      'ConversationEntry(type: $type, speaker: $speakerId, text: ${text.length > 30 ? text.substring(0, 30) + '...' : text})';

  /// Encode list of entries to JSON string for saving
  static String encodeList(List<ConversationEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  /// Decode JSON string to list of entries
  static List<ConversationEntry>? decodeList(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      if (!jsonString.trimLeft().startsWith('[')) {
        return null;
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map(
            (item) => ConversationEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('[ConversationEntry] Parse error: $e');
      return null;
    }
  }
}

/// Model for storing speaker-segmented transcript (kept for transcriber compatibility)
/// Each segment represents continuous speech from a single speaker
class SpeakerSegment {
  final int speakerId;
  final String text;
  final double? startTime;
  final double? endTime;

  SpeakerSegment({
    required this.speakerId,
    required this.text,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      's': speakerId,
      't': text,
      if (startTime != null) 'st': startTime,
      if (endTime != null) 'et': endTime,
    };
  }

  factory SpeakerSegment.fromJson(Map<String, dynamic> json) {
    return SpeakerSegment(
      speakerId: json['s'] as int? ?? 0,
      text: json['t'] as String? ?? '',
      startTime: (json['st'] as num?)?.toDouble(),
      endTime: (json['et'] as num?)?.toDouble(),
    );
  }

  /// Get display label for speaker
  /// Always returns "Speaker 1", "Speaker 2", etc.
  String getDisplayLabel(int totalSpeakers) {
    return 'Speaker ${speakerId + 1}';
  }

  /// Convert to ConversationEntry
  ConversationEntry toConversationEntry() {
    return ConversationEntry.fromSpeakerSegment(this);
  }

  @override
  String toString() => 'SpeakerSegment(speaker: $speakerId, text: $text)';
}

/// Model for storing transcript-answer pairs (for saving and displaying history)
/// Supports both plain text transcript (legacy) and speaker-segmented transcript (new)
class TranscriptAnswerPair {
  final String id;
  final String transcript; // Plain text fallback
  final List<SpeakerSegment>? segments; // Speaker-segmented transcript (new)
  final String answer;
  final DateTime timestamp;
  final String answerType; // 'help' or 'followUp'

  TranscriptAnswerPair({
    String? id,
    required this.transcript,
    this.segments,
    required this.answer,
    DateTime? timestamp,
    this.answerType = 'help',
  }) : id = id ?? _generateMessageId(),
       timestamp = timestamp ?? DateTime.now();

  /// Check if this pair has speaker segments
  bool get hasSegments => segments != null && segments!.isNotEmpty;

  /// Get unique speaker count from segments
  int get speakerCount {
    if (!hasSegments) return 0;
    return segments!.map((s) => s.speakerId).toSet().length;
  }

  /// Get plain text transcript from segments (for backward compatibility)
  String get fullTranscript {
    if (hasSegments) {
      return segments!.map((s) => s.text).join(' ');
    }
    return transcript;
  }

  TranscriptAnswerPair copyWith({
    String? transcript,
    List<SpeakerSegment>? segments,
    String? answer,
    DateTime? timestamp,
    String? answerType,
  }) {
    return TranscriptAnswerPair(
      id: id,
      transcript: transcript ?? this.transcript,
      segments: segments ?? this.segments,
      answer: answer ?? this.answer,
      timestamp: timestamp ?? this.timestamp,
      answerType: answerType ?? this.answerType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      't': transcript,
      if (segments != null && segments!.isNotEmpty)
        'seg': segments!.map((s) => s.toJson()).toList(),
      'a': answer,
      'ts': timestamp.toIso8601String(),
      'type': answerType,
    };
  }

  factory TranscriptAnswerPair.fromJson(Map<String, dynamic> json) {
    // Parse segments if available
    List<SpeakerSegment>? segments;
    if (json['seg'] != null) {
      final segList = json['seg'] as List<dynamic>;
      segments = segList
          .map((s) => SpeakerSegment.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return TranscriptAnswerPair(
      id: json['id'] as String?,
      transcript: json['t'] as String? ?? '',
      segments: segments,
      answer: json['a'] as String? ?? '',
      timestamp: json['ts'] != null
          ? DateTime.tryParse(json['ts'] as String)
          : null,
      answerType: json['type'] as String? ?? 'help',
    );
  }

  /// Encode list of pairs to JSON string for saving
  static String encodeList(List<TranscriptAnswerPair> pairs) {
    return jsonEncode(pairs.map((p) => p.toJson()).toList());
  }

  /// Decode JSON string to list of pairs for displaying
  static List<TranscriptAnswerPair>? decodeList(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      // Check if it's JSON format (starts with '[')
      if (!jsonString.trimLeft().startsWith('[')) {
        return null; // Old format, not JSON
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map(
            (item) =>
                TranscriptAnswerPair.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('[TranscriptAnswerPair] Not JSON format or parse error: $e');
      return null; // Return null for old format strings
    }
  }
}

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
