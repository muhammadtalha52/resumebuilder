import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:skillresy/utils/keys.dart';

enum TranscriptionState {
  idle,
  initializing,
  recording,
  processing,
  error,
  stopped,
}

class TranscriptionChunk {
  final String audioPath;
  final int chunkIndex;
  final DateTime timestamp;
  bool isProcessing = false;
  bool isProcessed = false;
  String? transcription;

  TranscriptionChunk({
    required this.audioPath,
    required this.chunkIndex,
    required this.timestamp,
  });
}

class ContinuousAudioTranscriber extends ChangeNotifier {
  // Core components
  final AudioRecorder _recorder = AudioRecorder();
  final Queue<TranscriptionChunk> _chunkQueue = Queue<TranscriptionChunk>();
  final Dio _dio = Dio();

  // State management
  TranscriptionState _state = TranscriptionState.idle;
  String _fullTranscript = '';
  String _latestSegment = '';
  int _chunkCounter = 0;

  // Timers and control
  Timer? _chunkRotationTimer;
  bool _isDisposed = false;
  int?
  _helpRequestCutoff; // Chunk ID when "Get Help" was clicked - ignore chunks > this

  // Configuration - optimized for real-time
  static const int chunkDurationSeconds = 5; // Short chunks for fast feedback
  static const int maxParallelTranscriptions = 2; // Process 2 chunks at once

  // Performance tracking
  int _successfulTranscriptions = 0;
  int _failedTranscriptions = 0;

  // Debug info
  final List<String> _debugLog = [];

  // Getters
  String get transcript => _fullTranscript;

  String get latestSegment => _latestSegment;

  TranscriptionState get state => _state;

  bool get isRecording => _state == TranscriptionState.recording;

  int get chunkCount => _chunkCounter;

  int get pendingChunks => _chunkQueue.where((c) => !c.isProcessed).length;

  // Initialize and check permissions
  Future<bool> initialize() async {
    _setState(TranscriptionState.initializing);

    try {
      if (!await _recorder.hasPermission()) {
        _setState(TranscriptionState.error);
        return false;
      }

      await _cleanupOldAudioFiles();
      _setState(TranscriptionState.idle);
      return true;
    } catch (e) {
      _setState(TranscriptionState.error);
      return false;
    }
  }

  // Start continuous recording with 5-second chunks
  Future<void> startRecording() async {
    if (_state == TranscriptionState.recording) {
      return;
    }

    _log('🎤 RECORDING START');
    _resetState();
    _setState(TranscriptionState.recording);

    try {
      // Start first chunk
      await _startNewChunk();

      // Set up timer to rotate chunks every 5 seconds
      _chunkRotationTimer = Timer.periodic(
        Duration(seconds: chunkDurationSeconds),
        (_) async {
          if (_state == TranscriptionState.recording && !_isDisposed) {
            await _rotateChunk();
          }
        },
      );
    } catch (e) {
      _setState(TranscriptionState.error);
    }
  }

  // Start recording a new chunk
  Future<void> _startNewChunk() async {
    if (_isDisposed) return;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/chunk_${_chunkCounter}_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000, // Increased bitrate for better quality
          sampleRate: 44100, // Higher sample rate for better capture
          numChannels: 1, // Mono is sufficient for speech
        ),
        path: path,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Rotate to a new chunk and process the previous one
  Future<void> _rotateChunk() async {
    try {
      // Stop current recording
      final completedPath = await _recorder.stop();
      if (completedPath == null) {
        await _startNewChunk();
        return;
      }

      // Create chunk object
      final chunk = TranscriptionChunk(
        audioPath: completedPath,
        chunkIndex: _chunkCounter,
        timestamp: DateTime.now(),
      );

      _chunkQueue.add(chunk);
      _chunkCounter++;

      // Start new chunk immediately (no gap in recording)
      if (_state == TranscriptionState.recording && !_isDisposed) {
        await _startNewChunk();
      }

      _log('⏰ CHUNK ${chunk.chunkIndex} QUEUED');
      _processTranscriptionQueue();
    } catch (e) {
      // Try to recover by starting a new chunk
      if (_state == TranscriptionState.recording) {
        await _startNewChunk();
      }
    }
  }

  // Process pending transcriptions in parallel
  Future<void> _processTranscriptionQueue() async {
    // Count how many are currently processing
    final processingCount = _chunkQueue.where((c) => c.isProcessing).length;

    // Process up to MAX_PARALLEL_TRANSCRIPTIONS at once
    final availableSlots = maxParallelTranscriptions - processingCount;
    if (availableSlots <= 0) return;

    // Find chunks that need processing
    final pendingChunks = _chunkQueue
        .where((c) => !c.isProcessing && !c.isProcessed)
        .take(availableSlots)
        .toList();

    // Process each chunk
    for (final chunk in pendingChunks) {
      _transcribeChunk(chunk);
    }
  }

