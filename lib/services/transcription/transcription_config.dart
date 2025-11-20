/// Configuration for real-time WebSocket transcription
///
/// Uses OpenAI's Realtime API for near-instant transcription with:
/// - WebSocket streaming (no disk I/O)
/// - Real-time partial updates (~1-2 second delay)
/// - Server-side Voice Activity Detection
/// - PCM16 audio format @ 16kHz
class TranscriptionConfig {
  // ==================== REALTIME CONFIG ====================

  /// Configuration for real-time transcription
  static const realtimeConfig = {
    /// OpenAI model to use
    /// Options: 'whisper-1', 'gpt-4o-transcribe', 'gpt-4o-mini-transcribe'
    'model': 'gpt-4o-transcribe',

    /// Audio format (must be pcm16 for realtime API)
    'audioFormat': 'pcm16',

    /// Sample rate in Hz (16000 or 24000 recommended for speech)
    'sampleRate': 16000,

    /// Audio buffer size in milliseconds (how often to send audio chunks)
    /// Lower = more frequent updates but more overhead
    /// Higher = less frequent updates but more efficient
    'audioBufferMs': 250,

    /// Voice Activity Detection (VAD) threshold (0.0 - 1.0)
    /// Lower = more sensitive to speech
    /// Higher = requires louder/clearer speech
    'vadThreshold': 0.5,

    /// Silence duration in ms before considering speech ended
    'silenceDurationMs': 500,

    /// Prefix padding in ms (context before speech starts)
    'prefixPaddingMs': 300,

    /// Noise reduction type
    /// Options: 'near_field' (close mic), 'far_field' (distant mic)
    'noiseReduction': 'near_field',

    /// Include log probabilities for confidence scores
    'includeLogProbs': false,

    /// WebSocket reconnection attempts
    'maxReconnectAttempts': 3,

    /// Delay between reconnection attempts in ms
    'reconnectDelayMs': 1000,

    /// WebSocket ping interval to keep connection alive (ms)
    'pingIntervalMs': 30000,
  };
}
