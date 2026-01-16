# Speaker Diarization Implementation

## Overview

Speaker diarization is the process of identifying "who spoke when" in an audio recording. This feature enables the app to distinguish between different speakers during interview/meeting sessions and display transcripts as a dialog view showing which speaker said what.

## How It Works

### Deepgram Integration

The app uses Deepgram's real-time transcription API with built-in speaker diarization. When enabled, Deepgram returns a `speaker` ID (0, 1, 2, etc.) with each transcribed word.

**Configuration** (`lib/services/transcription/transcription_config.dart`):
```dart
'diarize': true,  // Enable speaker diarization
```

### Data Flow

```
Audio Input
    ↓
Deepgram WebSocket (with diarize=true)
    ↓
Word-by-word results with speaker IDs
    ↓
DeepgramAudioTranscriber (groups words into segments)
    ↓
ContinuousTranscriptionProvider (syncs to state)
    ↓
UI (displays dialog view in bottom sheet)
```

## Key Components

### 1. SpeakerSegment Model

**File**: `lib/models/conversation_models.dart`

```dart
class SpeakerSegment {
  final int speakerId;      // Numeric ID from Deepgram (0, 1, 2, ...)
  final String text;        // The spoken text
  final double? startTime;  // When this segment started (seconds)
  final double? endTime;    // When this segment ended (seconds)

  /// Returns display label based on speaker count
  /// - 2 speakers: "Interviewer" (ID 0) / "You" (ID 1)
  /// - 3+ speakers: "Speaker 1", "Speaker 2", etc.
  String getDisplayLabel(int totalSpeakers) {
    if (totalSpeakers == 2) {
      return speakerId == 0 ? 'Interviewer' : 'You';
    }
    return 'Speaker ${speakerId + 1}';
  }
}
```

### 2. TranscriptAnswerPair Updates

**File**: `lib/models/conversation_models.dart`

The `TranscriptAnswerPair` class was updated to support speaker segments:

```dart
class TranscriptAnswerPair {
  final String transcript;              // Plain text fallback
  final List<SpeakerSegment>? segments; // Speaker-segmented transcript
  final String answer;                  // Scout's response

  /// Check if this pair has speaker segments
  bool get hasSegments => segments != null && segments!.isNotEmpty;

  /// Get unique speaker count from segments (computed getter)
  int get speakerCount {
    if (!hasSegments) return 0;
    return segments!.map((s) => s.speakerId).toSet().length;
  }
}
```

### 3. DeepgramAudioTranscriber

**File**: `lib/services/transcription/deepgram_audio_transcriber.dart`

Handles parsing speaker IDs from Deepgram's response and grouping consecutive words by speaker:

```dart
// State variables
final List<SpeakerSegment> _speakerSegments = [];
final Set<int> _uniqueSpeakers = {};
int? _currentSpeakerId;
String _currentSpeakerText = '';
double? _currentSegmentStartTime;

// Getters exposed via AudioTranscriber interface
List<SpeakerSegment> get speakerSegments;
int get speakerCount;
```

**Word Processing Logic**:
- Each word from Deepgram includes a `speaker` field
- Words are grouped into segments by consecutive speaker ID
- When speaker changes, the current segment is finalized and a new one begins

### 4. Provider State

**File**: `lib/providers/continuous_transcription_provider.dart`

`InterviewSessionData` includes:
```dart
final List<SpeakerSegment> speakerSegments;
final int speakerCount;
```

These are synced from the transcriber in `_onTranscriberUpdate()` and preserved in `stopSession()`.

## UI Components

### Bottom Sheet Dialog View

**Files**:
- `lib/screens/candidate/interview/meeting_detail_screen.dart`
- `lib/screens/candidate/interview/meeting_summary_screen.dart`

When displaying transcripts with speaker segments:

1. **Header** shows "Conversation" instead of "Transcript/Question"
2. **Speaker count badge** displays number of detected speakers
3. **Dialog view** shows each segment with:
   - Circular avatar with speaker initial
   - Speaker label (color-coded)
   - Spoken text

**Visual Design**:
- Interviewer/Speaker 0: Blue color scheme
- You/Other speakers: Green color scheme
- Each segment displays as a chat-like message

## JSON Serialization

Speaker segments are serialized for persistence:

```json
{
  "id": "msg_123",
  "t": "plain text transcript",
  "seg": [
    {
      "sid": 0,
      "txt": "Hello, tell me about yourself",
      "st": 0.5,
      "et": 3.2
    },
    {
      "sid": 1,
      "txt": "Sure, I have 5 years of experience...",
      "st": 3.5,
      "et": 8.1
    }
  ],
  "a": "Scout's response here",
  "ts": "2024-01-15T10:30:00Z",
  "type": "help"
}
```

## Limitations & Notes

1. **Speaker ID Assignment**: Deepgram assigns arbitrary IDs (0, 1, 2...) - there's no way to know which ID corresponds to the interviewer vs the user without manual labeling.

2. **Two-Speaker Assumption**: For interviews, we assume:
   - Speaker 0 = Interviewer (speaks first)
   - Speaker 1 = You (the user)

3. **Multiple Speakers**: For meetings with 3+ speakers, generic labels are used ("Speaker 1", "Speaker 2", etc.)

4. **Accuracy**: Diarization accuracy depends on:
   - Audio quality
   - Speaker overlap (simultaneous speech)
   - Similar voice characteristics

5. **Backward Compatibility**: The `transcript` field is always populated for systems that don't support segments.

## Testing

To test speaker diarization:

1. Start an interview/meeting session
2. Have multiple people speak (or simulate with different voice recordings)
3. Tap "Get Help" to generate a transcript-answer pair
4. End the session
5. View the transcript in the summary screen bottom sheet
6. Verify speaker segments are displayed as a dialog

## Future Enhancements

- [ ] Allow users to manually label speakers
- [ ] Auto-detect "Me" based on device microphone proximity
- [ ] Speaker confidence scores
- [ ] Timestamp display for each segment
- [ ] Export transcript as formatted dialog