import 'package:flutter/foundation.dart';

import '../../models/conversation_models.dart';

/// Transcription state enum
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
/// Implemented by DeepgramAudioTranscriber which provides:
/// - WebSocket-based real-time streaming
/// - Word-by-word transcription (~200-300ms latency)
/// - Continuous streaming (no commit/wait needed)
/// - PCM16 audio streaming @ 16kHz
/// - Speaker diarization (identifies different speakers)
abstract class AudioTranscriber extends ChangeNotifier {
  // ==================== STATE GETTERS ====================

  /// Current transcription state (idle, recording, processing, etc.)
  TranscriptionState get state;

  /// Complete transcript from all processed audio
  String get transcript;

  /// Raw transcript (same as transcript for Deepgram - no display effects)
  String get rawTranscript;

  /// Latest transcribed word/segment (for highlighting in UI)
  String get latestSegment;

  /// Whether currently recording audio
  bool get isRecording;

  /// Number of words processed
  int get chunkCount;

  /// Number of pending chunks (always 0 for Deepgram - real-time streaming)
  int get pendingChunks;

  /// Speaker-segmented transcript (for dialog view)
  /// Groups consecutive words by speaker ID
  List<SpeakerSegment> get speakerSegments;

  /// Number of unique speakers detected
  int get speakerCount;

  // ==================== LIFECYCLE METHODS ====================

  /// Initialize the transcriber (check permissions, setup resources)
  /// Returns true if initialization successful, false otherwise
  Future<bool> initialize();

  /// Start recording and transcribing audio
  Future<void> startRecording();

  /// Stop recording and clean up resources
  Future<void> stopRecording();

  // ==================== CLEANUP ====================

  /// Dispose of resources and cleanup
  @override
  void dispose();
}
