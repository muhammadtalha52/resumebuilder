import 'package:flutter/foundation.dart';

/// Transcription state enum - shared across all transcriber implementations
enum TranscriptionState {
  idle,
  initializing,
  recording,
  processing,
  error,
  stopped,
}

/// Abstract interface for audio transcription services
///
/// Currently implemented by RealtimeAudioTranscriber which provides:
/// - WebSocket-based real-time streaming
/// - Near-instant transcription (~1-2 second delay)
/// - Server-side Voice Activity Detection
/// - PCM16 audio streaming @ 16kHz
abstract class AudioTranscriber extends ChangeNotifier {
  // ==================== STATE GETTERS ====================

  /// Current transcription state (idle, recording, processing, etc.)
  TranscriptionState get state;

  /// Complete transcript from all processed audio
  String get transcript;

  /// Latest transcribed segment (highlighted in UI)
  String get latestSegment;

  /// Whether currently recording audio
  bool get isRecording;

  /// Number of audio chunks/segments processed
  int get chunkCount;

  /// Number of pending chunks awaiting transcription
  int get pendingChunks;

  // ==================== LIFECYCLE METHODS ====================

  /// Initialize the transcriber (check permissions, setup resources)
  /// Returns true if initialization successful, false otherwise
  Future<bool> initialize();

  /// Start recording and transcribing audio
  Future<void> startRecording();

  /// Stop recording and clean up resources
  Future<void> stopRecording();

  // ==================== HELP REQUEST METHODS ====================

  /// Set cutoff point for "Get Help" requests
  /// Chunks/audio created after this point should be ignored
  /// to prevent including irrelevant context in help requests
  void setHelpRequestCutoff();

  /// Clear the help request cutoff and resume normal processing
  void clearHelpRequestCutoff();

  /// Force commit current audio buffer and wait for transcription to complete
  /// This ensures we capture the latest audio context before sending to backend
  ///
  /// [maxWaitMs] - Maximum time to wait in milliseconds
  Future<void> commitAndWaitForTranscription({int maxWaitMs = 5000});

  // ==================== CLEANUP ====================

  /// Dispose of resources and cleanup
  @override
  void dispose();
}
