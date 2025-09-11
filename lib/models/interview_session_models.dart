import 'dart:convert';

class SessionStartRequest {
  final String? sessionId;
  final String sessionType;
  final String role;
  final String companyName;
  final String jobDescription;
  final String language;
  final String? resumeText;

  SessionStartRequest({
    this.sessionId,
    required this.sessionType,
    required this.role,
    required this.companyName,
    required this.jobDescription,
    this.language = "en",
    this.resumeText,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'session_type': sessionType,
      'role': role,
      'company_name': companyName,
      'job_description': jobDescription,
      'language': language,
    };

    // Only include optional fields if they have values
    if (sessionId != null) {
      data['session_id'] = sessionId;
    }
    if (resumeText != null && resumeText!.isNotEmpty) {
      data['resume_text'] = resumeText;
    }

    return data;
  }
}

class SessionStartResponse {
  final bool success;
  final String? status;
  final String sessionId;
  final String? message;
  final String? error;

  SessionStartResponse({
    required this.success,
    this.status,
    required this.sessionId,
    this.message,
    this.error,
  });

  factory SessionStartResponse.fromJson(Map<String, dynamic> json) {
    return SessionStartResponse(
      success: json['status'] == 'success' || json['success'] == true,
      status: json['status']?.toString(),
      sessionId: json['session_id']?.toString() ?? '',
      message: json['message']?.toString(),
      error: json['error']?.toString(),
    );
  }

  factory SessionStartResponse.failure(String errorMessage) {
    return SessionStartResponse(
      success: false,
      status: 'error',
      sessionId: '',
      error: errorMessage,
    );
  }
}

class SessionHelpRequest {
  final String sessionId;
  final String transcript;

  SessionHelpRequest({required this.sessionId, required this.transcript});

  Map<String, dynamic> toFormData() {
    return {'session_id': sessionId, 'transcript': transcript};
  }
}

class SessionHelpResponse {
  final bool success;
  final String type;
  final String message;
  final String? error;

  SessionHelpResponse({
    required this.success,
    required this.type,
    required this.message,
    this.error,
  });

  factory SessionHelpResponse.fromJson(Map<String, dynamic> json) {
    String rawMessage = json['message']?.toString() ?? '';
    print('[HELP-RESPONSE] Raw message: $rawMessage');

    // Parse nested JSON if the message contains a JSON code block
    String actualMessage = rawMessage;
    try {
      // Check if message contains JSON code block
      if (rawMessage.contains('```json') && rawMessage.contains('```')) {
        print('[HELP-RESPONSE] Found JSON code block, extracting...');
        // Extract JSON from code block
        final startIndex = rawMessage.indexOf('```json') + 7;
        final endIndex = rawMessage.indexOf('```', startIndex);
        if (startIndex < endIndex) {
          final jsonString = rawMessage.substring(startIndex, endIndex).trim();
          print('[HELP-RESPONSE] Extracted JSON: $jsonString');
          final parsedJson = Map<String, dynamic>.from(
            // Using a simple JSON parser approach
            _parseSimpleJson(jsonString),
          );
          actualMessage = parsedJson['message']?.toString() ?? rawMessage;
          print('[HELP-RESPONSE] Parsed message: $actualMessage');
        }
      } else {
        print('[HELP-RESPONSE] No JSON code block found, using raw message');
      }
    } catch (e) {
      print('[HELP-RESPONSE] Parsing error: $e');
      // If parsing fails, use the original message
      actualMessage = rawMessage;
    }

    return SessionHelpResponse(
      success: true,
      type: json['type']?.toString() ?? 'answer',
      message: actualMessage,
    );
  }

  // Simple JSON parser for extracting nested message
  static Map<String, dynamic> _parseSimpleJson(String jsonString) {
    try {
      // Use dart:convert for proper JSON parsing
      return Map<String, dynamic>.from(
        (const JsonDecoder()).convert(jsonString),
      );
    } catch (e) {
      return {};
    }
  }

  factory SessionHelpResponse.failure(String errorMessage) {
    return SessionHelpResponse(
      success: false,
      type: 'error',
      message: '',
      error: errorMessage,
    );
  }
}

// Follow-up Questions Request Model
class SessionFollowUpRequest {
  final String sessionId;
  final String transcript;

  SessionFollowUpRequest({required this.sessionId, required this.transcript});

  // Convert to form data (application/x-www-form-urlencoded)
  Map<String, String> toFormData() {
    return {'session_id': sessionId, 'transcript': transcript};
  }

  @override
  String toString() {
    return 'SessionFollowUpRequest(sessionId: $sessionId, transcript: ${transcript.length} chars)';
  }
}

// Follow-up Questions Response Model
class SessionFollowUpResponse {
  final bool success;
  final String type;
  final String message;
  final String? error;

  SessionFollowUpResponse({
    required this.success,
    required this.type,
    required this.message,
    this.error,
  });

  factory SessionFollowUpResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested JSON structure like: {"message": {"message": "actual content"}}
    dynamic messageData = json['message'];
    String actualMessage = '';

    if (messageData is Map<String, dynamic>) {
      // Extract nested message
      actualMessage = messageData['message']?.toString() ?? '';

      // If still empty, try other possible keys
      if (actualMessage.isEmpty) {
        actualMessage =
            messageData['content']?.toString() ??
            messageData['text']?.toString() ??
            messageData['response']?.toString() ??
            messageData.toString();
      }
    } else if (messageData is String) {
      // Direct string message
      actualMessage = messageData;
    } else if (messageData != null) {
      // Fallback: convert to string
      actualMessage = messageData.toString();
    }

    return SessionFollowUpResponse(
      success: json['success'] == true || json['success'] == 'true',
      type: json['type']?.toString() ?? 'follow_up',
      message: actualMessage,
      error: json['error']?.toString(),
    );
  }

  factory SessionFollowUpResponse.failure(String errorMessage) {
    return SessionFollowUpResponse(
      success: false,
      type: 'error',
      message: '',
      error: errorMessage,
    );
  }
}
