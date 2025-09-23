class InterviewSummaryModel {
  final String sessionId;
  final String sessionType;
  final DateTime date;
  final Duration duration;
  final List<String> keyTopics;
  final List<String> strengths;
  final List<String> areasForImprovement;
  final List<String> actionItems;
  final List<String> decisionsMade; // For meetings
  final String rawSummary;

  InterviewSummaryModel({
    required this.sessionId,
    required this.sessionType,
    required this.date,
    required this.duration,
    required this.keyTopics,
    required this.strengths,
    required this.areasForImprovement,
    required this.actionItems,
    this.decisionsMade = const [],
    required this.rawSummary,
  });

  factory InterviewSummaryModel.fromApiResponse({
    required String sessionId,
    required String sessionType,
    required DateTime startTime,
    required Duration duration,
    required String summary,
  }) {
    final keyTopics = <String>[];
    final strengths = <String>[];
    final areasForImprovement = <String>[];
    final actionItems = <String>[];
    final decisionsMade = <String>[];

    final lines = summary.split('\n');
    String currentSection = '';

    // Check if it's a meeting format (simplified format without markdown)
    final isMeetingFormat =
        summary.contains('Key Discussion Points:') ||
        summary.contains('Decisions Made:');

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Handle meeting format
      if (isMeetingFormat) {
        if (trimmedLine.startsWith('Key Discussion Points:') ||
            trimmedLine.startsWith('Key Topics:')) {
          currentSection = 'topics';
        } else if (trimmedLine.startsWith('Decisions Made:')) {
          currentSection = 'decisions';
        } else if (trimmedLine.startsWith('Action Items:')) {
          currentSection = 'actions';
        } else if (trimmedLine.startsWith('Areas for Improvement:')) {
          currentSection = 'areas';
        } else if (trimmedLine.startsWith('- ')) {
          final item = trimmedLine.substring(2).trim();
          if (item.isNotEmpty &&
              item != 'Not discussed.' &&
              item != 'None discussed.') {
            switch (currentSection) {
              case 'topics':
                keyTopics.add(item);
                break;
              case 'decisions':
                decisionsMade.add(item);
                break;
              case 'actions':
                actionItems.add(item);
                break;
              case 'areas':
                areasForImprovement.add(item);
                break;
            }
          }
        }
      } else {
        // Handle interview format (with markdown)
        if (trimmedLine.startsWith('**Key Topics Discussed:**')) {
          currentSection = 'topics';
        } else if (trimmedLine.startsWith('**Strengths Highlighted:**')) {
          currentSection = 'strengths';
        } else if (trimmedLine.startsWith('**Areas for Improvement:**')) {
          currentSection = 'areas';
        } else if (trimmedLine.startsWith('**Action Items:**')) {
          currentSection = 'actions';
        } else if (trimmedLine.startsWith('- ')) {
          final item = trimmedLine.substring(2).trim();
          switch (currentSection) {
            case 'topics':
              keyTopics.add(item);
              break;
            case 'strengths':
              strengths.add(item);
              break;
            case 'areas':
              areasForImprovement.add(item);
              break;
            case 'actions':
              actionItems.add(item);
              break;
          }
        }
      }
    }

    return InterviewSummaryModel(
      sessionId: sessionId,
      sessionType: sessionType,
      date: startTime,
      duration: duration,
      keyTopics: keyTopics,
      strengths: strengths,
      areasForImprovement: areasForImprovement,
      actionItems: actionItems,
      decisionsMade: decisionsMade,
      rawSummary: summary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'sessionType': sessionType,
      'date': date.toIso8601String(),
      'durationInSeconds': duration.inSeconds,
      'keyTopics': keyTopics,
      'strengths': strengths,
      'areasForImprovement': areasForImprovement,
      'actionItems': actionItems,
      'decisionsMade': decisionsMade,
      'rawSummary': rawSummary,
    };
  }
}
