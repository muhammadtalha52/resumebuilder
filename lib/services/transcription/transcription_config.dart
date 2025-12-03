/// Configuration for Deepgram real-time transcription
///
/// Deepgram provides true word-by-word streaming with:
/// - Low latency (~200-300ms)
/// - No commit/wait logic needed
/// - Better accuracy for continuous speech
class TranscriptionConfig {
  /// Configuration for Deepgram real-time transcription
  static const deepgramConfig = {
    /// Deepgram model to use
    /// Options: 'nova-3' (latest, best accuracy), 'nova-2', 'nova-2-meeting'
    /// Using 'nova-3' for best accuracy in interview transcription
    'model': 'nova-3',

    /// Language code
    'language': 'en-US',

    /// Audio encoding format
    /// Options: 'linear16' (PCM16), 'flac', 'mulaw', 'amr-nb', 'amr-wb', 'opus', 'speex'
    'encoding': 'linear16',

    /// Sample rate in Hz (must match audio input)
    'sampleRate': 16000,

    /// Number of audio channels (1 = mono, 2 = stereo)
    'channels': 1,

    /// Enable interim results (partial transcripts while speaking)
    /// true = get words as they're spoken, false = wait for final transcript
    'interimResults': true,

    /// Enable punctuation in transcripts
    'punctuate': true,

    /// Enable smart formatting (numbers, dates, etc.)
    'smartFormat': true,

    /// Enable profanity filtering
    'profanityFilter': false,

    /// Enable diarization (speaker identification)
    /// Useful if multiple speakers, but adds latency
    'diarize': false,

    /// End of speech detection sensitivity (ms of silence before finalizing)
    /// Lower = faster response, Higher = waits longer for speaker to continue
    'endpointing': 300,

    /// Utterance end detection (ms) - when to finalize an utterance
    /// Longer values = fewer interruptions in transcript
    'utteranceEndMs': 1000,

    /// Voice Activity Detection (VAD) model
    /// Options: 'true' (enable), 'false' (disable)
    'vadEvents': true,

    /// Filler words handling
    /// 'true' = include "um", "uh", etc. | 'false' = filter them out
    'fillerWords': false,

    /// Keywords to boost (improve recognition accuracy for specific terms)
    /// Add interview-specific terms if needed
    'keywords': <String>[],

    /// Maximum reconnection attempts
    'maxReconnectAttempts': 3,

    /// Delay between reconnection attempts in ms
    'reconnectDelayMs': 1000,

    /// WebSocket keep-alive interval (ms)
    /// Deepgram requires periodic keep-alive messages
    'keepAliveIntervalMs': 10000,
  };
}