  // Transcribe a single chunk using Whisper API
  Future<void> _transcribeChunk(TranscriptionChunk chunk) async {
    chunk.isProcessing = true;

    try {
      // Skip API call for chunks created after "Get Help" was clicked
      if (_helpRequestCutoff != null &&
          chunk.chunkIndex > _helpRequestCutoff!) {
        _log(
          '🚫 SKIP CHUNK ${chunk.chunkIndex} (ignored - after Get Help cutoff $_helpRequestCutoff)',
        );
        chunk.isProcessed = true;
        chunk.isProcessing = false;

        // Clean up audio file
        final file = File(chunk.audioPath);
        if (await file.exists()) {
          await file.delete();
        }
        return;
      }

      final startTime = DateTime.now();
      final file = File(chunk.audioPath);
      if (!await file.exists()) {
        chunk.isProcessed = true;
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.length < 50000) {
        _log('⚡ SKIP CHUNK ${chunk.chunkIndex} (${bytes.length}b - silence)');
        chunk.isProcessed = true;
        await file.delete();
        return;
      }

      if (!_isValidM4AFile(bytes)) {
        _log('❌ SKIP CHUNK ${chunk.chunkIndex} (invalid format)');
        chunk.isProcessed = true;
        await file.delete();
        return;
      }

      // TEMPORARILY DISABLED: Audio analysis needs improvement for M4A format
      // bool isLikelySilent = _isAudioLikelySilent(bytes);
      // if (isLikelySilent) {
      //   _log(
      //     '💰 COST SAVE: Skipping silent chunk ${chunk.chunkIndex} based on audio analysis - avoiding \$0.0005 API call',
      //   );
      //   chunk.isProcessed = true;
      //   await file.delete();
      //   return;
      // }

      // Prepare FormData for Dio - minimal config to avoid hallucinations
      final formData = FormData.fromMap({
        'model': 'gpt-4o-transcribe',
        'language': 'en',
        'response_format': 'text',
        'temperature': 0, // Force deterministic output, no creativity
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'audio.m4a',
          contentType: DioMediaType('audio', 'm4a'),
        ),
      });

      // Send request with timeout using Dio
      final response = await _dio
          .post(
            'https://api.openai.com/v1/audio/transcriptions',
            data: formData,
            options: Options(
              headers: {'Authorization': 'Bearer ${AppKeys.openAiApiKey}'},
              sendTimeout: Duration(seconds: 10),
              receiveTimeout: Duration(seconds: 10),
            ),
          )
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                'Transcription timeout for chunk ${chunk.chunkIndex}',
              );
            },
          );

      if (response.statusCode == 200) {
        final responseText = response.data?.toString().trim() ?? '';

        final endTime = DateTime.now();
        final processingTime = endTime.difference(startTime).inMilliseconds;
        _log(
          '🔍 CHUNK ${chunk.chunkIndex} RESULT: "$responseText" (${processingTime}ms)',
        );

        // Filter out common Whisper hallucinations and prompt leakage
        final hallucinations = [
          'thank you for watching',
          'thanks for watching',
          'please subscribe',
          'like and subscribe',
          'see you next time',
          'bye bye',
          'music playing',
          '[music]',
          '[applause]',
          'foreign',
          'thank you',
          'transcribe exactly',
          'transcribe exactly what is spoken',
          'What\'s that mean? I don\'t know what you mean.'
              'without adding',
          'assuming',
          'completing any words',
          'do not add punctuation',
          'do not generate text',
          'Yes.Bye',
          'You',
          'do not generate text',
        ];

        final lowerResponse = responseText.toLowerCase();
        bool isHallucination = false;
        String matchedHallucination = '';

        // Check if response is a known hallucination
        for (final hallucination in hallucinations) {
          if (lowerResponse == hallucination ||
              lowerResponse.contains(hallucination)) {
            // Remove length restriction to catch all variations
            isHallucination = true;
            matchedHallucination = hallucination;
            _log(
              '🚫 Filtered hallucination in chunk ${chunk.chunkIndex}: "$responseText" (matched: "$hallucination")',
            );
            break;
          }
        }

        // Only accept meaningful transcriptions
        if (!isHallucination && responseText.length > 2) {
          chunk.transcription = responseText;
          chunk.isProcessed = true;
          chunk.isProcessing = false;

          // Update transcript
          _appendToTranscript(chunk);
          _successfulTranscriptions++;

          _log('✅ CHUNK ${chunk.chunkIndex} ACCEPTED');
        } else {
          // Mark as processed but don't add to transcript
          chunk.isProcessed = true;
          chunk.isProcessing = false;

          _log('🚫 CHUNK ${chunk.chunkIndex} REJECTED');
        }

        // Clean up audio file
        await file.delete();
      } else {
        throw Exception('API error: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ CHUNK ${chunk.chunkIndex} FAILED: $e');
      chunk.isProcessing = false;
      _failedTranscriptions++;
      chunk.isProcessed = true;

      try {
        final file = File(chunk.audioPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (deleteError) {}
    }

    // Clean up old processed chunks from queue
    _cleanupProcessedChunks();
  }

  // Validate M4A file format to prevent API errors
  bool _isValidM4AFile(List<int> audioBytes) {
    try {
      // M4A files should start with specific magic bytes
      // M4A files have "ftyp" box at the beginning (after potential free space)
      if (audioBytes.length < 12) return false;

      // Look for 'ftyp' signature in the first 32 bytes
      for (int i = 0; i < audioBytes.length - 4 && i < 32; i++) {
        if (audioBytes[i] == 0x66 && // 'f'
            audioBytes[i + 1] == 0x74 && // 't'
            audioBytes[i + 2] == 0x79 && // 'y'
            audioBytes[i + 3] == 0x70) {
          // 'p'
          return true;
        }
      }

      // Also accept if the file has reasonable size and structure
      // (Some M4A files may have different headers)
      return audioBytes.length > 1000;
    } catch (e) {
      return true;
    }
  }

  // Append transcription to full transcript in order
  void _appendToTranscript(TranscriptionChunk chunk) {
    // Get all processed chunks in order
    final processedChunks =
        _chunkQueue
            .where((c) => c.isProcessed && c.transcription != null)
            .toList()
          ..sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));

    // Rebuild transcript from all chunks
    final transcriptParts = <String>[];
    for (final processedChunk in processedChunks) {
      if (processedChunk.transcription!.isNotEmpty) {
        transcriptParts.add(processedChunk.transcription!);
      }
    }

    _fullTranscript = transcriptParts.join(' ');
    _latestSegment = chunk.transcription ?? '';

    notifyListeners();
  }

  // FORCE STOP recording immediately - no waiting for anything
  Future<void> stopRecording() async {
    _log('🛑 FORCE STOP - No waiting, immediate shutdown');

    // Cancel timer immediately
    _chunkRotationTimer?.cancel();

    // Force stop recorder with short timeout
    try {
      await _recorder.stop().timeout(Duration(milliseconds: 500));
    } catch (e) {
      _log('🔥 Recorder force stopped (timeout ignored): $e');
    }

    // Clear all pending chunks - don't process them
    _chunkQueue.clear();

    // Set state to stopped immediately
    _setState(TranscriptionState.stopped);

    // Background cleanup (don't await)
    _cleanupInBackground();

    _log('⚡ INSTANT STOP COMPLETE - Background cleanup started');
  }

  // Background cleanup without blocking UI
  void _cleanupInBackground() async {
    try {
      _log('🧹 Background cleanup started');

      // Clean up audio files
      await _cleanupOldAudioFiles();

      _log('🧹 Background cleanup completed');
    } catch (e) {
      _log('🧹 Background cleanup error (ignored): $e');
    }
  }

  // Clean up old processed chunks to save memory
  void _cleanupProcessedChunks() {
    // Keep only last 20 chunks in memory
    while (_chunkQueue.length > 20) {
      final oldest = _chunkQueue.first;
      if (oldest.isProcessed) {
        _chunkQueue.removeFirst();
        // Delete audio file if it still exists
        File(oldest.audioPath).delete().catchError((error) {
          // Ignore deletion errors
          return File(oldest.audioPath);
        });
      } else {
        break; // Don't remove unprocessed chunks
      }
    }
  }

  // Clean up all temporary audio files
  Future<void> _cleanupOldAudioFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync().where((f) => f.path.contains('chunk_'));
      for (final file in files) {
        await file.delete();
      }
    } catch (e) {}
  }

  // Reset state for fresh start
  void _resetState() {
    _isDisposed = false;
    _fullTranscript = '';
    _latestSegment = '';
    _chunkCounter = 0;
    _successfulTranscriptions = 0;
    _failedTranscriptions = 0;
    _chunkQueue.clear();
    _debugLog.clear();
  }

  // State management
  void _setState(TranscriptionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  // Debug logging
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    final logMessage = '[$timestamp] $message';
    if (kDebugMode) {
      print('AudioTranscriber: $logMessage');
    }
    _debugLog.add(logMessage);
    if (_debugLog.length > 100) {
      _debugLog.removeAt(0);
    }
  }

  // Get debug information
  String get debugInfo {
    return '''
State: $_state
Chunks recorded: $_chunkCounter
Successful transcriptions: $_successfulTranscriptions
Failed transcriptions: $_failedTranscriptions
Pending chunks: $pendingChunks
Transcript length: ${_fullTranscript.length} chars
''';
  }

  List<String> get debugLog => List.unmodifiable(_debugLog);

  // Method to get current queue status for timing analysis
  String getQueueStatus() {
    final processing = _chunkQueue.where((c) => c.isProcessing).length;
    final pending = _chunkQueue
        .where((c) => !c.isProcessing && !c.isProcessed)
        .length;
    final completed = _chunkQueue.where((c) => c.isProcessed).length;

    _log(
      '🔍 QUEUE STATUS: ${processing} processing | ${pending} pending | ${completed} completed | Total: ${_chunkQueue.length}',
    );
    return _fullTranscript;
  }

  // Set cutoff point for Get Help - ignore chunks created after this point
  void setHelpRequestCutoff() {
    _helpRequestCutoff = _chunkCounter; // Current chunk being recorded
    _log('🔒 HELP CUTOFF SET: Ignoring chunks > $_helpRequestCutoff');
  }

  // Clear cutoff and resume normal processing
  void clearHelpRequestCutoff() {
    if (_helpRequestCutoff != null) {
      _log(
        '🔓 HELP CUTOFF CLEARED: Resuming normal processing (was $_helpRequestCutoff)',
      );
      _helpRequestCutoff = null;
    }
  }

  // Wait for all chunks up to the cutoff to complete (focused waiting for Get Help)
  Future<void> waitForChunksUpToCutoff({int maxWaitMs = 5000}) async {
    if (_helpRequestCutoff == null) {
      _log('❌ WAIT ERROR: No cutoff set - cannot wait');
      return;
    }

    final startTime = DateTime.now();
    final cutOffChunkId = _helpRequestCutoff!;

    _log(
      '⏳ WAIT START: Waiting for chunks ≤ $cutOffChunkId (max ${maxWaitMs}ms)',
    );

    while (DateTime.now().difference(startTime).inMilliseconds < maxWaitMs) {
      // Check if all relevant chunks (≤ cutoff) are processed
      final relevantChunks = _chunkQueue.where(
        (c) => c.chunkIndex <= cutOffChunkId,
      );
      final unprocessedRelevant = relevantChunks.where((c) => !c.isProcessed);

      if (unprocessedRelevant.isEmpty) {
        final waitTime = DateTime.now().difference(startTime).inMilliseconds;
        _log(
          '✅ WAIT COMPLETE: All chunks ≤ $cutOffChunkId processed (${waitTime}ms)',
        );
        return;
      }

      // Log current waiting status
      final unprocessedIds =
          unprocessedRelevant.map((c) => c.chunkIndex).toList()..sort();
      _log('⏳ WAITING FOR: chunks $unprocessedIds');

      // Wait a bit before checking again
      await Future.delayed(Duration(milliseconds: 100));
    }

    // Timeout reached
    final timeoutTime = DateTime.now().difference(startTime).inMilliseconds;
    final stillPending =
        _chunkQueue
            .where((c) => c.chunkIndex <= cutOffChunkId && !c.isProcessed)
            .map((c) => c.chunkIndex)
            .toList()
          ..sort();
    _log(
      '⏰ WAIT TIMEOUT: Chunks $stillPending still processing after ${timeoutTime}ms',
    );
  }

  // Legacy method - kept for compatibility but use waitForChunksUpToCutoff for Get Help
  Future<void> waitForChunksUpToCurrentRecording({int maxWaitMs = 5000}) async {
    final startTime = DateTime.now();
    final cutOffChunkId =
        _chunkCounter; // Current chunk being recorded (or last queued)

    _log(
      '⏳ WAIT START: Waiting for chunks up to $cutOffChunkId (max ${maxWaitMs}ms)',
    );

    while (DateTime.now().difference(startTime).inMilliseconds < maxWaitMs) {
      // Check if all relevant chunks are processed
      final relevantChunks = _chunkQueue.where(
        (c) => c.chunkIndex <= cutOffChunkId,
      );
      final unprocessedRelevant = relevantChunks.where((c) => !c.isProcessed);

      if (unprocessedRelevant.isEmpty) {
        final waitTime = DateTime.now().difference(startTime).inMilliseconds;
        _log('✅ WAIT COMPLETE: All relevant chunks processed (${waitTime}ms)');
        return;
      }

      // Wait a bit before checking again
      await Future.delayed(Duration(milliseconds: 100));
    }

    // Timeout reached
    final timeoutTime = DateTime.now().difference(startTime).inMilliseconds;
    _log('⏰ WAIT TIMEOUT: Some chunks still processing after ${timeoutTime}ms');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _chunkRotationTimer?.cancel();
    _recorder.stop();
    _recorder.dispose();
    _cleanupOldAudioFiles();
    super.dispose();
  }
}
